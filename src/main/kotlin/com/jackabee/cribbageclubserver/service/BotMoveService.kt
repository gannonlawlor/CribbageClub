package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.config.BotProperties
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.model.game.TimeControl
import com.jackabee.cribbageclubserver.repository.GameRepository
import jakarta.annotation.PreDestroy
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.context.event.EventListener
import org.springframework.scheduling.TaskScheduler
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler
import org.springframework.stereotype.Service
import java.time.Instant
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ScheduledFuture

/**
 * Drives fallback-matchmaking bots with human-feeling delays.
 *
 * Each pending bot move is a one-shot task on a dedicated scheduler (never the
 * single `@Scheduled` thread that [TimeoutCheckService] needs). The [pending]
 * map deduplicates: the [BotActionPendingEvent] listener and the self-healing
 * sweep both funnel through [maybeSchedule], which schedules only if nothing is
 * already queued for the game. [executeMove] removes its entry before acting and
 * chains another delayed step while the bot still owes one (second discard,
 * counting runs).
 *
 * The sweep repopulates the map after missed events and server restarts —
 * single-node in-memory state, like the engine cache it drives. Worst case the
 * bot "thinks" for one sweep interval plus its delay, which is indistinguishable
 * from a slow human. If this service fails entirely, the timeout sweep forfeits
 * the *bot* and the human wins a rated game — a graceful failure mode.
 */
@Service
class BotMoveService(
    private val gameService: GameService,
    private val gameRepository: GameRepository,
    private val botProperties: BotProperties,
    @Autowired(required = false) injectedScheduler: TaskScheduler? = null,
) {
    private val logger = LoggerFactory.getLogger(BotMoveService::class.java)

    private val ownScheduler: ThreadPoolTaskScheduler? = if (injectedScheduler == null) {
        ThreadPoolTaskScheduler().apply {
            poolSize = 2
            setThreadNamePrefix("bot-move-")
            initialize()
        }
    } else {
        null
    }

    private val scheduler: TaskScheduler = injectedScheduler ?: ownScheduler!!

    /** gameId -> the one queued move for that game. */
    private val pending = ConcurrentHashMap<String, ScheduledFuture<*>>()

    @PreDestroy
    fun shutdown() {
        ownScheduler?.shutdown()
    }

    @EventListener
    fun onBotActionPending(event: BotActionPendingEvent) {
        maybeSchedule(event.gameId)
    }

    /** Self-healing: covers missed events and repopulates after a restart. */
    @Scheduled(fixedDelayString = "\${cribbage.bots.move-sweep-interval-ms:5000}")
    fun sweep() {
        if (!botProperties.enabled) return
        for (entity in gameRepository.findActiveBotGames()) {
            maybeSchedule(entity.id)
        }
    }

    /** Schedules a delayed bot move unless one is already queued for the game. */
    fun maybeSchedule(gameId: String) {
        if (!botProperties.enabled) return
        pending.computeIfAbsent(gameId) {
            val delayMs = pickDelay(gameId)
            scheduler.schedule({ executeMove(gameId) }, Instant.now().plusMillis(delayMs))
        }
    }

    private fun pickDelay(gameId: String): Long {
        val entity = gameRepository.findById(gameId).orElse(null)
        val stage = entity?.stage
            ?.let { runCatching { GameStage.valueOf(it) }.getOrNull() }
            ?: GameStage.PEGGING
        val isTimed = entity != null && !entity.isAIGame && TimeControl.parse(entity.timeControl).isTimed
        return botProperties.pickDelayMs(stage, if (isTimed) entity!!.turnTimeLimitMs else null)
    }

    @Suppress("TooGenericExceptionCaught") // Resilience boundary: any failure defers to the sweep.
    private fun executeMove(gameId: String) {
        // Remove before acting so an event landing mid-move can queue the next step.
        pending.remove(gameId)
        try {
            val result = gameService.advanceBotGame(gameId)
            if (result?.botStillPending == true) {
                maybeSchedule(gameId)
            }
        } catch (e: Exception) {
            // Includes optimistic-lock failures from a concurrent timeout forfeit.
            // Never rethrow — the sweep retries if the game is still live.
            logger.warn("Bot move failed for game {} (sweep will retry): {}", gameId, e.message)
        }
    }
}
