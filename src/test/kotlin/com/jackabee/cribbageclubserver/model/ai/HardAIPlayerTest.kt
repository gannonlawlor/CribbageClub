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

class HardAIPlayerTest {

    private val aiPlayer = HardAIPlayer("ai1", "Test AI Hard")

    @Test
    fun `should not act when not its turn`() {
        val gameState = GameState(
            gameId = "test",
            players = listOf(Player("human1", "Human"), Player("ai1", "AI")),
            currentPlayerId = "human1",
            stage = GameStage.DISCARDING_TO_CRIB
        )
        assertNull(aiPlayer.getNextAction(gameState))
    }

    @Test
    fun `should discard exactly 2 cards`() {
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
        assertTrue(discards.all { it in hand })
    }

    @Test
    fun `should consider crib impact when dealer`() {
        // As dealer, hard AI should favor discarding cards that help the crib
        val hand = listOf(
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.FIVE, Suit.DIAMONDS),
            Card(Rank.TEN, Suit.HEARTS),
            Card(Rank.JACK, Suit.SPADES),
            Card(Rank.TWO, Suit.CLUBS),
            Card(Rank.SEVEN, Suit.CLUBS)
        )
        val dealerDiscards = aiPlayer.chooseCardsToDiscard(hand, true)
        val nonDealerDiscards = aiPlayer.chooseCardsToDiscard(hand, false)

        assertEquals(2, dealerDiscards.size)
        assertEquals(2, nonDealerDiscards.size)

        // Results may differ between dealer and non-dealer due to crib consideration
        // Both should be valid subsets of hand
        assertTrue(dealerDiscards.all { it in hand })
        assertTrue(nonDealerDiscards.all { it in hand })
    }

    @Test
    fun `should keep high-scoring hands`() {
        // 5-5-10-J is a very strong keep
        val hand = listOf(
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.FIVE, Suit.DIAMONDS),
            Card(Rank.TEN, Suit.HEARTS),
            Card(Rank.JACK, Suit.SPADES),
            Card(Rank.TWO, Suit.CLUBS),
            Card(Rank.THREE, Suit.CLUBS)
        )
        val discards = aiPlayer.chooseCardsToDiscard(hand, false)
        val kept = hand - discards.toSet()

        // Should keep the pair of 5s
        assertTrue(kept.contains(Card(Rank.FIVE, Suit.HEARTS)))
        assertTrue(kept.contains(Card(Rank.FIVE, Suit.DIAMONDS)))
    }

    @Test
    fun `should discard during discarding phase`() {
        val hand = listOf(
            Card(Rank.ACE, Suit.HEARTS),
            Card(Rank.TWO, Suit.HEARTS),
            Card(Rank.THREE, Suit.HEARTS),
            Card(Rank.FOUR, Suit.HEARTS),
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.SIX, Suit.HEARTS)
        )
        val gameState = GameState(
            gameId = "test",
            players = listOf(Player("human1", "Human"), Player("ai1", "AI", hand = hand)),
            currentPlayerId = "ai1",
            stage = GameStage.DISCARDING_TO_CRIB
        )
        val action = aiPlayer.getNextAction(gameState)
        assertTrue(action is GameAction.DiscardToCrib)
        assertTrue(action.card in hand)
    }

    @Test
    fun `should prefer 31 during pegging`() {
        val hand = listOf(
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.SIX, Suit.HEARTS)
        )
        val card = aiPlayer.chooseCardToPlay(hand, emptyList(), 26)
        assertEquals(Card(Rank.FIVE, Suit.HEARTS), card)
    }

    @Test
    fun `should prefer 15 during pegging`() {
        val hand = listOf(
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.THREE, Suit.HEARTS)
        )
        val card = aiPlayer.chooseCardToPlay(hand, emptyList(), 10)
        assertEquals(Card(Rank.FIVE, Suit.HEARTS), card)
    }

    @Test
    fun `should announce go when no playable cards`() {
        val hand = listOf(Card(Rank.KING, Suit.HEARTS))
        val gameState = GameState(
            gameId = "test",
            players = listOf(Player("human1", "Human"), Player("ai1", "AI", hand = hand)),
            currentPlayerId = "ai1",
            stage = GameStage.PEGGING,
            peggingCount = 25
        )
        val action = aiPlayer.getNextAction(gameState)
        assertTrue(action is GameAction.Go)
    }

    @Test
    fun `should cut deck during cutting phase`() {
        val gameState = GameState(
            gameId = "test",
            players = listOf(Player("human1", "Human"), Player("ai1", "AI")),
            currentPlayerId = "ai1",
            stage = GameStage.CUTTING
        )
        assertTrue(aiPlayer.getNextAction(gameState) is GameAction.CutDeck)
    }

    @Test
    fun `should count hand during counting phase`() {
        val gameState = GameState(
            gameId = "test",
            players = listOf(Player("human1", "Human"), Player("ai1", "AI")),
            currentPlayerId = "ai1",
            stage = GameStage.COUNTING
        )
        assertTrue(aiPlayer.getNextAction(gameState) is GameAction.CountHand)
    }

    @Test
    fun `should play valid card during pegging`() {
        val hand = listOf(
            Card(Rank.ACE, Suit.HEARTS),
            Card(Rank.TWO, Suit.HEARTS),
            Card(Rank.TEN, Suit.HEARTS)
        )
        val card = aiPlayer.chooseCardToPlay(hand, emptyList(), 0)
        assertNotNull(card)
        assertTrue(card in hand)
    }
}
