package com.jackabee.cribbageclubserver.model.game

import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Deck
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit
import com.jackabee.cribbageclubserver.model.player.Player
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.Mockito.mock
import org.mockito.kotlin.whenever
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class GameHistoryTest {

    private lateinit var game: Game
    private lateinit var players: List<Player>
    private lateinit var mockDeck: Deck

    @BeforeEach
    fun setUp() {
        players = listOf(
            Player("1", "Alice"),
            Player("2", "Bob")
        )
        mockDeck = mock<Deck>()
        setupMockDeck()
        game = Game("testGame", players, mockDeck)
    }

    private fun setupMockDeck() {
        // Define cards for both players
        val player1Cards = listOf(
            Card(Rank.ACE, Suit.HEARTS),
            Card(Rank.TWO, Suit.HEARTS),
            Card(Rank.THREE, Suit.HEARTS),
            Card(Rank.FOUR, Suit.HEARTS),
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.SIX, Suit.HEARTS)
        )

        val player2Cards = listOf(
            Card(Rank.SEVEN, Suit.SPADES),
            Card(Rank.EIGHT, Suit.SPADES),
            Card(Rank.NINE, Suit.SPADES),
            Card(Rank.TEN, Suit.SPADES),
            Card(Rank.JACK, Suit.SPADES),
            Card(Rank.QUEEN, Suit.SPADES)
        )

        // Set up draw method to return the correct sequence of cards
        whenever(mockDeck.draw(6)).thenReturn(player1Cards, player2Cards)
        whenever(mockDeck.cut()).thenReturn(Card(Rank.FIVE, Suit.DIAMONDS))
    }

    @Test
    fun `Game should track round start and cards dealt in history`() {
        val state = game.getCurrentState()
        val history = state.history

        // Should have round started and cards dealt events
        assertTrue(history.any { it is GameHistoryEvent.RoundStarted })
        assertTrue(history.any { it is GameHistoryEvent.CardsDealt })

        val roundStarted = history.first { it is GameHistoryEvent.RoundStarted } as GameHistoryEvent.RoundStarted
        assertEquals(1, roundStarted.roundNumber)
    }

    @Test
    fun `Game should track deck cutting in history`() {
        // Setup game to cutting phase
        discardAllPlayersToCrib()

        // Cut the deck - non-dealer cuts (dealer is players[0], so non-dealer is players[1])
        game.applyAction(GameAction.CutDeck(players[1].id))

        val state = game.getCurrentState()
        val history = state.history

        // Should have deck cut event
        assertTrue(history.any { it is GameHistoryEvent.DeckCut })

        val deckCut = history.first { it is GameHistoryEvent.DeckCut } as GameHistoryEvent.DeckCut
        assertEquals(Card(Rank.FIVE, Suit.DIAMONDS), deckCut.cutCard)
        assertEquals(players[1].id, deckCut.cuttingPlayerId)
    }

    @Test
    fun `Game should track Jack cut with nobs scoring in history`() {
        // Setup for Jack cut
        whenever(mockDeck.cut()).thenReturn(Card(Rank.JACK, Suit.HEARTS))

        // Setup game to cutting phase
        discardAllPlayersToCrib()

        // Cut the deck - non-dealer cuts
        game.applyAction(GameAction.CutDeck(players[1].id))
        
        val state = game.getCurrentState()
        val history = state.history

        val deckCut = history.first { it is GameHistoryEvent.DeckCut } as GameHistoryEvent.DeckCut
        assertEquals(Card(Rank.JACK, Suit.HEARTS), deckCut.cutCard)
        assertTrue(deckCut.dealerScoredNobs)
    }

    @Test
    fun `Game should track pegging card plays in history`() {
        // Setup game to pegging phase
        discardAllPlayersToCrib()
        game.applyAction(GameAction.CutDeck(players[1].id))

        // Get current state to see available cards - non-dealer plays first
        val peggingState = game.getCurrentState()
        val nonDealer = peggingState.players[1]
        val cardToPlay = nonDealer.hand.first()

        // Play a card
        game.applyAction(GameAction.PlayCard(nonDealer.id, cardToPlay))

        val state = game.getCurrentState()
        val history = state.history

        // Should have card played event
        assertTrue(history.any { it is GameHistoryEvent.CardPlayed })

        val cardPlayed = history.first { it is GameHistoryEvent.CardPlayed } as GameHistoryEvent.CardPlayed
        assertEquals(nonDealer.id, cardPlayed.playerId)
        assertEquals(cardToPlay, cardPlayed.card)
        assertTrue(cardPlayed.newCount >= 1)
    }

    @Test
    fun `Game should track go announcements in history`() {
        // Setup game to pegging phase
        discardAllPlayersToCrib()
        game.applyAction(GameAction.CutDeck(players[1].id))

        // Announce go - non-dealer plays first in pegging
        game.applyAction(GameAction.Go(players[1].id))

        val state = game.getCurrentState()
        val history = state.history

        // Should have go announced event
        assertTrue(history.any { it is GameHistoryEvent.GoAnnounced })

        val goAnnounced = history.first { it is GameHistoryEvent.GoAnnounced } as GameHistoryEvent.GoAnnounced
        assertEquals(players[1].id, goAnnounced.playerId)
        assertEquals(0, goAnnounced.pointsScored) // First go doesn't score
    }

    @Test
    fun `Game should track hand counting with score breakdown in history`() {
        // Create a mock deck with specific cards that will create a known scoring hand
        val scoringHand = listOf(
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.TEN, Suit.HEARTS),
            Card(Rank.JACK, Suit.HEARTS),
            Card(Rank.QUEEN, Suit.HEARTS) // This hand with a 5 cut card should score points
        )
        
        whenever(mockDeck.draw(6)).thenReturn(
            scoringHand + scoringHand.take(2), 
            scoringHand + scoringHand.take(2)
        )
        whenever(mockDeck.cut()).thenReturn(Card(Rank.FIVE, Suit.SPADES))
        
        val testGame = Game("testId", players, mockDeck)

        // Play through to counting phase
        discardAllPlayersToCrib(testGame)
        testGame.applyAction(GameAction.CutDeck(players[1].id))

        // Skip pegging by manually transitioning to counting
        // This is a simplified test - in a real game we'd play through pegging
        val field = testGame.javaClass.getDeclaredField("state")
        field.isAccessible = true
        val currentState = testGame.getCurrentState()
        field.set(testGame, currentState.copy(stage = GameStage.COUNTING))

        // Count hand - non-dealer counts first (players[1] is current after cutting)
        testGame.applyAction(GameAction.CountHand(players[1].id))

        val state = testGame.getCurrentState()
        val history = state.history

        // Should have hand counted event
        assertTrue(history.any { it is GameHistoryEvent.HandCounted })

        val handCounted = history.first { it is GameHistoryEvent.HandCounted } as GameHistoryEvent.HandCounted
        assertEquals(players[1].id, handCounted.playerId)
        assertTrue(handCounted.totalPoints >= 0)
        assertNotNull(handCounted.scoreBreakdown)
    }

    @Test
    fun `History tracker should work with different event types`() {
        val tracker = ListGameHistoryTracker()
        
        // Add different types of events
        tracker.addEvent(GameHistoryEvent.RoundStarted(roundNumber = 1))
        tracker.addEvent(GameHistoryEvent.CardsDealt())
        tracker.addEvent(GameHistoryEvent.DeckCut(
            cutCard = Card(Rank.KING, Suit.HEARTS),
            cuttingPlayerId = "player1"
        ))
        
        // Test getting all events
        val allEvents = tracker.getHistory()
        assertEquals(3, allEvents.size)
        
        // Test getting events of specific type
        val roundStartedEvents = tracker.getEventsOfType(GameHistoryEvent.RoundStarted::class.java)
        assertEquals(1, roundStartedEvents.size)
        assertEquals(1, roundStartedEvents[0].roundNumber)
        
        // Test getting last event of specific type
        val lastDeckCut = tracker.getLastEventOfType(GameHistoryEvent.DeckCut::class.java)
        assertNotNull(lastDeckCut)
        assertEquals(Card(Rank.KING, Suit.HEARTS), lastDeckCut.cutCard)
        
        // Test clearing history
        tracker.clear()
        assertEquals(0, tracker.getHistory().size)
    }

    @Test
    fun `Score breakdown should calculate correctly`() {
        val breakdown = GameHistoryEvent.ScoreBreakdown(
            fifteens = 4,
            pairs = 2,
            runs = 3,
            flushes = 4,
            nobs = 1
        )
        
        assertEquals(14, breakdown.totalScore)
    }

    private fun discardAllPlayersToCrib(gameInstance: Game = game) {
        val state = gameInstance.getCurrentState()
        state.players.forEach { player ->
            gameInstance.applyAction(GameAction.DiscardToCrib(player.id, player.hand[0]))
            gameInstance.applyAction(GameAction.DiscardToCrib(player.id, player.hand[1]))
        }
    }
}