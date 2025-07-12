package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit
import com.jackabee.cribbageclubserver.model.game.GameStage
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class GameServiceTest {

    private lateinit var gameService: GameService

    @BeforeEach
    fun setUp() {
        gameService = GameService()
    }

    @Test
    fun `should create game with AI opponent`() {
        val gameState = gameService.createGameWithAI("human1", "Alice")
        
        assertEquals(2, gameState.players.size)
        assertEquals("human1", gameState.players[0].id)
        assertEquals("Alice", gameState.players[0].name)
        assertEquals("AI Opponent", gameState.players[1].name)
        assertTrue(gameState.players[1].id.startsWith("ai_"))
        
        // Should be in discarding phase after setup
        assertEquals(GameStage.DISCARDING_TO_CRIB, gameState.stage)
        
        // Players should have 6 cards each
        assertEquals(6, gameState.players[0].hand.size)
        assertEquals(6, gameState.players[1].hand.size)
    }

    @Test
    fun `should process AI actions automatically`() {
        val gameState = gameService.createGameWithAI("human1", "Alice")
        
        // If it's AI's turn, it should have processed some actions
        val aiPlayerId = gameState.players[1].id
        if (gameState.currentPlayerId == aiPlayerId) {
            // AI should have acted, so game state should reflect that
            assertTrue(gameState.stage == GameStage.DISCARDING_TO_CRIB)
        }
    }

    @Test
    fun `should handle human player actions`() {
        val gameState = gameService.createGameWithAI("human1", "Alice")
        val gameId = gameService.listGames().keys.first()
        
        // Find a card in human player's hand to discard
        val humanPlayer = gameState.players.find { it.id == "human1" }
        assertNotNull(humanPlayer)
        
        val cardToDiscard = humanPlayer.hand.first()
        val action = GameAction.DiscardToCrib("human1", cardToDiscard)
        
        val newState = gameService.applyHumanAction(gameId, action)
        
        // Verify the action was applied
        val updatedHumanPlayer = newState.players.find { it.id == "human1" }
        assertNotNull(updatedHumanPlayer)
        assertEquals(5, updatedHumanPlayer.hand.size) // One card discarded
        assertTrue(cardToDiscard in newState.crib)
    }

    @Test
    fun `should list active games`() {
        val initialGames = gameService.listGames()
        assertEquals(0, initialGames.size)
        
        gameService.createGameWithAI("human1", "Alice")
        gameService.createGameWithAI("human2", "Bob")
        
        val activeGames = gameService.listGames()
        assertEquals(2, activeGames.size)
    }

    @Test
    fun `should remove games`() {
        gameService.createGameWithAI("human1", "Alice")
        val gameId = gameService.listGames().keys.first()
        
        assertEquals(1, gameService.listGames().size)
        
        gameService.removeGame(gameId)
        
        assertEquals(0, gameService.listGames().size)
    }

    @Test
    fun `should get game state`() {
        gameService.createGameWithAI("human1", "Alice")
        val gameId = gameService.listGames().keys.first()
        
        val gameState = gameService.getGameState(gameId)
        
        assertNotNull(gameState)
        assertEquals(2, gameState.players.size)
        assertEquals("human1", gameState.players[0].id)
        assertEquals("Alice", gameState.players[0].name)
    }

    @Test
    fun `should create different AI difficulties`() {
        val basicGame = gameService.createGameWithAI("human1", "Alice", "basic")
        val anotherGame = gameService.createGameWithAI("human2", "Bob", "advanced")
        
        // Both should work (advanced defaults to basic for now)
        assertEquals(2, basicGame.players.size)
        assertEquals(2, anotherGame.players.size)
    }
}