package com.jackabee.cribbageclubserver.websocket

import org.slf4j.LoggerFactory
import org.springframework.context.event.EventListener
import org.springframework.messaging.simp.stomp.StompHeaderAccessor
import org.springframework.stereotype.Component
import org.springframework.web.socket.messaging.SessionConnectEvent
import org.springframework.web.socket.messaging.SessionDisconnectEvent

@Component
class WebSocketEventHandler(
    private val sessionRegistry: WebSocketSessionRegistry,
    private val webSocketService: GameWebSocketService
) {
    private val logger = LoggerFactory.getLogger(WebSocketEventHandler::class.java)

    @EventListener
    fun handleConnect(event: SessionConnectEvent) {
        val accessor = StompHeaderAccessor.wrap(event.message)
        val sessionId = accessor.sessionId ?: return
        val userId = accessor.sessionAttributes?.get("userId") as? String

        logger.info("WebSocket connection established: {}", sessionId)

        if (userId != null) {
            sessionRegistry.registerConnection(sessionId, userId)
        }
    }

    @EventListener
    fun handleDisconnect(event: SessionDisconnectEvent) {
        val sessionId = event.sessionId
        logger.info("WebSocket connection closed: {}", sessionId)

        // Unregister connection-level tracking
        sessionRegistry.unregisterConnection(sessionId)

        // Unregister game session tracking
        val info = sessionRegistry.unregister(sessionId) ?: return

        logger.info("Player {} disconnected from game {}", info.playerId, info.gameId)
        webSocketService.broadcastPlayerLeft(info.gameId, info.playerId)
    }
}
