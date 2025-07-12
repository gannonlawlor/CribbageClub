package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.model.ai.AIPlayer
import com.jackabee.cribbageclubserver.model.ai.BasicAIPlayer
import com.jackabee.cribbageclubserver.model.game.Game
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.player.Player
import java.util.concurrent.ConcurrentHashMap
import kotlin.random.Random

/**
 * Service for managing cribbage games with AI players.
 */
class GameService {
    
    private val games = ConcurrentHashMap<String, Game>()
    private val aiPlayers = ConcurrentHashMap<String, AIPlayer>()
    
    /**
     * Creates a new game with a human player and an AI opponent.
     * 
     * @param humanPlayerId The ID of the human player
     * @param humanPlayerName The name of the human player
     * @param aiDifficulty The difficulty level of the AI (currently only "basic" is supported)
     * @return The initial game state
     */
    fun createGameWithAI(
        humanPlayerId: String,
        humanPlayerName: String,
        aiDifficulty: String = "basic"
    ): GameState {
        val gameId = generateGameId()
        val aiPlayerId = "ai_${Random.nextInt(1000, 9999)}"
        val aiPlayerName = "AI Opponent"
        
        // Create AI player
        val aiPlayer = when (aiDifficulty.lowercase()) {
            "basic" -> BasicAIPlayer(aiPlayerId, aiPlayerName)
            else -> BasicAIPlayer(aiPlayerId, aiPlayerName)
        }
        
        // Store AI player for later use
        aiPlayers[aiPlayerId] = aiPlayer
        
        // Create game with human and AI players
        val players = listOf(
            Player(humanPlayerId, humanPlayerName),
            Player(aiPlayerId, aiPlayerName)
        )
        
        val game = Game(gameId, players)
        games[gameId] = game
        
        // Process any immediate AI actions
        return processAIActions(game)
    }
    
    /**
     * Applies a human player's action to the game and processes any subsequent AI actions.
     * 
     * @param gameId The ID of the game
     * @param action The action to apply
     * @return The updated game state after all actions are processed
     */
    fun applyHumanAction(gameId: String, action: com.jackabee.cribbageclubserver.model.action.GameAction): GameState {
        val game = games[gameId] ?: throw IllegalArgumentException("Game not found: $gameId")
        
        // Apply human action
        game.applyAction(action)
        
        // Process any AI actions that should follow
        return processAIActions(game)
    }
    
    /**
     * Gets the current state of a game.
     * 
     * @param gameId The ID of the game
     * @return The current game state
     */
    fun getGameState(gameId: String): GameState {
        val game = games[gameId] ?: throw IllegalArgumentException("Game not found: $gameId")
        return game.getCurrentState()
    }
    
    /**
     * Removes a game from the service.
     * 
     * @param gameId The ID of the game to remove
     */
    fun removeGame(gameId: String) {
        games.remove(gameId)
        // Clean up AI players associated with this game
        val gameState = games[gameId]?.getCurrentState()
        gameState?.players?.forEach { player ->
            if (aiPlayers.containsKey(player.id)) {
                aiPlayers.remove(player.id)
            }
        }
    }
    
    /**
     * Lists all active games.
     * 
     * @return Map of game IDs to their current states
     */
    fun listGames(): Map<String, GameState> {
        return games.mapValues { it.value.getCurrentState() }
    }
    
    /**
     * Processes AI actions for the current game state.
     * Continues processing until it's a human player's turn or the game is over.
     * 
     * @param game The game to process
     * @return The final game state after all AI actions
     */
    private fun processAIActions(game: Game): GameState {
        var currentState = game.getCurrentState()
        var iterationCount = 0
        val maxIterations = 10 // Prevent infinite loops
        
        while (iterationCount < maxIterations) {
            val currentPlayerId = currentState.currentPlayerId
            
            // Check if current player is AI
            val aiPlayer = currentPlayerId?.let { aiPlayers[it] }
            if (aiPlayer == null) {
                // Human player's turn or no current player
                break
            }
            
            // Get AI action
            val aiAction = aiPlayer.getNextAction(currentState)
            if (aiAction == null) {
                // AI has no action to take
                break
            }
            
            // Apply AI action
            currentState = game.applyAction(aiAction)
            iterationCount++
        }
        
        return currentState
    }
    
    private fun generateGameId(): String {
        return "game_${System.currentTimeMillis()}_${Random.nextInt(1000, 9999)}"
    }
}