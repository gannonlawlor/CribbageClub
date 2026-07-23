package com.jackabee.cribbageclubserver.model.game

/**
 * Preset time controls a game can be played under.
 *
 * Each preset pairs a per-turn limit with a time bank. A player who exceeds the
 * turn limit draws the overage from their bank; when the bank is empty they
 * forfeit on time.
 *
 * These are the built-in defaults — deployments can override the numbers via
 * `cribbage.timer.overrides.*` (see [com.jackabee.cribbageclubserver.config.TimerProperties]).
 * The resolved values are frozen onto each game at creation, so changing config
 * never alters a game already in progress.
 */
enum class TimeControl(
    val defaultTurnTimeLimitMs: Long,
    val defaultTimeBankMs: Long
) {
    BLITZ(10_000, 60_000),
    RAPID(30_000, 120_000),
    CASUAL(60_000, 300_000),
    UNLIMITED(0, 0);

    /** Untimed games are never swept for timeouts and report `isTimed = false`. */
    val isTimed: Boolean get() = this != UNLIMITED

    companion object {
        /** Parses a stored/requested name, falling back to [fallback] when unrecognised. */
        fun parse(value: String?, fallback: TimeControl = RAPID): TimeControl {
            if (value == null) return fallback
            return entries.firstOrNull { it.name.equals(value, ignoreCase = true) } ?: fallback
        }
    }
}

/** The concrete limits a game is played under, after config overrides are applied. */
data class TimeSettings(
    val timeControl: TimeControl,
    val turnTimeLimitMs: Long,
    val timeBankMs: Long
) {
    val isTimed: Boolean get() = timeControl.isTimed
}
