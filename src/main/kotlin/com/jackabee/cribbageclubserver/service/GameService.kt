package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.bridge.RustEngine
import com.jackabee.cribbageclubserver.bridge.RustEngineAdapter
import com.jackabee.cribbageclubserver.controller.ImportGameRequest
import com.jackabee.cribbageclubserver.controller.ImportGamesResponse
import com.jackabee.cribbageclubserver.controller.ImportedGameMapping
import com.jackabee.cribbageclubserver.entity.GameEntity
import com.jackabee.cribbageclubserver.model.action.ForfeitReason
import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.game.GameHistoryEvent
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.model.game.TimeControl
import com.jackabee.cribbageclubserver.model.player.Player
import com.jackabee.cribbageclubserver.repository.GameRepository
import com.jackabee.cribbageclubserver.websocket.GameWebSocketService
import com.fasterxml.jackson.databind.ObjectMapper
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.transaction.event.TransactionPhase
import org.springframework.transaction.event.TransactionalEventListener
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
    @Autowired(required = false) private val turnTimerService: TurnTimerService? = null,
    @Autowired(required = false) private val forfeitService: ForfeitService? = null,
) {
    private val logger = LoggerFactory.getLogger(GameService::class.java)

    // In-memory cache of active Rust engine handles (rebuilt from DB on cache miss)
    private val games = ConcurrentHashMap<String, CachedGame>()

    // Per-game monitors. An engine handle is a raw pointer into Rust memory, and
    // the engine is not thread-safe — two concurrent calls on the same handle are
    // a data race in native code, not just a logic bug. Concurrent actions on one
    // game are routine (both players discard at once), so every engine touch for
    // a game must hold that game's lock. Also prevents closing a handle out from
    // under a thread that is still using it.
    private val gameLocks = ConcurrentHashMap<String, Any>()

    private inline fun <T> withGameLock(gameId: String, block: () -> T): T =
        synchronized(gameLocks.computeIfAbsent(gameId) { Any() }, block)

    /**
     * Creates a new game with the provided players.
     * Broadcasts the initial game state via WebSocket.
     */
    fun createGame(players: List<Player>, timeControl: TimeControl? = null): GameState {
        require(players.size == 2) { "Game must have exactly 2 players" }
        val adapter = requireAdapter()

        val gameId = generateGameId()
        val (engine, initialState) = adapter.createEngine(
            gameId,
            players[0].id, players[0].name,
            players[1].id, players[1].name,
        )
        games[gameId] = CachedGame(engine)

        val resolved = timeControl
            ?: turnTimerService?.defaultTimeControl()
            ?: TimeControl.RAPID

        // Persist to database
        val entity = saveGameEntity(
            gameId, players[0], players[1], initialState,
            isAIGame = false, timeControl = resolved
        )

        // Start turn timer for online games
        if (entity != null) {
            turnTimerService?.onTurnStart(gameId, entity, initialState)
            gameRepository?.save(entity)
        }

        // Broadcast the initial game state via WebSocket if available
        val timing = entity?.let { turnTimerService?.getTimingFields(gameId, it) }
        webSocketService?.broadcastGameStateUpdate(gameId, initialState, timing)
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
            isAIGame = true, aiPlayerId = aiPlayerId, aiDifficulty = normalizedDifficulty,
            timeControl = TimeControl.UNLIMITED
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
    fun applyHumanAction(gameId: String, action: GameAction): GameState {
        // Handle forfeit action separately (bypass Rust engine)
        if (action is GameAction.Forfeit) {
            val fs = forfeitService ?: throw IllegalStateException("ForfeitService not available")
            return fs.forfeitGame(gameId, action.playerId, action.reason)
        }

        val adapter = requireAdapter()

        return withGameLock(gameId) {
            val cached = games[gameId] ?: loadGame(gameId)
                ?: throw IllegalArgumentException("Game not found: $gameId")

            // Load the row once. Every mutation below lands on this instance and is
            // flushed in a single save, so the action never writes the row twice —
            // a second write against a stale copy would trip @Version optimistic locking.
            val entity = gameRepository?.findById(gameId)?.orElse(null)

            // The timeout sweep may have forfeited this game between the client
            // seeing it live and this action arriving. Without this guard the
            // action would overwrite the terminal row with a live stage.
            if (entity?.winnerId != null) {
                throw IllegalStateException("Game is already over")
            }

            // Apply human action. Deliberately before any timer bookkeeping: a
            // rejected action must leave the player's clock running, or an invalid
            // move would take them off the clock and let them stall unswept.
            adapter.applyAction(cached.engine, action)

            // Charge any overage to the acting player. No-ops for AI and UNLIMITED games.
            if (entity != null) {
                turnTimerService?.onActionReceived(gameId, action.playerId, entity)
            }

            // Process any AI actions that should follow
            val finalState = processAIActions(gameId)

            if (entity != null) {
                applyStateToEntity(entity, finalState)

                if (finalState.stage == GameStage.GAME_OVER) {
                    entity.turnStartedAt = null
                    turnTimerService?.clearGame(gameId)
                } else {
                    turnTimerService?.onTurnStart(gameId, entity, finalState)
                }

                gameRepository?.save(entity)
            }

            // Finished games must not linger as live engine handles.
            if (finalState.stage == GameStage.GAME_OVER) {
                evictCachedEngine(gameId)
            }

            // Broadcast with timing info
            val timing = entity?.let { turnTimerService?.getTimingFields(gameId, it) }
            webSocketService?.broadcastGameStateUpdate(gameId, finalState, timing)

            finalState
        }
    }

    /**
     * Gets the current state of a game.
     */
    fun getGameState(gameId: String): GameState = withGameLock(gameId) {
        val adapter = requireAdapter()

        // Try in-memory cache first
        val cached = games[gameId]
        if (cached != null) {
            return@withGameLock adapter.getState(cached.engine)
        }

        // Try to restore active game from database
        val restored = loadGame(gameId)
        if (restored != null) {
            return@withGameLock adapter.getState(restored.engine)
        }

        // Fall back to raw DB state (for finished games)
        val entity = gameRepository?.findById(gameId)?.orElse(null)
        if (entity != null) {
            return@withGameLock deserializeGameState(entity)
        }

        throw IllegalArgumentException("Game not found: $gameId")
    }

    /**
     * Drops a finished game's engine handle so reads fall back to the database.
     * Without this, a forfeit or timeout leaves the in-memory engine in play and
     * `getGameState` keeps returning the game as if it were still running.
     *
     * Runs after commit so a concurrent read can't reload and re-cache the
     * pre-forfeit row; `fallbackExecution` keeps it working outside a transaction.
     */
    @TransactionalEventListener(
        phase = TransactionPhase.AFTER_COMMIT,
        fallbackExecution = true
    )
    fun onGameEnded(event: GameEndedEvent) {
        withGameLock(event.gameId) {
            if (evictCachedEngine(event.gameId)) {
                logger.info("Dropped cached engine for ended game {}", event.gameId)
            }
        }
    }

    /**
     * Removes a game from the service and database.
     */
    fun removeGame(gameId: String) {
        withGameLock(gameId) {
            turnTimerService?.clearGame(gameId)
            evictCachedEngine(gameId)

            // Remove from database
            gameRepository?.deleteById(gameId)
        }
        gameLocks.remove(gameId)
        logger.info("Removed game {}", gameId)
    }

    /**
     * Closes and forgets the in-memory engine handle for a game, if any.
     * Callers must hold the game lock — closing frees native memory, and a
     * concurrent engine call on the freed handle is a use-after-free.
     */
    private fun evictCachedEngine(gameId: String): Boolean {
        val cached = games.remove(gameId) ?: return false
        cached.engine.close()
        return true
    }

    /**
     * Gets the GameEntity for a game (used by controller for timing info).
     */
    fun getGameEntity(gameId: String): GameEntity? {
        return gameRepository?.findById(gameId)?.orElse(null)
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
    /**
     * Evicts in-memory engine handles for games that are finished or idle past
     * [inactiveThreshold], so the native-memory cache doesn't grow unbounded.
     *
     * This releases memory only — it must never delete rows. Completed games are
     * the user's history (`/me/history`, head-to-head, post-game analysis), and
     * an idle game is not an abandoned one: UNLIMITED games can legitimately sit
     * for days, and timed games are ended by the timeout sweep, not by cleanup.
     * An earlier version deleted both, which silently destroyed every finished
     * game within minutes of it ending. Evicted games reload from the database
     * on the next access.
     */
    fun removeInactiveGames(inactiveThreshold: Instant): List<String> {
        val evicted = mutableListOf<String>()
        val repo = gameRepository

        for (gameId in games.keys.toList()) {
            val shouldEvict = if (repo != null) {
                val entity = repo.findById(gameId).orElse(null)
                // Row gone (explicitly deleted) counts as evictable too.
                entity == null ||
                    entity.stage == GameStage.GAME_OVER.name ||
                    entity.updatedAt.isBefore(inactiveThreshold)
            } else {
                // No DB: evict only finished games (no activity tracking without a row)
                val adapter = requireAdapter()
                withGameLock(gameId) {
                    games[gameId]?.let { adapter.getState(it.engine).stage == GameStage.GAME_OVER } ?: false
                }
            }

            if (shouldEvict) {
                withGameLock(gameId) {
                    turnTimerService?.clearGame(gameId)
                    if (evictCachedEngine(gameId)) {
                        evicted.add(gameId)
                    }
                }
                gameLocks.remove(gameId)
            }
        }
        return evicted
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
                val humanPlayer = remapped.players.firstOrNull { it.id == userId }
                val aiPlayer = remapped.players.firstOrNull { it.id != userId }
                if (humanPlayer == null || aiPlayer == null) {
                    errors.add(
                        "${game.localGameId}: could not tell which player is you " +
                            "(players: ${remapped.players.joinToString { it.id }})"
                    )
                    continue
                }

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
                    timeControl = TimeControl.UNLIMITED.name,
                    turnTimeLimitMs = 0,
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
                        loserScore = loser.score,
                        isAIGame = entity.isAIGame
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
        // The human is whichever player isn't the engine. Their recorded id
        // may be "local_player", a guest id, or an id from a previous sign-in —
        // all of them have to become the importing user, or the game can never
        // be attributed to anyone.
        val aiId = state.players.firstOrNull { it.id.startsWith("ai_") }?.id
        val oldLocalId = state.players.firstOrNull { it.id != aiId }?.id
        val needsRemap = oldLocalId != null && oldLocalId != userId
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
                is GameHistoryEvent.GameForfeited -> event.copy(
                    forfeitingPlayerId = remapId(event.forfeitingPlayerId)
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
        aiDifficulty: String? = null,
        timeControl: TimeControl = TimeControl.RAPID
    ): GameEntity? {
        val mapper = objectMapper ?: return null
        val repo = gameRepository ?: return null

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

        // Freeze the resolved time limits onto the game before its first save.
        turnTimerService?.initializeGame(entity, timeControl)
            ?: run { entity.timeControl = timeControl.name }

        repo.save(entity)
        return entity
    }

    /**
     * Copies a game state onto its entity without saving. The caller owns the save,
     * so a single action results in exactly one write to the row.
     */
    private fun applyStateToEntity(entity: GameEntity, state: GameState) {
        val mapper = objectMapper ?: return

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
                    loserScore = loser.score,
                    isAIGame = entity.isAIGame
                )
            }
        }
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
