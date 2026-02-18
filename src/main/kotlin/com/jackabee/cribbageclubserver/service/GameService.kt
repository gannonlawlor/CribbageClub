package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.bridge.RustEngine
import com.jackabee.cribbageclubserver.bridge.RustEngineAdapter
import com.jackabee.cribbageclubserver.controller.ImportGameRequest
import com.jackabee.cribbageclubserver.controller.ImportGamesResponse
import com.jackabee.cribbageclubserver.controller.ImportedGameMapping
import com.jackabee.cribbageclubserver.entity.GameEntity
import com.jackabee.cribbageclubserver.model.game.GameHistoryEvent
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

/** Tracks a cached Rust engine handle together with AI metadata. */
private data class CachedGame(
    val engine: RustEngine,
    val aiPlayerId: String? = null,
    val aiDifficulty: String? = null,
)

/**
 * Service for managing cribbage games with AI players and human players.
 * Game logic is delegated to the Rust cribbage-engine via JNA.
 * The database is the source of truth; in-memory engine handles serve as a
 * cache for active play. On cache miss (e.g., after server restart), engines
 * are reconstructed from the persisted GameState.
 */
@org.springframework.stereotype.Service
class GameService(
    @Autowired(required = false) private val webSocketService: GameWebSocketService? = null,
    @Autowired(required = false) private val gameRepository: GameRepository? = null,
    @Autowired(required = false) private val objectMapper: ObjectMapper? = null,
    @Autowired(required = false) private val playerStatsService: PlayerStatsService? = null,
    @Autowired(required = false) private val rustEngineAdapter: RustEngineAdapter? = null,
) {
    private val logger = LoggerFactory.getLogger(GameService::class.java)

    // In-memory cache of active Rust engine handles (rebuilt from DB on cache miss)
    private val games = ConcurrentHashMap<String, CachedGame>()

    /**
     * Creates a new game with the provided players.
     * Broadcasts the initial game state via WebSocket.
     */
    fun createGame(players: List<Player>): GameState {
        require(players.size == 2) { "Game must have exactly 2 players" }
        val adapter = requireAdapter()

        val gameId = generateGameId()
        val (engine, initialState) = adapter.createEngine(
            gameId,
            players[0].id, players[0].name,
            players[1].id, players[1].name,
        )
        games[gameId] = CachedGame(engine)

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
     */
    fun createGameWithAI(
        humanPlayerId: String,
        humanPlayerName: String,
        aiDifficulty: String = "basic"
    ): GameState {
        val adapter = requireAdapter()

        val gameId = generateGameId()
        val aiPlayerId = "ai_${Random.nextInt(1000, 9999)}"
        // Normalize difficulty to values the Rust engine understands
        val normalizedDifficulty = when (aiDifficulty.lowercase()) {
            "medium" -> "medium"
            "hard" -> "hard"
            else -> "basic"
        }
        val aiPlayerName = when (normalizedDifficulty) {
            "medium" -> "AI Opponent (Medium)"
            "hard" -> "AI Opponent (Hard)"
            else -> "AI Opponent"
        }

        val (engine, _) = adapter.createEngine(
            gameId,
            humanPlayerId, humanPlayerName,
            aiPlayerId, aiPlayerName,
        )
        games[gameId] = CachedGame(engine, aiPlayerId, normalizedDifficulty)

        // Process immediate AI actions (e.g. if AI is dealer's opponent during discard)
        val initialState = processAIActions(gameId)

        // Persist to database
        saveGameEntity(
            gameId,
            Player(humanPlayerId, humanPlayerName),
            Player(aiPlayerId, aiPlayerName),
            initialState,
            isAIGame = true, aiPlayerId = aiPlayerId, aiDifficulty = normalizedDifficulty
        )

        // Broadcast the initial game state via WebSocket if available
        webSocketService?.broadcastGameStateUpdate(gameId, initialState)
        logger.info("Created AI game {} for player {}", gameId, humanPlayerName)

        return initialState
    }

    /**
     * Applies a human player's action to the game and processes any subsequent AI actions.
     * Broadcasts the updated game state via WebSocket.
     */
    fun applyHumanAction(gameId: String, action: com.jackabee.cribbageclubserver.model.action.GameAction): GameState {
        val adapter = requireAdapter()
        val cached = games[gameId] ?: loadGame(gameId)
            ?: throw IllegalArgumentException("Game not found: $gameId")

        // Apply human action
        adapter.applyAction(cached.engine, action)

        // Process any AI actions that should follow
        val finalState = processAIActions(gameId)

        // Update database snapshot
        updateGameEntity(gameId, finalState)

        // Broadcast the updated game state via WebSocket if available
        webSocketService?.broadcastGameStateUpdate(gameId, finalState)

        return finalState
    }

    /**
     * Gets the current state of a game.
     */
    fun getGameState(gameId: String): GameState {
        val adapter = requireAdapter()

        // Try in-memory cache first
        val cached = games[gameId]
        if (cached != null) {
            return adapter.getState(cached.engine)
        }

        // Try to restore active game from database
        val restored = loadGame(gameId)
        if (restored != null) {
            return adapter.getState(restored.engine)
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
     */
    fun removeGame(gameId: String) {
        val cached = games.remove(gameId)
        cached?.engine?.close()

        // Remove from database
        gameRepository?.deleteById(gameId)
        logger.info("Removed game {}", gameId)
    }

    /**
     * Lists all active (non-finished) games.
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
        val adapter = requireAdapter()
        return games.mapValues { adapter.getState(it.value.engine) }
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
     * Finds active (in-progress) games for a player.
     */
    fun findActiveGamesByPlayer(playerId: String): List<GameState> {
        return gameRepository?.findActiveGamesByPlayer(playerId)?.map { deserializeGameState(it) } ?: emptyList()
    }

    /**
     * Finds completed games for a player.
     */
    fun findCompletedGamesByPlayer(playerId: String): List<GameState> {
        return gameRepository?.findCompletedGamesByPlayer(playerId)?.map { deserializeGameState(it) } ?: emptyList()
    }

    /**
     * Removes games that have been inactive for longer than the given duration.
     * Finished games (GAME_OVER) are always eligible for removal.
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
            val adapter = requireAdapter()
            for ((gameId, cached) in games) {
                val state = adapter.getState(cached.engine)
                if (state.stage == GameStage.GAME_OVER) {
                    removeGame(gameId)
                    removed.add(gameId)
                }
            }
        }
        return removed
    }

    /**
     * Imports completed local games into the server database.
     * Handles deduplication via originalLocalGameId, remaps 'local_player' IDs,
     * and records game stats for the human player.
     */
    fun importLocalGames(
        games: List<ImportGameRequest>,
        userId: String,
        username: String
    ): ImportGamesResponse {
        val mapper = objectMapper ?: throw IllegalStateException("ObjectMapper not available")
        val repo = gameRepository ?: throw IllegalStateException("GameRepository not available")

        val imported = mutableListOf<ImportedGameMapping>()
        val duplicates = mutableListOf<String>()
        val errors = mutableListOf<String>()

        for (game in games) {
            try {
                // Check for duplicate via originalLocalGameId
                val existing = repo.findByOriginalLocalGameId(game.localGameId)
                if (existing != null) {
                    duplicates.add(game.localGameId)
                    continue
                }

                // Deserialize the game state
                val state = mapper.readValue(game.stateJson, GameState::class.java)

                // Only import completed games
                if (state.stage != GameStage.GAME_OVER) {
                    errors.add("${game.localGameId}: game is not completed (stage=${state.stage})")
                    continue
                }

                // Remap IDs
                val newGameId = generateGameId()
                val remapped = remapGameState(state, newGameId, userId, username)

                // Determine player order (human is player1)
                val humanPlayer = remapped.players.first { it.id == userId }
                val aiPlayer = remapped.players.first { it.id != userId }

                // Determine timestamps
                val completedAt = game.completedAt?.let {
                    try { Instant.parse(it) } catch (_: Exception) { null }
                } ?: Instant.now()

                val entity = GameEntity(
                    id = newGameId,
                    player1Id = humanPlayer.id,
                    player1Name = humanPlayer.name,
                    player2Id = aiPlayer.id,
                    player2Name = aiPlayer.name,
                    player1Score = humanPlayer.score,
                    player2Score = aiPlayer.score,
                    stage = GameStage.GAME_OVER.name,
                    currentPlayerId = remapped.currentPlayerId,
                    isAIGame = true,
                    aiPlayerId = aiPlayer.id,
                    aiDifficulty = inferAiDifficulty(aiPlayer.name),
                    winnerId = remapped.players.maxByOrNull { it.score }?.id,
                    createdAt = completedAt,
                    updatedAt = completedAt,
                    stateJson = mapper.writeValueAsString(remapped),
                    originalLocalGameId = game.localGameId,
                )
                repo.save(entity)

                // Record stats for the human player
                val winner = remapped.players.maxByOrNull { it.score }
                if (winner != null && remapped.players.size == 2) {
                    val loser = remapped.players.first { it.id != winner.id }
                    playerStatsService?.recordGameResult(
                        winnerId = winner.id,
                        loserId = loser.id,
                        winnerScore = winner.score,
                        loserScore = loser.score
                    )
                }

                imported.add(ImportedGameMapping(game.localGameId, newGameId))
                logger.info("Imported local game {} as server game {}", game.localGameId, newGameId)
            } catch (e: Exception) {
                logger.warn("Failed to import local game {}: {}", game.localGameId, e.message)
                errors.add("${game.localGameId}: ${e.message}")
            }
        }

        return ImportGamesResponse(imported, duplicates, errors)
    }

    /**
     * Remaps a locally-played GameState to use server-side IDs.
     * Replaces 'local_player' with the authenticated user's ID/name,
     * and updates the gameId to the new server-generated ID.
     */
    private fun remapGameState(
        state: GameState,
        newGameId: String,
        userId: String,
        username: String
    ): GameState {
        val oldLocalId = "local_player"
        // Check if remapping is needed (games played while logged in already have real userId)
        val needsRemap = state.players.any { it.id == oldLocalId }
        val remapId = { id: String -> if (needsRemap && id == oldLocalId) userId else id }

        val remappedPlayers = state.players.map { player ->
            if (needsRemap && player.id == oldLocalId) {
                Player(userId, username, player.hand, player.score)
            } else {
                player
            }
        }

        val remappedHandsForCounting = state.handsForCounting.mapKeys { (key, _) -> remapId(key) }

        val remappedHistory = state.history.map { event ->
            when (event) {
                is GameHistoryEvent.CardsDealt -> event.copy(
                    dealtHands = event.dealtHands.mapKeys { (key, _) -> remapId(key) }
                )
                is GameHistoryEvent.DeckCut -> event.copy(
                    cuttingPlayerId = remapId(event.cuttingPlayerId)
                )
                is GameHistoryEvent.CardPlayed -> event.copy(
                    playerId = remapId(event.playerId)
                )
                is GameHistoryEvent.GoAnnounced -> event.copy(
                    playerId = remapId(event.playerId)
                )
                is GameHistoryEvent.HandCounted -> event.copy(
                    playerId = remapId(event.playerId)
                )
                is GameHistoryEvent.CribCounted -> event.copy(
                    dealerPlayerId = remapId(event.dealerPlayerId)
                )
                is GameHistoryEvent.GameEnded -> event.copy(
                    winnerPlayerId = remapId(event.winnerPlayerId)
                )
                is GameHistoryEvent.RoundStarted -> event
                is GameHistoryEvent.PeggingEnded -> event
            }
        }

        return state.copy(
            gameId = newGameId,
            players = remappedPlayers,
            currentPlayerId = state.currentPlayerId?.let { remapId(it) },
            handsForCounting = remappedHandsForCounting,
            history = remappedHistory
        )
    }

    private fun inferAiDifficulty(aiName: String): String {
        return when {
            aiName.contains("Hard", ignoreCase = true) -> "hard"
            aiName.contains("Medium", ignoreCase = true) -> "medium"
            else -> "basic"
        }
    }

    /**
     * Loads a game from the database, restores the Rust engine, and caches it.
     */
    private fun loadGame(gameId: String): CachedGame? {
        val repo = gameRepository ?: return null
        objectMapper ?: return null
        val adapter = requireAdapter()

        val entity = repo.findById(gameId).orElse(null) ?: return null
        val state = deserializeGameState(entity)

        // Don't restore finished games as playable engine handles
        if (state.stage == GameStage.GAME_OVER) return null

        val engine = adapter.restoreEngine(state)
        val cached = CachedGame(
            engine = engine,
            aiPlayerId = if (entity.isAIGame) entity.aiPlayerId else null,
            aiDifficulty = if (entity.isAIGame) (entity.aiDifficulty ?: "basic") else null,
        )
        games[gameId] = cached

        logger.info("Restored game {} from database", gameId)
        return cached
    }

    /**
     * Processes AI actions via the Rust engine.
     * Returns the current state (whether or not AI actions were processed).
     */
    private fun processAIActions(gameId: String): GameState {
        val adapter = requireAdapter()
        val cached = games[gameId]
            ?: throw IllegalStateException("No cached engine for game: $gameId")

        if (cached.aiPlayerId != null && cached.aiDifficulty != null) {
            return adapter.processAI(
                cached.engine,
                cached.aiPlayerId,
                cached.aiDifficulty,
                maxIterations = 10,
            )
        }

        return adapter.getState(cached.engine)
    }

    private fun requireAdapter(): RustEngineAdapter =
        rustEngineAdapter ?: throw IllegalStateException("RustEngineAdapter is not available")

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
