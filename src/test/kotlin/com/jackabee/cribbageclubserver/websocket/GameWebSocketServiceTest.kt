package com.jackabee.cribbageclubserver.websocket

import com.jackabee.cribbageclubserver.bridge.CribbageEngineLib
import com.jackabee.cribbageclubserver.bridge.RustEngineAdapter
import com.jackabee.cribbageclubserver.model.player.Player
import com.jackabee.cribbageclubserver.service.GameService
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.eq
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify
import org.springframework.messaging.simp.SimpMessagingTemplate

class GameWebSocketServiceTest {

    companion object {
        private lateinit var lib: CribbageEngineLib

        @JvmStatic
        @BeforeAll
        fun loadNativeLib() {
            lib = CribbageEngineLib.load()
        }
    }

    private val messagingTemplate = mock<SimpMessagingTemplate>()
    private val sessionRegistry = WebSocketSessionRegistry()
    private val webSocketService = GameWebSocketService(messagingTemplate, sessionRegistry)

    @Test
    fun `should broadcast game state update`() {
        // Given
        val gameId = "test-game"
        val players = listOf(
            Player("player1", "Player 1"),
            Player("player2", "Player 2")
        )
        val objectMapper = jacksonObjectMapper()
        val adapter = RustEngineAdapter(lib, objectMapper)
        val gameService = GameService(objectMapper = objectMapper, rustEngineAdapter = adapter)
        val gameState = gameService.createGame(players)

        // When
        webSocketService.broadcastGameStateUpdate(gameId, gameState)

        // Then
        verify(messagingTemplate).convertAndSend(
            eq("/topic/game/$gameId"),
            any<GameStateUpdateMessage>()
        )
    }

    @Test
    fun `tags player queue frames PLAYER and topic frames SPECTATOR`() {
        val players = listOf(
            Player("player1", "Player 1"),
            Player("player2", "Player 2")
        )
        val objectMapper = jacksonObjectMapper()
        val adapter = RustEngineAdapter(lib, objectMapper)
        val gameService = GameService(objectMapper = objectMapper, rustEngineAdapter = adapter)
        val gameState = gameService.createGame(players)
        val gameId = gameState.gameId
        sessionRegistry.register("session1", "player1", "Player 1", gameId)
        sessionRegistry.register("session2", "player2", "Player 2", gameId)

        webSocketService.broadcastGameStateUpdate(gameId, gameState)

        // Each participant's queue frame keeps their own hand and is tagged PLAYER.
        for ((sessionId, playerId) in listOf("session1" to "player1", "session2" to "player2")) {
            val captor = org.mockito.kotlin.argumentCaptor<GameStateUpdateMessage>()
            verify(messagingTemplate).convertAndSendToUser(
                eq(sessionId), eq("/queue/game-state"), captor.capture()
            )
            val frame = captor.firstValue
            kotlin.test.assertEquals("PLAYER", frame.view)
            kotlin.test.assertTrue(
                frame.gameState.players.first { it.id == playerId }.hand.isNotEmpty()
            )
        }

        // The topic frame hides every hand and is tagged SPECTATOR — clients that
        // are participants must skip it or it wipes their own hand from the UI.
        val topicCaptor = org.mockito.kotlin.argumentCaptor<Any>()
        verify(messagingTemplate).convertAndSend(eq("/topic/game/$gameId"), topicCaptor.capture())
        val spectatorFrame = topicCaptor.firstValue as GameStateUpdateMessage
        kotlin.test.assertEquals("SPECTATOR", spectatorFrame.view)
        kotlin.test.assertTrue(spectatorFrame.gameState.players.all { it.hand.isEmpty() })
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
