package com.jackabee.cribbageclubserver.websocket

import org.springframework.context.event.EventListener
import org.springframework.messaging.simp.SimpMessagingTemplate
import org.springframework.stereotype.Component
import org.springframework.web.socket.messaging.SessionConnectEvent
import org.springframework.web.socket.messaging.SessionDisconnectEvent

@Component
class WebSocketEventHandler(
    private val messagingTemplate: SimpMessagingTemplate
) {

    @EventListener
    fun handleConnect(event: SessionConnectEvent) {
        // Handle WebSocket connection established
        val sessionId = event.message.headers["simpSessionId"] as String
        println("WebSocket connection established: $sessionId")
    }

    @EventListener
    fun handleDisconnect(event: SessionDisconnectEvent) {
        // Handle WebSocket disconnection
        val sessionId = event.sessionId
        println("WebSocket connection closed: $sessionId")
        
        // Note: Session attributes are not easily accessible in disconnect event
        // Game disconnect notifications are handled in the GameWebSocketController
        // when players explicitly send leave messages
    }
}