package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.entity.GameEntity
import com.jackabee.cribbageclubserver.model.ai.AIPlayer
import com.jackabee.cribbageclubserver.model.ai.BasicAIPlayer
import com.jackabee.cribbageclubserver.model.ai.HardAIPlayer
import com.jackabee.cribbageclubserver.model.ai.MediumAIPlayer
import com.jackabee.cribbageclubserver.model.game.Game
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.model.player.Player
import com.jackabee.cribbageclubserver.repository.GameRepository
import com.jackabee.cribbageclubserver.websocket.GameWebSocketService
import com.fasterxml.jackson.databind.ObjectMapper
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Autowired
import java.time.Instant
import java.util.concurrent.ConcurrentHashMap
import kotlin.random.Random

/**
 * Service for managing cribbage games with AI players and human players.
 * The database is the source of truth; in-memory Game objects serve as a cache
 * for active play. On cache miss (e.g., after server restart), games are
 * reconstructed from the persisted GameState.
 */
@org.springframework.stereotype.Service
class GameService(
    @Autowired(required = false) private val webSocketService: GameWebSocketService? = null,
    @Autowired(required = false) private val gameRepository: GameRepository? = null,
    @Autowired(required = false) private val objectMapper: ObjectMapper? = null,
    @Autowired(required = false) private val playerStatsService: PlayerStatsService? = null
) {
    private val logger = LoggerFactory.getLogger(GameService::class.java)

    // In-memory cache of active Game objects (rebuilt from DB on cache miss)
    private val games = ConcurrentHashMap<String, Game>()
    private val aiPlayers = ConcurrentHashMap<String, AIPlayer>()

    /**
     * Creates a new game with the provided players.
     * Broadcasts the initial game state via WebSocket.
     *
     * @param players The list of players for the game
     * @return The initial game state
     */
    fun createGame(players: List<Player>): GameState {
        require(players.size == 2) { "Game must have exactly 2 players" }

        val gameId = generateGameId()
        val game = Game(gameId, players)
        games[gameId] = game

        // Process any immediate AI actions if any players are AI
        val initialState = processAIActions(game)

        // Persist to database
        saveGameEntity(gameId, players[0], players[1], initialState, isAIGame = false)

        // Broadcast the initial game state via WebSocket if available
        webSocketService?.broadcastGameStateUpdate(gameId, initialState)
        logger.info("Created game {} between {} and {}", gameId, players[0].name, players[1].name)

        return initialState
    }

    /**
     * Creates a new game with a human player and an AI opponent.
     * Broadcasts the initial game state via WebSocket.
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

        // Create AI player based on difficulty
        val aiPlayer = when (aiDifficulty.lowercase()) {
            "basic" -> BasicAIPlayer(aiPlayerId, aiPlayerName)
            "medium" -> MediumAIPlayer(aiPlayerId, "$aiPlayerName (Medium)")
            "hard" -> HardAIPlayer(aiPlayerId, "$aiPlayerName (Hard)")
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
        val initialState = processAIActions(game)

        // Persist to database
        saveGameEntity(
            gameId, players[0], players[1], initialState,
            isAIGame = true, aiPlayerId = aiPlayerId, aiDifficulty = aiDifficulty
        )

        // Broadcast the initial game state via WebSocket if available
        webSocketService?.broadcastGameStateUpdate(gameId, initialState)
        logger.info("Created AI game {} for player {}", gameId, humanPlayerName)

        return initialState
    }

    /**
     * Applies a human player's action to the game and processes any subsequent AI actions.
     * Broadcasts the updated game state via WebSocket.
     *
     * @param gameId The ID of the game
     * @param action The action to apply
     * @return The updated game state after all actions are processed
     */
    fun applyHumanAction(gameId: String, action: com.jackabee.cribbageclubserver.model.action.GameAction): GameState {
        val game = games[gameId] ?: loadGame(gameId)
            ?: throw IllegalArgumentException("Game not found: $gameId")

        // Apply human action
        game.applyAction(action)

        // Process any AI actions that should follow
        val finalState = processAIActions(game)

        // Update database snapshot
        updateGameEntity(gameId, finalState)

        // Broadcast the updated game state via WebSocket if available
        webSocketService?.broadcastGameStateUpdate(gameId, finalState)

        return finalState
    }

    /**
     * Gets the current state of a game.
     *
     * @param gameId The ID of the game
     * @return The current game state
     */
    fun getGameState(gameId: String): GameState {
        // Try in-memory cache first
        val cachedGame = games[gameId]
        if (cachedGame != null) {
            return cachedGame.getCurrentState()
        }

        // Try to restore active game from database
        val restoredGame = loadGame(gameId)
        if (restoredGame != null) {
            return restoredGame.getCurrentState()
        }

        // Fall back to raw DB state (for finished games)
        val entity = gameRepository?.findById(gameId)?.orElse(null)
        if (entity != null) {
            return deserializeGameState(entity)
        }

        throw IllegalArgumentException("Game not found: $gameId")
    }

    /**
     * Removes a game from the service and database.
     *
     * @param gameId The ID of the game to remove
     */
    fun removeGame(gameId: String) {
        // Clean up AI players associated with this game before removing it
        val game = games[gameId]
        game?.getCurrentState()?.players?.forEach { player ->
            aiPlayers.remove(player.id)
        }
        games.remove(gameId)

        // Remove from database
        gameRepository?.deleteById(gameId)
        logger.info("Removed game {}", gameId)
    }

    /**
     * Lists all active (non-finished) games.
     *
     * @return Map of game IDs to their current states
     */
    fun listGames(): Map<String, GameState> {
        val repo = gameRepository
        val mapper = objectMapper
        if (repo != null && mapper != null) {
            return repo.findByWinnerIdIsNull().associate { entity ->
                entity.id to deserializeGameState(entity)
            }
        }
        // Fallback to in-memory cache when no DB is available
        return games.mapValues { it.value.getCurrentState() }
    }

    /**
     * Lists all game records from the database.
     */
    fun listAllGameRecords(): List<GameEntity> {
        return gameRepository?.findAll() ?: emptyList()
    }

    /**
     * Finds games by player ID.
     */
    fun findGamesByPlayer(playerId: String): List<GameEntity> {
        return gameRepository?.findByPlayer1IdOrPlayer2Id(playerId, playerId) ?: emptyList()
    }

    /**
     * Removes games that have been inactive for longer than the given duration.
     * Finished games (GAME_OVER) are always eligible for removal.
     *
     * @return The list of removed game IDs
     */
    fun removeInactiveGames(inactiveThreshold: Instant): List<String> {
        val removed = mutableListOf<String>()
        val repo = gameRepository
        if (repo != null) {
            val allGames = repo.findAll()
            for (entity in allGames) {
                if (entity.updatedAt.isBefore(inactiveThreshold) || entity.stage == GameStage.GAME_OVER.name) {
                    removeGame(entity.id)
                    removed.add(entity.id)
                }
            }
        } else {
            // Fallback: clean up only cached games (no activity tracking without DB)
            for ((gameId, game) in games) {
                val state = game.getCurrentState()
                if (state.stage == GameStage.GAME_OVER) {
                    removeGame(gameId)
                    removed.add(gameId)
                }
            }
        }
        return removed
    }

    /**
     * Loads a game from the database, restores the Game object, and caches it.
     * For AI games, also recreates the AIPlayer instance.
     *
     * @return The restored Game, or null if not found in DB
     */
    private fun loadGame(gameId: String): Game? {
        val repo = gameRepository ?: return null
        objectMapper ?: return null

        val entity = repo.findById(gameId).orElse(null) ?: return null
        val state = deserializeGameState(entity)

        // Don't restore finished games as playable Game objects
        if (state.stage == GameStage.GAME_OVER) return null

        val game = Game.restore(state)
        games[gameId] = game

        // Recreate AI player if this is an AI game
        if (entity.isAIGame && entity.aiPlayerId != null) {
            val aiPlayerId = entity.aiPlayerId!!
            val difficulty = entity.aiDifficulty ?: "basic"
            val aiPlayerName = state.players.find { it.id == aiPlayerId }?.name ?: "AI Opponent"
            val aiPlayer = when (difficulty.lowercase()) {
                "basic" -> BasicAIPlayer(aiPlayerId, aiPlayerName)
                "medium" -> MediumAIPlayer(aiPlayerId, aiPlayerName)
                "hard" -> HardAIPlayer(aiPlayerId, aiPlayerName)
                else -> BasicAIPlayer(aiPlayerId, aiPlayerName)
            }
            aiPlayers[aiPlayerId] = aiPlayer
        }

        logger.info("Restored game {} from database", gameId)
        return game
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

    private fun saveGameEntity(
        gameId: String,
        player1: Player,
        player2: Player,
        state: GameState,
        isAIGame: Boolean,
        aiPlayerId: String? = null,
        aiDifficulty: String? = null
    ) {
        val mapper = objectMapper ?: return
        val repo = gameRepository ?: return

        val entity = GameEntity(
            id = gameId,
            player1Id = player1.id,
            player1Name = player1.name,
            player2Id = player2.id,
            player2Name = player2.name,
            player1Score = state.players[0].score,
            player2Score = state.players[1].score,
            stage = state.stage.name,
            currentPlayerId = state.currentPlayerId,
            isAIGame = isAIGame,
            aiPlayerId = aiPlayerId,
            aiDifficulty = aiDifficulty,
            stateJson = mapper.writeValueAsString(state)
        )
        repo.save(entity)
    }

    private fun updateGameEntity(gameId: String, state: GameState) {
        val mapper = objectMapper ?: return
        val repo = gameRepository ?: return

        val entity = repo.findById(gameId).orElse(null) ?: return
        entity.player1Score = state.players[0].score
        entity.player2Score = state.players[1].score
        entity.stage = state.stage.name
        entity.currentPlayerId = state.currentPlayerId
        entity.updatedAt = Instant.now()
        entity.stateJson = mapper.writeValueAsString(state)

        if (state.stage == GameStage.GAME_OVER) {
            val winner = state.players.maxByOrNull { it.score }
            entity.winnerId = winner?.id

            // Record stats for both players
            if (winner != null && state.players.size == 2) {
                val loser = state.players.first { it.id != winner.id }
                playerStatsService?.recordGameResult(
                    winnerId = winner.id,
                    loserId = loser.id,
                    winnerScore = winner.score,
                    loserScore = loser.score
                )
            }
        }

        repo.save(entity)
    }

    private fun deserializeGameState(entity: GameEntity): GameState {
        val mapper = objectMapper
        if (mapper != null && entity.stateJson != null) {
            return mapper.readValue(entity.stateJson, GameState::class.java)
        }
        // Minimal fallback if no JSON stored or no ObjectMapper
        return GameState(
            gameId = entity.id,
            players = listOf(
                Player(entity.player1Id, entity.player1Name, score = entity.player1Score),
                Player(entity.player2Id, entity.player2Name, score = entity.player2Score)
            ),
            stage = GameStage.valueOf(entity.stage)
        )
    }

    private fun generateGameId(): String {
        return "game_${System.currentTimeMillis()}_${Random.nextInt(1000, 9999)}"
    }
}
