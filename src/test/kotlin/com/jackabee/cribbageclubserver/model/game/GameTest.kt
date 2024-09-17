package com.jackabee.cribbageclubserver.model.game

import com.jackabee.cribbageclubserver.model.action.ActionType
import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit
import com.jackabee.cribbageclubserver.model.player.Player
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class GameTest {

    private lateinit var game: Game
    private lateinit var players: List<Player>

    @BeforeEach
    fun setUp() {
        players = listOf(
            Player("1", "Alice"),
            Player("2", "Bob")
        )
        game = Game("testGame", players)
    }

    @Test
    fun `Game should initialize with correct number of players`() {
        assertEquals(2, game.getCurrentState().players.size)
        assertThrows<IllegalArgumentException> { Game("invalidGame", listOf(Player("1", "Alice"))) }
        assertThrows<IllegalArgumentException> { Game("invalidGame", List(5) { Player(it.toString(), "Player$it") }) }
    }

    @Test
    fun `Game should deal correct number of cards to players`() {
        val state = game.getCurrentState()
        assertEquals(6, state.players[0].hand.size)
        assertEquals(6, state.players[1].hand.size)
    }

    @Test
    fun `Game should transition to discarding stage after dealing`() {
        assertEquals(GameStage.DISCARDING_TO_CRIB, game.getCurrentState().stage)
    }

    @Test
    fun `Game should allow players to discard to crib`() {
        val initialState = game.getCurrentState()
        val player1 = initialState.players[0]
        val player2 = initialState.players[1]
        val cardToDiscard1 = player1.hand[0]
        val cardToDiscard2 = player1.hand[1]
        val cardToDiscard3 = player2.hand[0]
        val cardToDiscard4 = player2.hand[1]

        game.applyAction(GameAction(player1.id, ActionType.DISCARD_TO_CRIB, cardToDiscard1))
        game.applyAction(GameAction(player1.id, ActionType.DISCARD_TO_CRIB, cardToDiscard2))
        game.applyAction(GameAction(player2.id, ActionType.DISCARD_TO_CRIB, cardToDiscard3))
        val finalState = game.applyAction(GameAction(player2.id, ActionType.DISCARD_TO_CRIB, cardToDiscard4))

        assertEquals(4, finalState.crib.size)
        assertEquals(4, finalState.players[0].hand.size)
        assertEquals(4, finalState.players[1].hand.size)
        assertTrue(cardToDiscard1 in finalState.crib)
        assertTrue(cardToDiscard2 in finalState.crib)
        assertTrue(cardToDiscard3 in finalState.crib)
        assertTrue(cardToDiscard4 in finalState.crib)
    }

    @Test
    fun `Game should transition to cutting stage after all players have discarded`() {
        discardAllPlayersToCrib()
        assertEquals(GameStage.CUTTING, game.getCurrentState().stage)
    }

    @Test
    fun `Game should not allow discarding cards not in hand`() {
        val player = game.getCurrentState().players[0]
        val invalidCard = Card(Rank.ACE, Suit.SPADES) // Assuming this card is not in the player's hand
        assertThrows<IllegalArgumentException> {
            game.applyAction(GameAction(player.id, ActionType.DISCARD_TO_CRIB, invalidCard))
        }
    }

    @Test
    fun `Game should allow cutting the deck`() {
        discardAllPlayersToCrib()
        val player = game.getCurrentState().players[0]
        val newState = game.applyAction(GameAction(player.id, ActionType.CUT_DECK))
        assertEquals(GameStage.PEGGING, newState.stage)
        assertTrue(newState.cutCard != null)
    }

    @Test
    fun `Game should not allow invalid actions for current stage`() {
        val player = game.getCurrentState().players[0]
        assertThrows<Exception> {
            game.applyAction(GameAction(player.id, ActionType.CUT_DECK))
        }
    }

    private fun discardAllPlayersToCrib(gameInstance: Game = game) {
        val state = gameInstance.getCurrentState()
        state.players.forEach { player ->
            gameInstance.applyAction(GameAction(player.id, ActionType.DISCARD_TO_CRIB, player.hand[0]))
            gameInstance.applyAction(GameAction(player.id, ActionType.DISCARD_TO_CRIB, player.hand[1]))
        }
    }
}