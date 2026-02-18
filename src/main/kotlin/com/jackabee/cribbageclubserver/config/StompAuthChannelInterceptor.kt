package com.jackabee.cribbageclubserver.config

import com.jackabee.cribbageclubserver.service.JwtService
import org.slf4j.LoggerFactory
import org.springframework.messaging.Message
import org.springframework.messaging.MessageChannel
import org.springframework.messaging.simp.stomp.StompCommand
import org.springframework.messaging.simp.stomp.StompHeaderAccessor
import org.springframework.messaging.support.ChannelInterceptor
import org.springframework.messaging.support.MessageHeaderAccessor
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.stereotype.Component

/**
 * Intercepts STOMP CONNECT frames to validate the JWT token.
 * On successful validation, stores userId and username in the session
 * attributes so downstream message handlers can trust the identity.
 */
@Component
class StompAuthChannelInterceptor(
    private val jwtService: JwtService
) : ChannelInterceptor {

    private val logger = LoggerFactory.getLogger(StompAuthChannelInterceptor::class.java)

    override fun preSend(message: Message<*>, channel: MessageChannel): Message<*>? {
        val accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor::class.java)
            ?: return message

        if (accessor.command != StompCommand.CONNECT) {
            return message
        }

        val authHeader = accessor.getFirstNativeHeader("Authorization")
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            logger.warn("WebSocket CONNECT rejected: missing or malformed Authorization header")
            throw IllegalArgumentException("Missing or invalid Authorization header")
        }

        val token = authHeader.substring(7)
        if (!jwtService.isTokenValid(token)) {
            logger.warn("WebSocket CONNECT rejected: invalid JWT token")
            throw IllegalArgumentException("Invalid or expired JWT token")
        }

        val userId = jwtService.getUserIdFromToken(token)
        val username = jwtService.getUsernameFromToken(token)
        if (userId == null || username == null) {
            logger.warn("WebSocket CONNECT rejected: could not extract identity from token")
            throw IllegalArgumentException("Invalid JWT token claims")
        }

        // Store identity in session attributes for downstream handlers
        val sessionAttributes = accessor.sessionAttributes ?: mutableMapOf()
        sessionAttributes["userId"] = userId
        sessionAttributes["username"] = username
        accessor.sessionAttributes = sessionAttributes

        // Set the authenticated user principal on the message
        accessor.user = UsernamePasswordAuthenticationToken(userId, null, emptyList())

        logger.debug("WebSocket CONNECT authenticated for user {} ({})", username, userId)
        return message
    }
}
