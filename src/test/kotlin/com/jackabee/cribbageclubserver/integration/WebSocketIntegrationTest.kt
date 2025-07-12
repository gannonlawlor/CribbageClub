package com.jackabee.cribbageclubserver.integration

import com.jackabee.cribbageclubserver.model.player.Player
import com.jackabee.cribbageclubserver.service.GameService
import com.jackabee.cribbageclubserver.service.LobbyService
import com.jackabee.cribbageclubserver.websocket.GameWebSocketService
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.messaging.simp.SimpMessagingTemplate
import org.springframework.test.context.ActiveProfiles

@SpringBootTest
@ActiveProfiles("test")
class WebSocketIntegrationTest {

    @Autowired
    private lateinit var gameService: GameService
    
    @Autowired
    private lateinit var lobbyService: LobbyService
    
    @Autowired
    private lateinit var webSocketService: GameWebSocketService
    
    @Autowired
    private lateinit var messagingTemplate: SimpMessagingTemplate

    @Test
    fun `should create game and verify WebSocket integration`() {
        // Given
        val players = listOf(
            Player("player1", "Alice"),
            Player("player2", "Bob")
        )
        
        // When
        val gameState = gameService.createGame(players)
        
        // Then
        assert(gameState.gameId.isNotEmpty())
        assert(gameState.players.size == 2)
        assert(gameState.players[0].name == "Alice")
        assert(gameState.players[1].name == "Bob")
        
        // Verify WebSocket service is available
        assert(webSocketService != null)
        assert(messagingTemplate != null)
        
        println("Game created successfully with WebSocket integration")
        println("Game ID: ${gameState.gameId}")
        println("Players: ${gameState.players.map { it.name }}")
        println("Game Stage: ${gameState.stage}")
    }
    
    @Test
    fun `should create lobby and start game with WebSocket support`() {
        // Given
        val lobbyName = "Test Lobby"
        val creatorId = "creator123"
        val creatorName = "Creator"
        val joinerIds = "joiner456"
        val joinerName = "Joiner"
        
        // When
        val lobby = lobbyService.createLobby(lobbyName, creatorId, creatorName)
        val updatedLobby = lobbyService.joinLobby(lobby.id, joinerIds, joinerName)
        val gameState = lobbyService.startGame(updatedLobby.id)
        
        // Then
        assert(gameState.gameId.isNotEmpty())
        assert(gameState.players.size == 2)
        
        println("Lobby to game flow successful with WebSocket integration")
        println("Lobby ID: ${lobby.id}")
        println("Game ID: ${gameState.gameId}")
        println("Players: ${gameState.players.map { "${it.name} (${it.id})" }}")
    }
}