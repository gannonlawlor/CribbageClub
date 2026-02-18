package com.jackabee.cribbageclubserver.websocket

import com.jackabee.cribbageclubserver.service.GameService
import org.slf4j.LoggerFactory
import org.springframework.messaging.handler.annotation.MessageMapping
import org.springframework.messaging.handler.annotation.Payload
import org.springframework.messaging.simp.SimpMessageHeaderAccessor
import org.springframework.stereotype.Controller
import org.springframework.web.bind.annotation.CrossOrigin

@Controller
@CrossOrigin
class GameWebSocketController(
    private val gameService: GameService,
    private val webSocketService: GameWebSocketService,
    private val sessionRegistry: WebSocketSessionRegistry
) {
    private val logger = LoggerFactory.getLogger(GameWebSocketController::class.java)

    /**
     * Handle game actions sent via WebSocket
     */
    @MessageMapping("/game/action")
    fun handleGameAction(@Payload message: GameActionMessage, headerAccessor: SimpMessageHeaderAccessor) {
        val playerId = headerAccessor.sessionAttributes?.get("userId") as? String
        if (playerId == null) {
            webSocketService.sendErrorToPlayer(
                headerAccessor.sessionId!!,
                message.gameId,
                "Not authenticated"
            )
            return
        }

        try {
            // Verify sender is a participant in the game
            val currentState = gameService.getGameState(message.gameId)
            val isParticipant = currentState.players.any { it.id == playerId }
            if (!isParticipant) {
                webSocketService.sendErrorToPlayer(
                    headerAccessor.sessionId!!,
                    message.gameId,
                    "You are not a participant in this game"
                )
                return
            }

            // Apply the action to the game
            val updatedGameState = gameService.applyHumanAction(message.gameId, message.action)

            // Broadcast the filtered game state to each player
            webSocketService.broadcastGameStateUpdate(message.gameId, updatedGameState)

        } catch (e: Exception) {
            webSocketService.sendErrorToPlayer(
                headerAccessor.sessionId!!,
                message.gameId,
                e.message ?: "Unknown error occurred"
            )
        }
    }

    /**
     * Handle joining a game via WebSocket.
     * Player identity comes from the authenticated session, not the message.
     */
    @MessageMapping("/game/join")
    fun handleJoinGame(@Payload message: JoinGameMessage, headerAccessor: SimpMessageHeaderAccessor) {
        val playerId = headerAccessor.sessionAttributes?.get("userId") as? String
        val playerName = headerAccessor.sessionAttributes?.get("username") as? String

        if (playerId == null || playerName == null) {
            webSocketService.sendErrorToPlayer(
                headerAccessor.sessionId!!,
                message.gameId,
                "Not authenticated"
            )
            return
        }

        try {
            // Get current game state
            val gameState = gameService.getGameState(message.gameId)

            // Register session for disconnect cleanup
            sessionRegistry.register(
                headerAccessor.sessionId!!,
                playerId,
                playerName,
                message.gameId
            )

            // Send filtered game state to the joining player
            webSocketService.sendGameStateToPlayer(
                headerAccessor.sessionId!!,
                message.gameId,
                gameState
            )

            // Notify other players about the new connection
            webSocketService.broadcastPlayerJoined(message.gameId, playerId, playerName)

        } catch (e: Exception) {
            webSocketService.sendErrorToPlayer(
                headerAccessor.sessionId!!,
                message.gameId,
                e.message ?: "Failed to join game"
            )
        }
    }

    /**
     * Handle leaving a game via WebSocket.
     * Player identity comes from the authenticated session.
     */
    @MessageMapping("/game/leave")
    fun handleLeaveGame(@Payload message: LeaveGameMessage, headerAccessor: SimpMessageHeaderAccessor) {
        try {
            val playerId = headerAccessor.sessionAttributes?.get("userId") as? String

            // Unregister session from registry
            sessionRegistry.unregister(headerAccessor.sessionId!!)

            // Notify other players about the disconnection
            if (playerId != null) {
                webSocketService.broadcastPlayerLeft(message.gameId, playerId)
            }

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

            // Send filtered game state to the requesting player
            webSocketService.sendGameStateToPlayer(
                headerAccessor.sessionId!!,
                gameId,
                gameState
            )

        } catch (e: Exception) {
            webSocketService.sendErrorToPlayer(
                headerAccessor.sessionId!!,
                gameId,
                e.message ?: "Failed to get game state"
            )
        }
    }
}