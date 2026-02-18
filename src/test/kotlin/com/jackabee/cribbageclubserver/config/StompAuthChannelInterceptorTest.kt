package com.jackabee.cribbageclubserver.config

import com.jackabee.cribbageclubserver.service.JwtService
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.springframework.messaging.simp.stomp.StompCommand
import org.springframework.messaging.simp.stomp.StompHeaderAccessor
import org.springframework.messaging.support.MessageBuilder
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class StompAuthChannelInterceptorTest {

    private val jwtService = JwtService(
        secret = "test-secret-key-that-is-at-least-256-bits-long-for-hs256!!",
        expirationMs = 3600000
    )
    private val interceptor = StompAuthChannelInterceptor(jwtService)

    private fun buildConnectMessage(authHeader: String?): org.springframework.messaging.Message<*> {
        val accessor = StompHeaderAccessor.create(StompCommand.CONNECT)
        accessor.sessionId = "test-session"
        accessor.sessionAttributes = mutableMapOf<String, Any>()
        if (authHeader != null) {
            accessor.addNativeHeader("Authorization", authHeader)
        }
        // Keep headers mutable so the interceptor can set user/sessionAttributes
        // (matches Spring's real pipeline behavior)
        accessor.setLeaveMutable(true)
        return MessageBuilder.createMessage(ByteArray(0), accessor.messageHeaders)
    }

    private fun buildSendMessage(): org.springframework.messaging.Message<*> {
        val accessor = StompHeaderAccessor.create(StompCommand.SEND)
        accessor.sessionId = "test-session"
        accessor.destination = "/app/game/action"
        return MessageBuilder.createMessage(ByteArray(0), accessor.messageHeaders)
    }

    @Test
    fun `valid JWT on CONNECT sets userId and username in session attributes`() {
        val token = jwtService.generateToken("user123", "alice")
        val message = buildConnectMessage("Bearer $token")

        val result = interceptor.preSend(message, FakeChannel())

        assertNotNull(result)
        val accessor = StompHeaderAccessor.wrap(result)
        assertEquals("user123", accessor.sessionAttributes?.get("userId"))
        assertEquals("alice", accessor.sessionAttributes?.get("username"))
    }

    @Test
    fun `valid JWT on CONNECT sets user principal`() {
        val token = jwtService.generateToken("user123", "alice")
        val message = buildConnectMessage("Bearer $token")

        val result = interceptor.preSend(message, FakeChannel())

        assertNotNull(result)
        val accessor = StompHeaderAccessor.wrap(result)
        assertNotNull(accessor.user)
        assertEquals("user123", accessor.user?.name)
    }

    @Test
    fun `CONNECT without Authorization header is rejected`() {
        val message = buildConnectMessage(null)

        assertThrows<IllegalArgumentException> {
            interceptor.preSend(message, FakeChannel())
        }
    }

    @Test
    fun `CONNECT with malformed Authorization header is rejected`() {
        val message = buildConnectMessage("NotBearer some-token")

        assertThrows<IllegalArgumentException> {
            interceptor.preSend(message, FakeChannel())
        }
    }

    @Test
    fun `CONNECT with invalid JWT is rejected`() {
        val message = buildConnectMessage("Bearer invalid.jwt.token")

        assertThrows<IllegalArgumentException> {
            interceptor.preSend(message, FakeChannel())
        }
    }

    @Test
    fun `CONNECT with expired JWT is rejected`() {
        val expiredJwtService = JwtService(
            secret = "test-secret-key-that-is-at-least-256-bits-long-for-hs256!!",
            expirationMs = -1000
        )
        val token = expiredJwtService.generateToken("user123", "alice")
        val message = buildConnectMessage("Bearer $token")

        assertThrows<IllegalArgumentException> {
            interceptor.preSend(message, FakeChannel())
        }
    }

    @Test
    fun `non-CONNECT messages pass through without auth check`() {
        val message = buildSendMessage()

        val result = interceptor.preSend(message, FakeChannel())

        assertNotNull(result)
    }

    @Test
    fun `valid non-guest JWT sets isGuest false in session attributes`() {
        val token = jwtService.generateToken("user123", "alice")
        val message = buildConnectMessage("Bearer $token")

        val result = interceptor.preSend(message, FakeChannel())

        assertNotNull(result)
        val accessor = StompHeaderAccessor.wrap(result)
        assertEquals(false, accessor.sessionAttributes?.get("isGuest"))
    }

    @Test
    fun `guest JWT sets isGuest true in session attributes`() {
        val token = jwtService.generateToken("guest_123", "guest_123", isGuest = true)
        val message = buildConnectMessage("Bearer $token")

        val result = interceptor.preSend(message, FakeChannel())

        assertNotNull(result)
        val accessor = StompHeaderAccessor.wrap(result)
        assertEquals(true, accessor.sessionAttributes?.get("isGuest"))
        assertEquals("guest_123", accessor.sessionAttributes?.get("userId"))
    }

    /**
     * Minimal MessageChannel implementation for testing.
     */
    private class FakeChannel : org.springframework.messaging.MessageChannel {
        override fun send(message: org.springframework.messaging.Message<*>): Boolean = true
        override fun send(message: org.springframework.messaging.Message<*>, timeout: Long): Boolean = true
    }
}
