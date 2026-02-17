package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.entity.GameEntity
import com.jackabee.cribbageclubserver.model.ai.AIPlayer
import com.jackabee.cribbageclubserver.model.ai.BasicAIPlayer
import com.jackabee.cribbageclubserver.model.game.Game
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.model.player.Player
import com.jackabee.cribbageclubserver.repository.GameRepository
import com.jackabee.cribbageclubserver.websocket.GameWebSocketService
import com.fasterxml.jackson.databind.ObjectMapper
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Service
import java.time.Instant
import java.util.concurrent.ConcurrentHashMap
import kotlin.random.Random

/**
 * Service for managing cribbage games with AI players and human players.
 * Active games live in memory (Game objects hold mutable deck state).
 * Game snapshots are persisted to the database after each action.
 */
@Service
class GameService(
    private val gameRepository: GameRepository,
    private val objectMapper: ObjectMapper,
    @Autowired(required = false) private val webSocketService: GameWebSocketService? = null
) {
    private val logger = LoggerFactory.getLogger(GameService::class.java)

    // Active games in memory (Game objects hold mutable deck/round state)
    private val games = ConcurrentHashMap<String, Game>()
    private val aiPlayers = ConcurrentHashMap<String, AIPlayer>()

    /**
     * Creates a new game with the provided players.
     */
    fun createGame(players: List<Player>): GameState {
        require(players.size == 2) { "Game must have exactly 2 players" }

        val gameId = generateGameId()
        val game = Game(gameId, players)
        games[gameId] = game

        val initialState = processAIActions(game)

        // Persist to database
        saveGameEntity(gameId, players[0], players[1], initialState, isAIGame = false)

        webSocketService?.broadcastGameStateUpdate(gameId, initialState)
        logger.info("Created game {} between {} and {}", gameId, players[0].name, players[1].name)

        return initialState
    }

    /**
     * Creates a new game with a human player and an AI opponent.
     */
    fun createGameWithAI(
        humanPlayerId: String,
        humanPlayerName: String,
        aiDifficulty: String = "basic"
    ): GameState {
        val gameId = generateGameId()
        val aiPlayerId = "ai_${Random.nextInt(1000, 9999)}"
        val aiPlayerName = "AI Opponent"

        val aiPlayer = when (aiDifficulty.lowercase()) {
            "basic" -> BasicAIPlayer(aiPlayerId, aiPlayerName)
            else -> BasicAIPlayer(aiPlayerId, aiPlayerName)
        }

        aiPlayers[aiPlayerId] = aiPlayer

        val players = listOf(
            Player(humanPlayerId, humanPlayerName),
            Player(aiPlayerId, aiPlayerName)
        )

        val game = Game(gameId, players)
        games[gameId] = game

        val initialState = processAIActions(game)

        // Persist to database
        saveGameEntity(
            gameId, players[0], players[1], initialState,
            isAIGame = true, aiPlayerId = aiPlayerId, aiDifficulty = aiDifficulty
        )

        webSocketService?.broadcastGameStateUpdate(gameId, initialState)
        logger.info("Created AI game {} for player {}", gameId, humanPlayerName)

        return initialState
    }

    /**
     * Applies a human player's action to the game and processes any subsequent AI actions.
     */
    fun applyHumanAction(gameId: String, action: com.jackabee.cribbageclubserver.model.action.GameAction): GameState {
        val game = games[gameId] ?: throw IllegalArgumentException("Game not found: $gameId")

        game.applyAction(action)

        val finalState = processAIActions(game)

        // Update database snapshot
        updateGameEntity(gameId, finalState)

        webSocketService?.broadcastGameStateUpdate(gameId, finalState)

        return finalState
    }

    /**
     * Gets the current state of a game.
     */
    fun getGameState(gameId: String): GameState {
        // Try in-memory first (active games)
        val game = games[gameId]
        if (game != null) {
            return game.getCurrentState()
        }

        // Fall back to database for completed/inactive games
        val entity = gameRepository.findById(gameId).orElse(null)
            ?: throw IllegalArgumentException("Game not found: $gameId")

        return deserializeGameState(entity)
    }

    /**
     * Removes a game from the service and marks it in the database.
     */
    fun removeGame(gameId: String) {
        // Clean up AI players before removing
        val game = games[gameId]
        game?.getCurrentState()?.players?.forEach { player ->
            aiPlayers.remove(player.id)
        }
        games.remove(gameId)

        // Remove from database
        gameRepository.deleteById(gameId)
        logger.info("Removed game {}", gameId)
    }

    /**
     * Lists all active games (in-memory).
     */
    fun listGames(): Map<String, GameState> {
        return games.mapValues { it.value.getCurrentState() }
    }

    /**
     * Lists all game records from the database.
     */
    fun listAllGameRecords(): List<GameEntity> {
        return gameRepository.findAll()
    }

    /**
     * Finds games by player ID.
     */
    fun findGamesByPlayer(playerId: String): List<GameEntity> {
        return gameRepository.findByPlayer1IdOrPlayer2Id(playerId, playerId)
    }

    private fun processAIActions(game: Game): GameState {
        var currentState = game.getCurrentState()
        var iterationCount = 0
        val maxIterations = 10

        while (iterationCount < maxIterations) {
            val currentPlayerId = currentState.currentPlayerId

            val aiPlayer = currentPlayerId?.let { aiPlayers[it] }
            if (aiPlayer == null) break

            val aiAction = aiPlayer.getNextAction(currentState)
            if (aiAction == null) break

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
            stateJson = objectMapper.writeValueAsString(state)
        )
        gameRepository.save(entity)
    }

    private fun updateGameEntity(gameId: String, state: GameState) {
        val entity = gameRepository.findById(gameId).orElse(null) ?: return
        entity.player1Score = state.players[0].score
        entity.player2Score = state.players[1].score
        entity.stage = state.stage.name
        entity.currentPlayerId = state.currentPlayerId
        entity.updatedAt = Instant.now()
        entity.stateJson = objectMapper.writeValueAsString(state)

        if (state.stage == GameStage.GAME_OVER) {
            val winner = state.players.maxByOrNull { it.score }
            entity.winnerId = winner?.id
        }

        gameRepository.save(entity)
    }

    private fun deserializeGameState(entity: GameEntity): GameState {
        if (entity.stateJson != null) {
            return objectMapper.readValue(entity.stateJson, GameState::class.java)
        }
        // Minimal fallback if no JSON stored
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
