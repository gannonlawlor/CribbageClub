package com.jackabee.cribbageclubserver.websocket

import org.slf4j.LoggerFactory
import org.springframework.context.event.EventListener
import org.springframework.messaging.simp.SimpMessagingTemplate
import org.springframework.stereotype.Component
import org.springframework.web.socket.messaging.SessionConnectEvent
import org.springframework.web.socket.messaging.SessionDisconnectEvent

@Component
class WebSocketEventHandler(
    private val messagingTemplate: SimpMessagingTemplate
) {
    private val logger = LoggerFactory.getLogger(WebSocketEventHandler::class.java)

    @EventListener
    fun handleConnect(event: SessionConnectEvent) {
        val sessionId = event.message.headers["simpSessionId"] as String
        logger.info("WebSocket connection established: {}", sessionId)
    }

    @EventListener
    fun handleDisconnect(event: SessionDisconnectEvent) {
        val sessionId = event.sessionId
        logger.info("WebSocket connection closed: {}", sessionId)

        // Note: Session attributes are not easily accessible in disconnect event
        // Game disconnect notifications are handled in the GameWebSocketController
        // when players explicitly send leave messages
    }
}
