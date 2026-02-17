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

class MediumAIPlayerTest {

    private val aiPlayer = MediumAIPlayer("ai1", "Test AI Medium")

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
    fun `should keep high-scoring combinations`() {
        // Hand with a clear best keep: 5-5-10-J (lots of 15s and a pair)
        val hand = listOf(
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.FIVE, Suit.DIAMONDS),
            Card(Rank.TEN, Suit.HEARTS),
            Card(Rank.JACK, Suit.SPADES),
            Card(Rank.TWO, Suit.CLUBS),
            Card(Rank.THREE, Suit.CLUBS)
        )
        val discards = aiPlayer.chooseCardsToDiscard(hand, false)
        assertEquals(2, discards.size)

        val kept = hand - discards.toSet()
        assertEquals(4, kept.size)

        // The AI should keep the 5-5-10-J combination (high scoring)
        // which means discarding 2 and 3
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
    fun `should cut deck during cutting phase`() {
        val gameState = GameState(
            gameId = "test",
            players = listOf(Player("human1", "Human"), Player("ai1", "AI")),
            currentPlayerId = "ai1",
            stage = GameStage.CUTTING
        )
        val action = aiPlayer.getNextAction(gameState)
        assertTrue(action is GameAction.CutDeck)
    }

    @Test
    fun `should play card during pegging`() {
        val hand = listOf(
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.TEN, Suit.HEARTS)
        )
        val gameState = GameState(
            gameId = "test",
            players = listOf(Player("human1", "Human"), Player("ai1", "AI", hand = hand)),
            currentPlayerId = "ai1",
            stage = GameStage.PEGGING,
            peggingCount = 10
        )
        val action = aiPlayer.getNextAction(gameState)
        assertTrue(action is GameAction.PlayCard)
        assertTrue(action.card in hand)
    }

    @Test
    fun `should prefer making 15 during pegging`() {
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
    fun `should count hand during counting phase`() {
        val gameState = GameState(
            gameId = "test",
            players = listOf(Player("human1", "Human"), Player("ai1", "AI")),
            currentPlayerId = "ai1",
            stage = GameStage.COUNTING
        )
        assertTrue(aiPlayer.getNextAction(gameState) is GameAction.CountHand)
    }
}
