package com.jackabee.cribbageclubserver.model.game

import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit
import com.jackabee.cribbageclubserver.model.player.Player
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class GameStateFilterTest {

    private val player1 = Player(
        id = "p1",
        name = "Alice",
        hand = listOf(Card(Rank.ACE, Suit.HEARTS), Card(Rank.TWO, Suit.HEARTS)),
        score = 10
    )
    private val player2 = Player(
        id = "p2",
        name = "Bob",
        hand = listOf(Card(Rank.THREE, Suit.CLUBS), Card(Rank.FOUR, Suit.CLUBS)),
        score = 20
    )
    private val crib = listOf(Card(Rank.FIVE, Suit.DIAMONDS), Card(Rank.SIX, Suit.DIAMONDS))
    private val deck = listOf(Card(Rank.KING, Suit.SPADES), Card(Rank.QUEEN, Suit.SPADES))
    private val handsForCounting = mapOf(
        "p1" to listOf(Card(Rank.ACE, Suit.HEARTS), Card(Rank.TWO, Suit.HEARTS)),
        "p2" to listOf(Card(Rank.THREE, Suit.CLUBS), Card(Rank.FOUR, Suit.CLUBS))
    )

    private fun baseState(stage: GameStage) = GameState(
        gameId = "game_1",
        players = listOf(player1, player2),
        crib = crib,
        stage = stage,
        remainingDeck = deck,
        handsForCounting = handsForCounting
    )

    // --- Own hand visible, opponent hand blank ---

    @Test
    fun `player sees own hand but not opponent hand`() {
        val state = baseState(GameStage.PEGGING)
        val filtered = GameStateFilter.forPlayer(state, "p1")

        assertEquals(player1.hand, filtered.players[0].hand)
        assertTrue(filtered.players[1].hand.isEmpty())
    }

    @Test
    fun `player 2 sees own hand but not player 1 hand`() {
        val state = baseState(GameStage.PEGGING)
        val filtered = GameStateFilter.forPlayer(state, "p2")

        assertTrue(filtered.players[0].hand.isEmpty())
        assertEquals(player2.hand, filtered.players[1].hand)
    }

    // --- remainingDeck always empty ---

    @Test
    fun `remainingDeck is always hidden`() {
        for (stage in GameStage.entries) {
            val state = baseState(stage)
            val filtered = GameStateFilter.forPlayer(state, "p1")
            assertTrue(filtered.remainingDeck.isEmpty(), "Deck should be hidden in $stage")
        }
    }

    // --- Crib hidden before COUNTING ---

    @Test
    fun `crib is hidden during PEGGING`() {
        val filtered = GameStateFilter.forPlayer(baseState(GameStage.PEGGING), "p1")
        assertTrue(filtered.crib.isEmpty())
    }

    @Test
    fun `crib is hidden during DISCARDING_TO_CRIB`() {
        val filtered = GameStateFilter.forPlayer(baseState(GameStage.DISCARDING_TO_CRIB), "p1")
        assertTrue(filtered.crib.isEmpty())
    }

    @Test
    fun `crib is visible during COUNTING`() {
        val filtered = GameStateFilter.forPlayer(baseState(GameStage.COUNTING), "p1")
        assertEquals(crib, filtered.crib)
    }

    @Test
    fun `crib is visible during GAME_OVER`() {
        val filtered = GameStateFilter.forPlayer(baseState(GameStage.GAME_OVER), "p1")
        assertEquals(crib, filtered.crib)
    }

    // --- handsForCounting filtered by stage ---

    @Test
    fun `handsForCounting hides opponent entry during PEGGING`() {
        val filtered = GameStateFilter.forPlayer(baseState(GameStage.PEGGING), "p1")
        assertEquals(1, filtered.handsForCounting.size)
        assertTrue(filtered.handsForCounting.containsKey("p1"))
    }

    @Test
    fun `handsForCounting shows all entries during COUNTING`() {
        val filtered = GameStateFilter.forPlayer(baseState(GameStage.COUNTING), "p1")
        assertEquals(2, filtered.handsForCounting.size)
        assertTrue(filtered.handsForCounting.containsKey("p1"))
        assertTrue(filtered.handsForCounting.containsKey("p2"))
    }

    @Test
    fun `handsForCounting shows all entries during GAME_OVER`() {
        val filtered = GameStateFilter.forPlayer(baseState(GameStage.GAME_OVER), "p1")
        assertEquals(2, filtered.handsForCounting.size)
    }

    // --- Spectator view (empty playerId) ---

    @Test
    fun `spectator view hides all hands`() {
        val state = baseState(GameStage.PEGGING)
        val filtered = GameStateFilter.forPlayer(state, "")

        assertTrue(filtered.players[0].hand.isEmpty())
        assertTrue(filtered.players[1].hand.isEmpty())
        assertTrue(filtered.remainingDeck.isEmpty())
        assertTrue(filtered.crib.isEmpty())
        assertTrue(filtered.handsForCounting.isEmpty())
    }

    @Test
    fun `spectator view shows crib and counting hands during COUNTING`() {
        val state = baseState(GameStage.COUNTING)
        val filtered = GameStateFilter.forPlayer(state, "")

        assertTrue(filtered.players[0].hand.isEmpty())
        assertTrue(filtered.players[1].hand.isEmpty())
        assertEquals(crib, filtered.crib)
        assertEquals(2, filtered.handsForCounting.size)
    }

    // --- Scores pass through unfiltered ---

    @Test
    fun `scores are never filtered`() {
        val filtered = GameStateFilter.forPlayer(baseState(GameStage.PEGGING), "p1")
        assertEquals(10, filtered.players[0].score)
        assertEquals(20, filtered.players[1].score)
    }

    // --- Unknown playerId behaves like spectator ---

    @Test
    fun `unknown playerId hides all hands like spectator`() {
        val state = baseState(GameStage.PEGGING)
        val filtered = GameStateFilter.forPlayer(state, "unknown_player")

        assertTrue(filtered.players[0].hand.isEmpty())
        assertTrue(filtered.players[1].hand.isEmpty())
    }

    // --- Other fields pass through unchanged ---

    @Test
    fun `gameId and other fields are preserved`() {
        val state = baseState(GameStage.PEGGING).copy(
            cutCard = Card(Rank.JACK, Suit.HEARTS),
            currentPlayerId = "p1",
            peggingCount = 15,
            dealerIndex = 1
        )
        val filtered = GameStateFilter.forPlayer(state, "p1")

        assertEquals("game_1", filtered.gameId)
        assertEquals(Card(Rank.JACK, Suit.HEARTS), filtered.cutCard)
        assertEquals("p1", filtered.currentPlayerId)
        assertEquals(15, filtered.peggingCount)
        assertEquals(1, filtered.dealerIndex)
        assertEquals(GameStage.PEGGING, filtered.stage)
    }
}
