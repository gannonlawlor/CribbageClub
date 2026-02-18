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

    // Connection-level tracking for online status (independent of game sessions)
    private val connectedUsers = ConcurrentHashMap<String, String>() // sessionId → playerId
    private val userSessions = ConcurrentHashMap<String, MutableSet<String>>() // playerId → sessionIds

    fun registerConnection(sessionId: String, playerId: String) {
        connectedUsers[sessionId] = playerId
        userSessions.computeIfAbsent(playerId) { ConcurrentHashMap.newKeySet() }.add(sessionId)
        logger.debug("Registered connection {} for user {}", sessionId, playerId)
    }

    fun unregisterConnection(sessionId: String) {
        val playerId = connectedUsers.remove(sessionId) ?: return
        userSessions[playerId]?.let { sessionSet ->
            sessionSet.remove(sessionId)
            if (sessionSet.isEmpty()) {
                userSessions.remove(playerId)
            }
        }
        logger.debug("Unregistered connection {} for user {}", sessionId, playerId)
    }

    fun isUserOnline(userId: String): Boolean =
        userSessions[userId]?.isNotEmpty() == true

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
