package com.jackabee.cribbageclubserver.testutil

import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset

/** A clock tests advance by hand, so timing behaviour is verified without sleeping. */
class MutableClock(var instant: Instant = Instant.parse("2026-01-01T00:00:00Z")) : Clock() {
    override fun getZone(): ZoneId = ZoneOffset.UTC
    override fun withZone(zone: ZoneId): Clock = this
    override fun instant(): Instant = instant

    fun advance(duration: Duration) {
        instant = instant.plus(duration)
    }
}
