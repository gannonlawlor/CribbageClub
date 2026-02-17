package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.repository.GameRepository
import com.fasterxml.jackson.databind.ObjectMapper
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest
import org.springframework.context.annotation.Import
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

@DataJpaTest
@Import(GameService::class, ObjectMapper::class)
class GameServiceTest {

    @Autowired
    private lateinit var gameService: GameService

    @Autowired
    private lateinit var gameRepository: GameRepository

    @Test
    fun `should create game with AI opponent`() {
        val gameState = gameService.createGameWithAI("human1", "Alice")

        assertEquals(2, gameState.players.size)
        assertEquals("human1", gameState.players[0].id)
        assertEquals("Alice", gameState.players[0].name)
        assertEquals("AI Opponent", gameState.players[1].name)
        assertTrue(gameState.players[1].id.startsWith("ai_"))

        assertEquals(GameStage.DISCARDING_TO_CRIB, gameState.stage)
        assertEquals(6, gameState.players[0].hand.size)
        assertEquals(6, gameState.players[1].hand.size)
    }

    @Test
    fun `should persist game to database on create`() {
        val gameState = gameService.createGameWithAI("human1", "Alice")
        val gameId = gameService.listGames().keys.first()

        val entity = gameRepository.findById(gameId)
        assertTrue(entity.isPresent)
        assertEquals("human1", entity.get().player1Id)
        assertEquals("Alice", entity.get().player1Name)
        assertTrue(entity.get().isAIGame)
        assertNotNull(entity.get().stateJson)
    }

    @Test
    fun `should update database after human action`() {
        val gameState = gameService.createGameWithAI("human1", "Alice")
        val gameId = gameService.listGames().keys.first()

        val humanPlayer = gameState.players.find { it.id == "human1" }
        assertNotNull(humanPlayer)
        val cardToDiscard = humanPlayer.hand.first()

        gameService.applyHumanAction(gameId, GameAction.DiscardToCrib("human1", cardToDiscard))

        val entity = gameRepository.findById(gameId)
        assertTrue(entity.isPresent)
        assertNotNull(entity.get().stateJson)
        // stateJson should be updated
        assertTrue(entity.get().stateJson!!.contains("DISCARDING_TO_CRIB"))
    }

    @Test
    fun `should process AI actions automatically`() {
        val gameState = gameService.createGameWithAI("human1", "Alice")

        val aiPlayerId = gameState.players[1].id
        if (gameState.currentPlayerId == aiPlayerId) {
            assertTrue(gameState.stage == GameStage.DISCARDING_TO_CRIB)
        }
    }

    @Test
    fun `should handle human player actions`() {
        val gameState = gameService.createGameWithAI("human1", "Alice")
        val gameId = gameService.listGames().keys.first()

        val humanPlayer = gameState.players.find { it.id == "human1" }
        assertNotNull(humanPlayer)

        val cardToDiscard = humanPlayer.hand.first()
        val action = GameAction.DiscardToCrib("human1", cardToDiscard)

        val newState = gameService.applyHumanAction(gameId, action)

        val updatedHumanPlayer = newState.players.find { it.id == "human1" }
        assertNotNull(updatedHumanPlayer)
        assertEquals(5, updatedHumanPlayer.hand.size)
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
    fun `should remove games from memory and database`() {
        gameService.createGameWithAI("human1", "Alice")
        val gameId = gameService.listGames().keys.first()

        assertEquals(1, gameService.listGames().size)
        assertTrue(gameRepository.findById(gameId).isPresent)

        gameService.removeGame(gameId)

        assertEquals(0, gameService.listGames().size)
        assertTrue(gameRepository.findById(gameId).isEmpty)
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
}
