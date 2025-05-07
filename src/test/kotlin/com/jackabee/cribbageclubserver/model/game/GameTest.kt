package com.jackabee.cribbageclubserver.model.game

import com.jackabee.cribbageclubserver.model.action.ActionType
import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Deck
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit
import com.jackabee.cribbageclubserver.model.player.Player
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.mockito.Mockito.mock
import org.mockito.kotlin.clearInvocations
import org.mockito.kotlin.whenever
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

        game.applyAction(GameAction.DiscardToCrib(player1.id, cardToDiscard1))
        game.applyAction(GameAction.DiscardToCrib(player1.id, cardToDiscard2))
        game.applyAction(GameAction.DiscardToCrib(player2.id, cardToDiscard3))
        val finalState = game.applyAction(GameAction.DiscardToCrib(player2.id, cardToDiscard4))

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
            game.applyAction(GameAction.DiscardToCrib(player.id, invalidCard))
        }
    }

    @Test
    fun `Game should allow cutting the deck`() {
        discardAllPlayersToCrib()
        val player = game.getCurrentState().players[0]
        val newState = game.applyAction(GameAction.CutDeck(player.id))
        assertEquals(GameStage.PEGGING, newState.stage)
        assertTrue(newState.cutCard != null)
    }

    @Test
    fun `Game should not allow invalid actions for current stage`() {
        val player = game.getCurrentState().players[0]
        assertThrows<Exception> {
            game.applyAction(GameAction.CutDeck(player.id))
        }
    }

    @Test
    fun `Cutting the deck should transition game to pegging stage`() {
        // Arrange
        val mockDeck = mock<Deck>()
        game = Game("1", players, mockDeck)
        setupGameForCutting(mockDeck)

        // Act
        game.applyAction(GameAction.CutDeck(players[0].id))

        // Assert
        val currentState = game.getCurrentState()
        assertEquals(GameStage.PEGGING, currentState.stage)
        assertEquals(players[0].id, currentState.currentPlayerId)
    }

    @Test
    fun `Cutting a Jack should award 2 points to the dealer`() {
        // Arrange
        val mockDeck = mock<Deck>()
        setupGameForCutting(mockDeck)
        whenever(mockDeck.cut()).thenReturn(Card(Rank.JACK, Suit.SPADES))

        // Act
        game.applyAction(GameAction.CutDeck(players[0].id))

        // Assert
        val currentState = game.getCurrentState()
        assertEquals(2, currentState.players[1].score) // Dealer (second player) gets 2 points
        assertEquals(Card(Rank.JACK, Suit.SPADES), currentState.cutCard)
    }

    @Test
    fun `Cutting a non-Jack should not award any points`() {
        // Arrange
        val mockDeck = mock<Deck>()
        setupGameForCutting(mockDeck)
        whenever(mockDeck.cut()).thenReturn(Card(Rank.QUEEN, Suit.HEARTS))

        // Act
        game.applyAction(GameAction.CutDeck(players[0].id))

        // Assert
        val currentState = game.getCurrentState()
        assertEquals(0, currentState.players[0].score)
        assertEquals(0, currentState.players[1].score)
        assertEquals(Card(Rank.QUEEN, Suit.HEARTS), currentState.cutCard)
    }

    private fun setupGameForCutting(mockDeck: Deck) {
        // Clear any previous interactions with the mock
        clearInvocations(mockDeck)

        // Define cards for both players (12 cards total for initial deal)
        val player1Cards = listOf(
            Card(Rank.ACE, Suit.HEARTS),
            Card(Rank.TWO, Suit.HEARTS),
            Card(Rank.THREE, Suit.HEARTS),
            Card(Rank.FOUR, Suit.HEARTS),
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.SIX, Suit.HEARTS)
        )

        val player2Cards = listOf(
            Card(Rank.SEVEN, Suit.HEARTS),
            Card(Rank.EIGHT, Suit.HEARTS),
            Card(Rank.NINE, Suit.HEARTS),
            Card(Rank.TEN, Suit.HEARTS),
            Card(Rank.JACK, Suit.HEARTS),
            Card(Rank.QUEEN, Suit.HEARTS)
        )

        // Set up draw(n) method to return the correct sequence of cards
        whenever(mockDeck.draw(6)).thenReturn(player1Cards, player2Cards)

        // Create the game with the mock deck
        game = Game("testGame", players, mockDeck)

        // Now let's discard cards to crib
        // We need to use the actual cards from players' hands
        val state = game.getCurrentState()
        val player1 = state.players[0]
        val player2 = state.players[1]

        // Each player discards two cards
        game.applyAction(GameAction.DiscardToCrib(player1.id, player1.hand[0]))
        game.applyAction(GameAction.DiscardToCrib(player1.id, player1.hand[1]))
        game.applyAction(GameAction.DiscardToCrib(player2.id, player2.hand[0]))
        game.applyAction(GameAction.DiscardToCrib(player2.id, player2.hand[1]))

        // Set up the cut card
        whenever(mockDeck.cut()).thenReturn(Card(Rank.JACK, Suit.DIAMONDS))
    }

    private fun discardAllPlayersToCrib(gameInstance: Game = game) {
        val state = gameInstance.getCurrentState()
        state.players.forEach { player ->
            gameInstance.applyAction(GameAction.DiscardToCrib(player.id, player.hand[0]))
            gameInstance.applyAction(GameAction.DiscardToCrib(player.id, player.hand[1]))
        }
    }
}