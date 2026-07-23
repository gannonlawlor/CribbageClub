package com.jackabee.cribbageclubserver.config

import com.jackabee.cribbageclubserver.model.game.TimeControl
import com.jackabee.cribbageclubserver.model.game.TimeSettings
import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.stereotype.Component

/**
 * Turn-timer configuration.
 *
 * ```properties
 * cribbage.timer.default-time-control=RAPID
 * cribbage.timer.overrides.BLITZ.turn-time-limit-ms=15000
 * cribbage.timer.overrides.BLITZ.time-bank-ms=45000
 * ```
 *
 * Anything not overridden falls back to the preset's built-in values.
 */
@Component
@ConfigurationProperties(prefix = "cribbage.timer")
class TimerProperties {
    /** Time control used when a client does not request one (e.g. quick-match). */
    var defaultTimeControl: TimeControl = TimeControl.RAPID

    /** Per-preset overrides of the built-in limits. */
    var overrides: MutableMap<TimeControl, Override> = mutableMapOf()

    class Override {
        var turnTimeLimitMs: Long? = null
        var timeBankMs: Long? = null
    }

    /** Resolves a preset to the concrete limits a new game should be frozen at. */
    fun resolve(timeControl: TimeControl): TimeSettings {
        val override = overrides[timeControl]
        return TimeSettings(
            timeControl = timeControl,
            turnTimeLimitMs = override?.turnTimeLimitMs ?: timeControl.defaultTurnTimeLimitMs,
            timeBankMs = override?.timeBankMs ?: timeControl.defaultTimeBankMs
        )
    }
}
