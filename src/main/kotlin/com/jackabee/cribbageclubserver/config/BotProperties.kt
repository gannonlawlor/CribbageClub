package com.jackabee.cribbageclubserver.config

import com.jackabee.cribbageclubserver.model.game.GameStage
import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.stereotype.Component
import kotlin.random.Random

/**
 * Bot fallback matchmaking configuration.
 *
 * ```properties
 * cribbage.bots.enabled=true
 * cribbage.bots.wait-seconds=60
 * cribbage.bots.delays.pegging.min-ms=1500
 * cribbage.bots.delays.pegging.max-ms=4500
 * ```
 *
 * Delays make a bot's moves feel human: each action is scheduled after a jittered
 * "thinking" pause picked from the acting stage's range. In timed games the pause
 * is capped at a fraction of the turn limit so a bot never draws on its time bank.
 */
private const val DEFAULT_WAIT_SECONDS = 60L
private const val DEFAULT_MATCH_SWEEP_INTERVAL_MS = 10_000L
private const val DEFAULT_MOVE_SWEEP_INTERVAL_MS = 5_000L
private const val DEFAULT_MAX_DELAY_FRACTION = 0.5
private const val DISCARD_MIN_MS = 3_000L
private const val DISCARD_MAX_MS = 8_000L
private const val CUT_MIN_MS = 1_000L
private const val CUT_MAX_MS = 2_500L
private const val PEGGING_MIN_MS = 1_500L
private const val PEGGING_MAX_MS = 4_500L
private const val COUNT_MIN_MS = 2_000L
private const val COUNT_MAX_MS = 5_000L
private const val FALLBACK_MIN_MS = 1_000L
private const val FALLBACK_MAX_MS = 2_500L

@Component
@ConfigurationProperties(prefix = "cribbage.bots")
class BotProperties {
    /** Master switch — when false, no bot ever joins a lobby or moves. */
    var enabled: Boolean = true

    /** How long a quick-match lobby must sit unfilled before a bot joins. */
    var waitSeconds: Long = DEFAULT_WAIT_SECONDS

    /** How often the matchmaking sweep looks for stale quick-match lobbies. */
    var matchSweepIntervalMs: Long = DEFAULT_MATCH_SWEEP_INTERVAL_MS

    /** How often the self-healing move sweep re-checks active bot games. */
    var moveSweepIntervalMs: Long = DEFAULT_MOVE_SWEEP_INTERVAL_MS

    /**
     * Ceiling on any single delay in a timed game, as a fraction of the game's
     * per-turn limit. Coerced into 0..1 — above 1.0 the bot would dip into its
     * time bank while "thinking", and eventually forfeit on time.
     */
    var maxDelayFractionOfTurnLimit: Double = DEFAULT_MAX_DELAY_FRACTION
        set(value) {
            field = value.coerceIn(0.0, 1.0)
        }

    /** Jitter range for one delayed action, in milliseconds. */
    class DelayRange(var minMs: Long = FALLBACK_MIN_MS, var maxMs: Long = FALLBACK_MAX_MS)

    /** Per-stage delay ranges, keyed by the stage the game is in when the bot acts. */
    var delays: Delays = Delays()

    class Delays {
        /** Per discarded card — a discard phase is two separately delayed steps. */
        var discard: DelayRange = DelayRange(DISCARD_MIN_MS, DISCARD_MAX_MS)
        var cut: DelayRange = DelayRange(CUT_MIN_MS, CUT_MAX_MS)
        /** Pegging plays and Go announcements. */
        var pegging: DelayRange = DelayRange(PEGGING_MIN_MS, PEGGING_MAX_MS)
        var count: DelayRange = DelayRange(COUNT_MIN_MS, COUNT_MAX_MS)
        /** Anything else (e.g. DEALING edge states). */
        var default: DelayRange = DelayRange(FALLBACK_MIN_MS, FALLBACK_MAX_MS)
    }

    /**
     * Picks a jittered thinking delay for a bot acting during [stage], capped for
     * timed games by [turnTimeLimitMs] (pass null/0 for untimed games).
     */
    fun pickDelayMs(stage: GameStage, turnTimeLimitMs: Long?): Long {
        val range = when (stage) {
            GameStage.DISCARDING_TO_CRIB -> delays.discard
            GameStage.CUTTING -> delays.cut
            GameStage.PEGGING -> delays.pegging
            GameStage.COUNTING -> delays.count
            else -> delays.default
        }
        val max = maxOf(range.minMs, range.maxMs)
        val raw = Random.nextLong(range.minMs, max + 1)
        val cap = turnTimeLimitMs?.takeIf { it > 0 }
            ?.let { (it * maxDelayFractionOfTurnLimit).toLong() }
        return if (cap != null) raw.coerceAtMost(cap) else raw
    }
}
