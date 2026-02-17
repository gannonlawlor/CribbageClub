package com.jackabee.cribbageclubserver.websocket

import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.player.Player
import org.junit.jupiter.api.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.eq
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify
import org.springframework.messaging.simp.SimpMessagingTemplate

class GameWebSocketServiceTest {

    private val messagingTemplate = mock<SimpMessagingTemplate>()
    private val webSocketService = GameWebSocketService(messagingTemplate)

    @Test
    fun `should broadcast game state update`() {
        // Given
        val gameId = "test-game"
        val gameState = GameState(
            gameId = gameId,
            players = listOf(
                Player("player1", "Player 1"),
                Player("player2", "Player 2")
            )
        )

        // When
        webSocketService.broadcastGameStateUpdate(gameId, gameState)

        // Then
        verify(messagingTemplate).convertAndSend(
            eq("/topic/game/$gameId"),
            any<GameStateUpdateMessage>()
        )
    }

    @Test
    fun `should broadcast player joined message`() {
        // Given
        val gameId = "test-game"
        val playerId = "player1"
        val playerName = "Player 1"

        // When
        webSocketService.broadcastPlayerJoined(gameId, playerId, playerName)

        // Then
        verify(messagingTemplate).convertAndSend(
            eq("/topic/game/$gameId/players"),
            any<PlayerJoinedMessage>()
        )
    }

    @Test
    fun `should broadcast player left message`() {
        // Given
        val gameId = "test-game"
        val playerId = "player1"

        // When
        webSocketService.broadcastPlayerLeft(gameId, playerId)

        // Then
        verify(messagingTemplate).convertAndSend(
            eq("/topic/game/$gameId/players"),
            any<PlayerLeftMessage>()
        )
    }

    @Test
    fun `should send error to player`() {
        // Given
        val sessionId = "session123"
        val gameId = "test-game"
        val error = "Test error"

        // When
        webSocketService.sendErrorToPlayer(sessionId, gameId, error)

        // Then
        verify(messagingTemplate).convertAndSendToUser(
            eq(sessionId),
            eq("/queue/errors"),
            any<GameErrorMessage>()
        )
    }
}
