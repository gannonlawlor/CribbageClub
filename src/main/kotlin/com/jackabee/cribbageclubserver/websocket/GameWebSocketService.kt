package com.jackabee.cribbageclubserver.websocket

import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.game.GameStateFilter
import org.springframework.messaging.simp.SimpMessagingTemplate
import org.springframework.stereotype.Service

@Service
class GameWebSocketService(
    private val messagingTemplate: SimpMessagingTemplate,
    private val sessionRegistry: WebSocketSessionRegistry
) {

    /**
     * Broadcast game state update to all subscribers of a game.
     * Each connected player receives a filtered view showing only their own hand.
     * Falls back to a spectator view on the topic if no sessions are registered.
     */
    fun broadcastGameStateUpdate(gameId: String, gameState: GameState) {
        val sessions = sessionRegistry.getSessionsForGame(gameId)

        if (sessions.isNotEmpty()) {
            for (session in sessions) {
                val filtered = GameStateFilter.forPlayer(gameState, session.playerId)
                val message = GameStateUpdateMessage(gameId = gameId, gameState = filtered)
                messagingTemplate.convertAndSendToUser(
                    session.sessionId,
                    "/queue/game-state",
                    message
                )
            }
        }

        // Always send a spectator view on the topic for observers
        val spectatorView = GameStateFilter.forPlayer(gameState, "")
        val spectatorMessage = GameStateUpdateMessage(gameId = gameId, gameState = spectatorView)
        messagingTemplate.convertAndSend("/topic/game/$gameId", spectatorMessage)
    }

    /**
     * Send game state to a specific player session, filtered for that player.
     */
    fun sendGameStateToPlayer(sessionId: String, gameId: String, gameState: GameState) {
        val session = sessionRegistry.getSession(sessionId)
        val playerId = session?.playerId ?: ""
        val filtered = GameStateFilter.forPlayer(gameState, playerId)
        val updateMessage = GameStateUpdateMessage(
            gameId = gameId,
            gameState = filtered
        )

        messagingTemplate.convertAndSendToUser(
            sessionId,
            "/queue/game-state",
            updateMessage
        )
    }

    /**
     * Send error message to a specific player
     */
    fun sendErrorToPlayer(sessionId: String, gameId: String, error: String) {
        val errorMessage = GameErrorMessage(
            gameId = gameId,
            error = error
        )
        
        messagingTemplate.convertAndSendToUser(
            sessionId,
            "/queue/errors",
            errorMessage
        )
    }

    /**
     * Broadcast player joined message
     */
    fun broadcastPlayerJoined(gameId: String, playerId: String, playerName: String) {
        val joinMessage = PlayerJoinedMessage(
            gameId = gameId,
            playerId = playerId,
            playerName = playerName
        )
        
        messagingTemplate.convertAndSend("/topic/game/$gameId/players", joinMessage)
    }

    /**
     * Broadcast player left message
     */
    fun broadcastPlayerLeft(gameId: String, playerId: String) {
        val leaveMessage = PlayerLeftMessage(
            gameId = gameId,
            playerId = playerId
        )
        
        messagingTemplate.convertAndSend("/topic/game/$gameId/players", leaveMessage)
    }
}