package com.jackabee.cribbageclubserver.websocket

import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import java.util.concurrent.ConcurrentHashMap

/**
 * Tracks WebSocket session-to-player/game mappings so that
 * disconnect events can trigger automatic cleanup.
 */
@Component
class WebSocketSessionRegistry {
    private val logger = LoggerFactory.getLogger(WebSocketSessionRegistry::class.java)

    data class SessionInfo(
        val sessionId: String,
        val playerId: String,
        val playerName: String,
        val gameId: String
    )

    private val sessions = ConcurrentHashMap<String, SessionInfo>()

    fun register(sessionId: String, playerId: String, playerName: String, gameId: String) {
        val info = SessionInfo(sessionId, playerId, playerName, gameId)
        sessions[sessionId] = info
        logger.debug("Registered session {} for player {} in game {}", sessionId, playerId, gameId)
    }

    fun unregister(sessionId: String): SessionInfo? {
        val info = sessions.remove(sessionId)
        if (info != null) {
            logger.debug("Unregistered session {} for player {} in game {}", sessionId, info.playerId, info.gameId)
        }
        return info
    }

    fun getSession(sessionId: String): SessionInfo? = sessions[sessionId]

    fun getSessionsForGame(gameId: String): List<SessionInfo> =
        sessions.values.filter { it.gameId == gameId }
}
