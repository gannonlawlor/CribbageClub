package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.entity.GameEntity
import com.jackabee.cribbageclubserver.model.game.GameResponse
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.game.GameStateFilter
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import java.time.Duration
import java.time.Instant
import java.util.concurrent.ConcurrentHashMap

@Service
class TurnTimerService {
    private val logger = LoggerFactory.getLogger(TurnTimerService::class.java)

    companion object {
        const val TURN_TIME_LIMIT_MS = 30_000L
        const val DEFAULT_TIME_BANK_MS = 120_000L
    }

    // In-memory turn start times for precise timing (synced to DB)
    private val turnStartTimes = ConcurrentHashMap<String, Instant>()

    /**
     * Records the start of a new turn. Called after each action is applied.
     */
    fun onTurnStart(gameId: String, entity: GameEntity) {
        val now = Instant.now()
        turnStartTimes[gameId] = now
        entity.turnStartedAt = now
    }

    /**
     * Called before applying a player's action. Deducts time from the player's
     * time bank if they exceeded the turn time limit.
     */
    fun onActionReceived(gameId: String, playerId: String, entity: GameEntity) {
        val turnStart = turnStartTimes[gameId] ?: entity.turnStartedAt ?: return
        val elapsed = Duration.between(turnStart, Instant.now()).toMillis()
        val overtime = elapsed - TURN_TIME_LIMIT_MS

        if (overtime > 0) {
            deductTimeBank(entity, playerId, overtime)
            logger.info("Player {} used {}ms from time bank in game {}", playerId, overtime, gameId)
        }
    }

    /**
     * Checks if any player has timed out (time bank exhausted).
     * Returns the timed-out player's ID, or null.
     */
    fun checkTimeout(gameId: String, entity: GameEntity): String? {
        val turnStart = turnStartTimes[gameId] ?: entity.turnStartedAt ?: return null
        val currentPlayerId = entity.currentPlayerId ?: return null
        val elapsed = Duration.between(turnStart, Instant.now()).toMillis()
        val overtime = elapsed - TURN_TIME_LIMIT_MS

        if (overtime <= 0) return null

        val remainingBank = getTimeBankForPlayer(entity, currentPlayerId)
        return if (remainingBank - overtime <= 0) currentPlayerId else null
    }

    /**
     * Builds a GameResponse with timing info for a specific viewing player.
     */
    fun buildGameResponse(
        gameId: String,
        entity: GameEntity,
        gameState: GameState,
        viewingPlayerId: String
    ): GameResponse {
        val isTimed = !entity.isAIGame
        val filtered = GameStateFilter.forPlayer(gameState, viewingPlayerId)

        if (!isTimed) {
            return GameResponse(gameState = filtered, isTimed = false)
        }

        val isPlayer1 = viewingPlayerId == entity.player1Id
        val myBank = if (isPlayer1) entity.player1TimeBankMs else entity.player2TimeBankMs
        val oppBank = if (isPlayer1) entity.player2TimeBankMs else entity.player1TimeBankMs

        return GameResponse(
            gameState = filtered,
            turnStartedAt = turnStartTimes[gameId] ?: entity.turnStartedAt,
            turnTimeLimitMs = TURN_TIME_LIMIT_MS,
            myTimeBankMs = myBank,
            opponentTimeBankMs = oppBank,
            isTimed = true
        )
    }

    /**
     * Builds timing fields for a WebSocket broadcast message.
     */
    fun getTimingFields(gameId: String, entity: GameEntity): TimingInfo {
        return TimingInfo(
            turnStartedAt = turnStartTimes[gameId] ?: entity.turnStartedAt,
            turnTimeLimitMs = TURN_TIME_LIMIT_MS,
            player1TimeBankMs = entity.player1TimeBankMs,
            player2TimeBankMs = entity.player2TimeBankMs,
            isTimed = !entity.isAIGame
        )
    }

    /**
     * Cleans up timer state when a game ends or is removed.
     */
    fun clearGame(gameId: String) {
        turnStartTimes.remove(gameId)
    }

    private fun deductTimeBank(entity: GameEntity, playerId: String, amount: Long) {
        if (playerId == entity.player1Id) {
            entity.player1TimeBankMs = (entity.player1TimeBankMs - amount).coerceAtLeast(0)
        } else {
            entity.player2TimeBankMs = (entity.player2TimeBankMs - amount).coerceAtLeast(0)
        }
    }

    private fun getTimeBankForPlayer(entity: GameEntity, playerId: String): Long {
        return if (playerId == entity.player1Id) entity.player1TimeBankMs else entity.player2TimeBankMs
    }
}

data class TimingInfo(
    val turnStartedAt: Instant?,
    val turnTimeLimitMs: Long,
    val player1TimeBankMs: Long,
    val player2TimeBankMs: Long,
    val isTimed: Boolean
)
