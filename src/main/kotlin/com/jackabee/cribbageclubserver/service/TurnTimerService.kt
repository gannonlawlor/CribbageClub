package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.config.TimerProperties
import com.jackabee.cribbageclubserver.entity.GameEntity
import com.jackabee.cribbageclubserver.model.game.GameResponse
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.game.GameStateFilter
import com.jackabee.cribbageclubserver.model.game.TimeControl
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.util.concurrent.ConcurrentHashMap

/**
 * Enforces per-turn time limits.
 *
 * Each player who is on the clock has their own start instant. A player who takes
 * longer than the game's turn limit draws the overage from their time bank; when
 * the bank runs out they forfeit on time (see [TimeoutCheckService]).
 *
 * Clocks are per-player rather than per-game because `DISCARDING_TO_CRIB` lets both
 * players act concurrently — the engine does not gate discards on `currentPlayerId`.
 * With a single shared clock, whichever player acted second was charged for time the
 * other one burned, and a player's clock reset every time their opponent moved.
 *
 * The in-memory clocks are the precise source; `GameEntity.turnStartedAt` is the
 * persisted fallback used after a restart, when it degrades to a single clock on
 * `currentPlayerId` until the next action rebuilds the per-player state.
 */
@Service
class TurnTimerService(
    private val timerProperties: TimerProperties = TimerProperties(),
    /** Overridden in tests to advance time without sleeping. */
    private val clock: Clock = Clock.systemUTC()
) {
    private val logger = LoggerFactory.getLogger(TurnTimerService::class.java)

    companion object {
        /** Cards a player keeps after discarding to the crib. */
        private const val KEEP_CARDS = 4
    }

    /** gameId -> (playerId -> instant their current turn began) */
    private val clocks = ConcurrentHashMap<String, ConcurrentHashMap<String, Instant>>()

    /**
     * Freezes the resolved limits for [timeControl] onto a newly created game.
     * Frozen at creation so later config changes never alter a game in progress.
     */
    fun initializeGame(entity: GameEntity, timeControl: TimeControl) {
        val settings = timerProperties.resolve(timeControl)
        entity.timeControl = settings.timeControl.name
        entity.turnTimeLimitMs = settings.turnTimeLimitMs
        entity.player1TimeBankMs = settings.timeBankMs
        entity.player2TimeBankMs = settings.timeBankMs
    }

    /** The default time control for clients that don't request one. */
    fun defaultTimeControl(): TimeControl = timerProperties.defaultTimeControl

    /**
     * Starts the clock for every player who now owes an action. Players already on
     * the clock keep their existing start instant — an opponent moving must not
     * hand a stalling player a fresh allowance.
     */
    fun onTurnStart(gameId: String, entity: GameEntity, state: GameState? = null) {
        if (!isTimed(entity)) return

        val now = Instant.now(clock)
        val onClock = playersOnClock(entity, state)
        if (onClock.isEmpty()) {
            clearGame(gameId)
            entity.turnStartedAt = null
            return
        }

        val gameClocks = clocks.computeIfAbsent(gameId) { ConcurrentHashMap() }
        gameClocks.keys.retainAll(onClock)
        for (playerId in onClock) {
            gameClocks.putIfAbsent(playerId, now)
        }

        // Persisted fallback for post-restart recovery. Prefer the current player's
        // clock; otherwise the earliest running one, so the stored instant never
        // understates how long someone has been on the clock.
        entity.turnStartedAt = entity.currentPlayerId?.let { gameClocks[it] }
            ?: gameClocks.values.minOrNull()
            ?: now
    }

    /**
     * Called before a player's action is applied. Charges any overage against that
     * player's own bank and stops their clock; [onTurnStart] restarts it if they
     * still owe an action.
     */
    fun onActionReceived(gameId: String, playerId: String, entity: GameEntity) {
        if (!isTimed(entity)) return

        val start = clockStart(gameId, playerId, entity) ?: return
        clocks[gameId]?.remove(playerId)

        val overtime = overtimeMs(start, entity.turnTimeLimitMs)
        if (overtime > 0) {
            deductTimeBank(entity, playerId, overtime)
            logger.info("Player {} used {}ms from time bank in game {}", playerId, overtime, gameId)
        }
    }

    /**
     * Returns the id of a player whose time bank is exhausted, or null.
     * Checks every player currently on the clock, not just the nominal current player.
     */
    fun checkTimeout(gameId: String, entity: GameEntity): String? {
        if (!isTimed(entity)) return null

        val running = clocks[gameId]?.toMap()
            ?: entity.currentPlayerId?.let { current ->
                entity.turnStartedAt?.let { mapOf(current to it) }
            }
            ?: return null

        for ((playerId, start) in running) {
            val overtime = overtimeMs(start, entity.turnTimeLimitMs)
            if (overtime > 0 && timeBankOf(entity, playerId) - overtime <= 0) {
                return playerId
            }
        }
        return null
    }

    /**
     * Builds a [GameResponse] with timing info from one player's point of view.
     * `turnStartedAt` is the viewer's own clock when they're on it, so a player
     * waiting on a concurrent discard sees their real deadline.
     */
    fun buildGameResponse(
        gameId: String,
        entity: GameEntity,
        gameState: GameState,
        viewingPlayerId: String
    ): GameResponse {
        val filtered = GameStateFilter.forPlayer(gameState, viewingPlayerId)
        val timeControl = TimeControl.parse(entity.timeControl)

        if (!isTimed(entity)) {
            return GameResponse(gameState = filtered, isTimed = false, timeControl = timeControl.name)
        }

        val isPlayer1 = viewingPlayerId == entity.player1Id
        val myBank = if (isPlayer1) entity.player1TimeBankMs else entity.player2TimeBankMs
        val oppBank = if (isPlayer1) entity.player2TimeBankMs else entity.player1TimeBankMs
        val gameClocks = clocks[gameId]
        val turnStartedAt = gameClocks?.get(viewingPlayerId)
            ?: entity.currentPlayerId?.let { gameClocks?.get(it) }
            ?: entity.turnStartedAt

        return GameResponse(
            gameState = filtered,
            turnStartedAt = turnStartedAt,
            turnTimeLimitMs = entity.turnTimeLimitMs,
            myTimeBankMs = myBank,
            opponentTimeBankMs = oppBank,
            isTimed = true,
            timeControl = timeControl.name
        )
    }

    /** Builds timing fields for a WebSocket broadcast. */
    fun getTimingFields(gameId: String, entity: GameEntity): TimingInfo {
        val gameClocks = clocks[gameId]
        return TimingInfo(
            turnStartedAt = entity.currentPlayerId?.let { gameClocks?.get(it) } ?: entity.turnStartedAt,
            turnTimeLimitMs = entity.turnTimeLimitMs,
            player1TimeBankMs = entity.player1TimeBankMs,
            player2TimeBankMs = entity.player2TimeBankMs,
            isTimed = isTimed(entity),
            timeControl = TimeControl.parse(entity.timeControl).name
        )
    }

    /** Drops all clock state for a game that has ended or been removed. */
    fun clearGame(gameId: String) {
        clocks.remove(gameId)
    }

    private fun isTimed(entity: GameEntity): Boolean =
        !entity.isAIGame && TimeControl.parse(entity.timeControl).isTimed

    /**
     * Who owes an action right now. During `DISCARDING_TO_CRIB` that is every player
     * still holding more than [KEEP_CARDS] cards, since the engine accepts discards
     * from either player in any order.
     */
    private fun playersOnClock(entity: GameEntity, state: GameState?): Set<String> {
        if (state == null) return setOfNotNull(entity.currentPlayerId)

        return when (state.stage) {
            GameStage.GAME_OVER -> emptySet()
            GameStage.DISCARDING_TO_CRIB ->
                state.players.filter { it.hand.size > KEEP_CARDS }.map { it.id }.toSet()
            else -> setOfNotNull(state.currentPlayerId)
        }
    }

    private fun clockStart(gameId: String, playerId: String, entity: GameEntity): Instant? {
        clocks[gameId]?.get(playerId)?.let { return it }
        // Post-restart fallback: only the nominal current player has a known clock.
        return if (entity.currentPlayerId == playerId) entity.turnStartedAt else null
    }

    private fun overtimeMs(start: Instant, turnTimeLimitMs: Long): Long =
        Duration.between(start, Instant.now(clock)).toMillis() - turnTimeLimitMs

    private fun deductTimeBank(entity: GameEntity, playerId: String, amount: Long) {
        if (playerId == entity.player1Id) {
            entity.player1TimeBankMs = (entity.player1TimeBankMs - amount).coerceAtLeast(0)
        } else {
            entity.player2TimeBankMs = (entity.player2TimeBankMs - amount).coerceAtLeast(0)
        }
    }

    private fun timeBankOf(entity: GameEntity, playerId: String): Long =
        if (playerId == entity.player1Id) entity.player1TimeBankMs else entity.player2TimeBankMs
}

data class TimingInfo(
    val turnStartedAt: Instant?,
    val turnTimeLimitMs: Long,
    val player1TimeBankMs: Long,
    val player2TimeBankMs: Long,
    val isTimed: Boolean,
    val timeControl: String = TimeControl.RAPID.name
)
