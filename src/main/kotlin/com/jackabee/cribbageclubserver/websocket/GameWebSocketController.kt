package com.jackabee.cribbageclubserver.websocket

import com.jackabee.cribbageclubserver.service.GameService
import org.slf4j.LoggerFactory
import org.springframework.messaging.handler.annotation.MessageMapping
import org.springframework.messaging.handler.annotation.Payload
import org.springframework.messaging.simp.SimpMessageHeaderAccessor
import org.springframework.messaging.simp.SimpMessagingTemplate
import org.springframework.messaging.simp.annotation.SendToUser
import org.springframework.stereotype.Controller
import org.springframework.web.bind.annotation.CrossOrigin

@Controller
@CrossOrigin
class GameWebSocketController(
    private val gameService: GameService,
    private val messagingTemplate: SimpMessagingTemplate,
    private val sessionRegistry: WebSocketSessionRegistry
) {
    private val logger = LoggerFactory.getLogger(GameWebSocketController::class.java)

    /**
     * Handle game actions sent via WebSocket
     */
    @MessageMapping("/game/action")
    fun handleGameAction(@Payload message: GameActionMessage, headerAccessor: SimpMessageHeaderAccessor) {
        try {
            // Apply the action to the game
            val updatedGameState = gameService.applyHumanAction(message.gameId, message.action)
            
            // Broadcast the updated game state to all subscribers of this game
            val updateMessage = GameStateUpdateMessage(
                gameId = message.gameId,
                gameState = updatedGameState
            )
            
            messagingTemplate.convertAndSend("/topic/game/${message.gameId}", updateMessage)
            
        } catch (e: Exception) {
            // Send error message back to the sender
            val errorMessage = GameErrorMessage(
                gameId = message.gameId,
                error = e.message ?: "Unknown error occurred"
            )
            
            messagingTemplate.convertAndSendToUser(
                headerAccessor.sessionId!!,
                "/queue/errors",
                errorMessage
            )
        }
    }

    /**
     * Handle joining a game via WebSocket
     */
    @MessageMapping("/game/join")
    fun handleJoinGame(@Payload message: JoinGameMessage, headerAccessor: SimpMessageHeaderAccessor) {
        try {
            // Get current game state
            val gameState = gameService.getGameState(message.gameId)
            
            // Register session for disconnect cleanup
            sessionRegistry.register(
                headerAccessor.sessionId!!,
                message.playerId,
                message.playerName,
                message.gameId
            )
            
            // Send current game state to the joining player
            val updateMessage = GameStateUpdateMessage(
                gameId = message.gameId,
                gameState = gameState
            )
            
            messagingTemplate.convertAndSendToUser(
                headerAccessor.sessionId!!,
                "/queue/game-state",
                updateMessage
            )
            
            // Notify other players about the new connection
            val joinMessage = PlayerJoinedMessage(
                gameId = message.gameId,
                playerId = message.playerId,
                playerName = message.playerName
            )
            
            messagingTemplate.convertAndSend("/topic/game/${message.gameId}/players", joinMessage)
            
        } catch (e: Exception) {
            val errorMessage = GameErrorMessage(
                gameId = message.gameId,
                error = e.message ?: "Failed to join game"
            )
            
            messagingTemplate.convertAndSendToUser(
                headerAccessor.sessionId!!,
                "/queue/errors",
                errorMessage
            )
        }
    }

    /**
     * Handle leaving a game via WebSocket
     */
    @MessageMapping("/game/leave")
    fun handleLeaveGame(@Payload message: LeaveGameMessage, headerAccessor: SimpMessageHeaderAccessor) {
        try {
            // Unregister session from registry
            sessionRegistry.unregister(headerAccessor.sessionId!!)
            
            // Notify other players about the disconnection
            val leaveMessage = PlayerLeftMessage(
                gameId = message.gameId,
                playerId = message.playerId
            )
            
            messagingTemplate.convertAndSend("/topic/game/${message.gameId}/players", leaveMessage)
            
        } catch (e: Exception) {
            // Log error but don't send back to client since they're leaving
            logger.warn("Error handling leave game: {}", e.message)
        }
    }

    /**
     * Handle getting game state via WebSocket
     */
    @MessageMapping("/game/state")
    fun handleGetGameState(@Payload gameId: String, headerAccessor: SimpMessageHeaderAccessor) {
        try {
            val gameState = gameService.getGameState(gameId)
            
            val updateMessage = GameStateUpdateMessage(
                gameId = gameId,
                gameState = gameState
            )
            
            messagingTemplate.convertAndSendToUser(
                headerAccessor.sessionId!!,
                "/queue/game-state",
                updateMessage
            )
            
        } catch (e: Exception) {
            val errorMessage = GameErrorMessage(
                gameId = gameId,
                error = e.message ?: "Failed to get game state"
            )
            
            messagingTemplate.convertAndSendToUser(
                headerAccessor.sessionId!!,
                "/queue/errors",
                errorMessage
            )
        }
    }
}