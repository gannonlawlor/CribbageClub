package com.jackabee.cribbageclubserver.model.game

import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit
import com.jackabee.cribbageclubserver.model.player.Player
import com.jackabee.cribbageclubserver.utils.HandCounting
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class HandScoringTest {

    @Test
    fun `Test hand scoring with 15s`() {
        // Create a hand with 15s: 5 + 10 = 15
        val hand = listOf(
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.TEN, Suit.HEARTS),
            Card(Rank.TWO, Suit.DIAMONDS),
            Card(Rank.THREE, Suit.HEARTS)
        )
        val cutCard = Card(Rank.JACK, Suit.HEARTS)
        
        val score = HandCounting.calculateHandScore(hand, cutCard, false)
        
        // Should score 2 points for one 15 (5 + 10)
        assertEquals(8, score, "Expected at 8 points for 4 15s, got $score")
    }

    @Test
    fun `Test hand scoring with multiple pairs`() {
        val hand = listOf(
            Card(Rank.ACE, Suit.HEARTS),
            Card(Rank.ACE, Suit.DIAMONDS),
            Card(Rank.FIVE, Suit.CLUBS),
            Card(Rank.SEVEN, Suit.HEARTS)
        )
        val cutCard = Card(Rank.FIVE, Suit.SPADES) // Fourth 5
        
        val score = HandCounting.calculateHandScore(hand, cutCard, false)
        
        assertEquals(4, score, "Expected at least 4 points for pairs, got $score")
    }

    @Test
    fun `Test hand scoring with runs`() {
        val hand = listOf(
            Card(Rank.ACE, Suit.HEARTS),
            Card(Rank.TWO, Suit.HEARTS),
            Card(Rank.THREE, Suit.HEARTS),
            Card(Rank.FOUR, Suit.HEARTS)
        )
        val cutCard = Card(Rank.JACK, Suit.HEARTS)
        
        val score = HandCounting.calculateHandScore(hand, cutCard, false)
        
        assertEquals(13, score, "Expected at least 13 points (5 -> Flush, 4 -> Run, 2 -> 15s), got $score")
    }

    @Test
    fun `Test hand scoring with nobs`() {
        val hand = listOf(
            Card(Rank.JACK, Suit.HEARTS), // Jack of same suit as cut card
            Card(Rank.TWO, Suit.DIAMONDS),
            Card(Rank.THREE, Suit.DIAMONDS),
            Card(Rank.FOUR, Suit.DIAMONDS)
        )
        val cutCard = Card(Rank.FIVE, Suit.HEARTS) // Same suit as Jack in hand
        
        val score = HandCounting.calculateHandScore(hand, cutCard, false)
        
        assertEquals(9, score, "Expected 9 points (4 -> Run, 2 -> 15s, 1 -> Nob), got $score")
    }

    @Test
    fun `Test complex hand scoring debug`() {
        // Famous "29 hand" - highest possible score
        val hand = listOf(
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.FIVE, Suit.DIAMONDS),
            Card(Rank.FIVE, Suit.CLUBS),
            Card(Rank.JACK, Suit.HEARTS)
        )
        val cutCard = Card(Rank.FIVE, Suit.HEARTS) // Fourth 5
        
        val score = HandCounting.calculateHandScore(hand, cutCard, false)
        
        // Debug: Print the actual score for analysis
        println("Actual score: $score")
        
        // Should score 29 points total, but let's be less strict for now
        assertEquals(29, score, "Expected 29 points, got $score")
    }
}