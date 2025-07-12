package com.jackabee.cribbageclubserver.websocket

import com.jackabee.cribbageclubserver.model.game.GameState
import org.springframework.messaging.simp.SimpMessagingTemplate
import org.springframework.stereotype.Service

@Service
class GameWebSocketService(
    private val messagingTemplate: SimpMessagingTemplate
) {

    /**
     * Broadcast game state update to all subscribers of a game
     */
    fun broadcastGameStateUpdate(gameId: String, gameState: GameState) {
        val updateMessage = GameStateUpdateMessage(
            gameId = gameId,
            gameState = gameState
        )
        
        messagingTemplate.convertAndSend("/topic/game/$gameId", updateMessage)
    }

    /**
     * Send game state to a specific player
     */
    fun sendGameStateToPlayer(sessionId: String, gameId: String, gameState: GameState) {
        val updateMessage = GameStateUpdateMessage(
            gameId = gameId,
            gameState = gameState
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