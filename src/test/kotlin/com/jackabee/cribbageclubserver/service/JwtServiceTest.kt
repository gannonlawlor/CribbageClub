package com.jackabee.cribbageclubserver.service

import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class JwtServiceTest {

    private val jwtService = JwtService(
        secret = "test-secret-key-that-is-at-least-256-bits-long-for-hs256!!",
        expirationMs = 3600000 // 1 hour
    )

    @Test
    fun `should generate and validate token`() {
        val token = jwtService.generateToken("user123", "testuser")
        assertTrue(jwtService.isTokenValid(token))
    }

    @Test
    fun `should extract userId from token`() {
        val token = jwtService.generateToken("user123", "testuser")
        assertEquals("user123", jwtService.getUserIdFromToken(token))
    }

    @Test
    fun `should extract username from token`() {
        val token = jwtService.generateToken("user123", "testuser")
        assertEquals("testuser", jwtService.getUsernameFromToken(token))
    }

    @Test
    fun `should reject invalid token`() {
        assertFalse(jwtService.isTokenValid("invalid.token.here"))
    }

    @Test
    fun `should reject tampered token`() {
        val token = jwtService.generateToken("user123", "testuser")
        val tampered = token.dropLast(5) + "XXXXX"
        assertFalse(jwtService.isTokenValid(tampered))
    }

    @Test
    fun `should return null for invalid token userId`() {
        assertNull(jwtService.getUserIdFromToken("bad.token"))
    }

    @Test
    fun `should reject expired token`() {
        val expiredService = JwtService(
            secret = "test-secret-key-that-is-at-least-256-bits-long-for-hs256!!",
            expirationMs = -1000 // already expired
        )
        val token = expiredService.generateToken("user123", "testuser")
        assertFalse(expiredService.isTokenValid(token))
    }

    @Test
    fun `should default isGuest to false`() {
        val token = jwtService.generateToken("user123", "testuser")
        assertFalse(jwtService.isGuestFromToken(token))
    }

    @Test
    fun `should store isGuest true in token`() {
        val token = jwtService.generateToken("guest_123", "guest_123", isGuest = true)
        assertTrue(jwtService.isGuestFromToken(token))
    }

    @Test
    fun `should return false for isGuest on invalid token`() {
        assertFalse(jwtService.isGuestFromToken("bad.token"))
    }
}
