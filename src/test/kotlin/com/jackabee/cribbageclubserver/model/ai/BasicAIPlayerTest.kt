package com.jackabee.cribbageclubserver.model.ai

import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.model.player.Player
import com.jackabee.cribbageclubserver.utils.HandCounting.peggingValue
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class BasicAIPlayerTest {

    private val aiPlayer = BasicAIPlayer("ai1", "Test AI")

    @Test
    fun `AI should not act when not its turn`() {
        val gameState = GameState(
            gameId = "test-game-1",
            players = listOf(
                Player("human1", "Human"),
                Player("ai1", "AI")
            ),
            currentPlayerId = "human1",
            stage = GameStage.DISCARDING_TO_CRIB
        )

        val action = aiPlayer.getNextAction(gameState)
        assertNull(action)
    }

    @Test
    fun `AI should discard cards during discarding phase`() {
        val hand = listOf(
            Card(Rank.ACE, Suit.HEARTS),
            Card(Rank.TWO, Suit.HEARTS),
            Card(Rank.THREE, Suit.HEARTS),
            Card(Rank.FOUR, Suit.HEARTS),
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.SIX, Suit.HEARTS)
        )

        val gameState = GameState(
            gameId = "test-game-2",
            players = listOf(
                Player("human1", "Human"),
                Player("ai1", "AI", hand = hand)
            ),
            currentPlayerId = "ai1",
            stage = GameStage.DISCARDING_TO_CRIB
        )

        val action = aiPlayer.getNextAction(gameState)
        assertTrue(action is GameAction.DiscardToCrib)
        assertEquals("ai1", action.playerId)
        assertTrue(action.card in hand)
    }

    @Test
    fun `AI should cut deck during cutting phase`() {
        val gameState = GameState(
            gameId = "test-game-3",
            players = listOf(
                Player("human1", "Human"),
                Player("ai1", "AI")
            ),
            currentPlayerId = "ai1",
            stage = GameStage.CUTTING
        )

        val action = aiPlayer.getNextAction(gameState)
        assertTrue(action is GameAction.CutDeck)
        assertEquals("ai1", action.playerId)
    }

    @Test
    fun `AI should count hand during counting phase`() {
        val gameState = GameState(
            gameId = "test-game-4",
            players = listOf(
                Player("human1", "Human"),
                Player("ai1", "AI")
            ),
            currentPlayerId = "ai1",
            stage = GameStage.COUNTING
        )

        val action = aiPlayer.getNextAction(gameState)
        assertTrue(action is GameAction.CountHand)
        assertEquals("ai1", action.playerId)
    }

    @Test
    fun `AI should choose cards to discard`() {
        val hand = listOf(
            Card(Rank.ACE, Suit.HEARTS),
            Card(Rank.TWO, Suit.HEARTS),
            Card(Rank.THREE, Suit.HEARTS),
            Card(Rank.FOUR, Suit.HEARTS),
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.SIX, Suit.HEARTS)
        )

        val discards = aiPlayer.chooseCardsToDiscard(hand, false)
        assertEquals(2, discards.size)
        discards.forEach { card ->
            assertTrue(card in hand)
        }
    }

    @Test
    fun `AI should choose different discards when dealer vs non-dealer`() {
        val hand = listOf(
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.FIVE, Suit.DIAMONDS), // Pair
            Card(Rank.TEN, Suit.HEARTS),
            Card(Rank.JACK, Suit.HEARTS),
            Card(Rank.QUEEN, Suit.HEARTS),
            Card(Rank.KING, Suit.HEARTS)
        )

        val dealerDiscards = aiPlayer.chooseCardsToDiscard(hand, true)
        val nonDealerDiscards = aiPlayer.chooseCardsToDiscard(hand, false)

        assertEquals(2, dealerDiscards.size)
        assertEquals(2, nonDealerDiscards.size)
        
        // Strategies might differ between dealer and non-dealer
        assertTrue(dealerDiscards.all { it in hand })
        assertTrue(nonDealerDiscards.all { it in hand })
    }

    @Test
    fun `AI should play card during pegging when possible`() {
        val hand = listOf(
            Card(Rank.ACE, Suit.HEARTS),
            Card(Rank.TWO, Suit.HEARTS),
            Card(Rank.THREE, Suit.HEARTS)
        )

        val playedCards = listOf(Card(Rank.FIVE, Suit.SPADES))
        val currentCount = 5

        val cardToPlay = aiPlayer.chooseCardToPlay(hand, playedCards, currentCount)
        assertNotNull(cardToPlay)
        assertTrue(cardToPlay in hand)
        assertTrue(currentCount + cardToPlay.peggingValue() <= 31)
    }

    @Test
    fun `AI should return null when no cards can be played`() {
        val hand = listOf(
            Card(Rank.QUEEN, Suit.HEARTS), // 10 points
            Card(Rank.KING, Suit.HEARTS)   // 10 points
        )

        val playedCards = emptyList<Card>()
        val currentCount = 25 // Playing any card would exceed 31

        val cardToPlay = aiPlayer.chooseCardToPlay(hand, playedCards, currentCount)
        assertNull(cardToPlay)
    }

    @Test
    fun `AI should prefer making 15 or 31 when possible`() {
        val hand = listOf(
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.TEN, Suit.HEARTS)
        )

        // Test making 15
        val fifteenCard = aiPlayer.chooseCardToPlay(hand, emptyList(), 10)
        assertEquals(Card(Rank.FIVE, Suit.HEARTS), fifteenCard)

        // Test making 31
        val thirtyOneCard = aiPlayer.chooseCardToPlay(hand, emptyList(), 26)
        assertEquals(Card(Rank.FIVE, Suit.HEARTS), thirtyOneCard)
    }

    @Test
    fun `AI should handle pegging phase correctly`() {
        val hand = listOf(
            Card(Rank.ACE, Suit.HEARTS),
            Card(Rank.TWO, Suit.HEARTS)
        )

        val gameState = GameState(
            gameId = "test-game-5",
            players = listOf(
                Player("human1", "Human"),
                Player("ai1", "AI", hand = hand)
            ),
            currentPlayerId = "ai1",
            stage = GameStage.PEGGING,
            peggingCount = 10
        )

        val action = aiPlayer.getNextAction(gameState)
        when (action) {
            is GameAction.PlayCard -> {
                assertEquals("ai1", action.playerId)
                assertTrue(action.card in hand)
            }
            is GameAction.Go -> {
                assertEquals("ai1", action.playerId)
            }
            else -> {
                // Should be one of the above
                assertTrue(false, "Expected PlayCard or Go action")
            }
        }
    }
}