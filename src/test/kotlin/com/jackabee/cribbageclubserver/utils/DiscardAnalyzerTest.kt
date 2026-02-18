package com.jackabee.cribbageclubserver.utils

import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class DiscardAnalyzerTest {

    @Test
    fun `analyzeAllDiscards returns 15 options for a 6-card hand`() {
        val hand = listOf(
            Card(Rank.ACE, Suit.HEARTS),
            Card(Rank.TWO, Suit.HEARTS),
            Card(Rank.THREE, Suit.HEARTS),
            Card(Rank.FOUR, Suit.HEARTS),
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.SIX, Suit.HEARTS)
        )

        val options = DiscardAnalyzer.analyzeAllDiscards(hand, isDealer = true)
        assertEquals(15, options.size)
    }

    @Test
    fun `options are sorted by expectedCombinedValue descending`() {
        val hand = listOf(
            Card(Rank.ACE, Suit.HEARTS),
            Card(Rank.TWO, Suit.HEARTS),
            Card(Rank.THREE, Suit.HEARTS),
            Card(Rank.FOUR, Suit.HEARTS),
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.SIX, Suit.HEARTS)
        )

        val options = DiscardAnalyzer.analyzeAllDiscards(hand, isDealer = true)
        for (i in 0 until options.size - 1) {
            assertTrue(
                options[i].expectedCombinedValue >= options[i + 1].expectedCombinedValue,
                "Options should be sorted descending by EV"
            )
        }
    }

    @Test
    fun `dealer vs pone can produce different optimal discards`() {
        // Hand where crib consideration matters:
        // 5-5-6-7-8-K — dealer wants 5s in crib, pone doesn't
        val hand = listOf(
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.FIVE, Suit.DIAMONDS),
            Card(Rank.SIX, Suit.CLUBS),
            Card(Rank.SEVEN, Suit.SPADES),
            Card(Rank.EIGHT, Suit.HEARTS),
            Card(Rank.KING, Suit.CLUBS)
        )

        val dealerOptimal = DiscardAnalyzer.findOptimalDiscard(hand, isDealer = true)
        val poneOptimal = DiscardAnalyzer.findOptimalDiscard(hand, isDealer = false)

        // Both should return valid 4-card keeps and 2-card discards
        assertEquals(4, dealerOptimal.keep.size)
        assertEquals(2, dealerOptimal.discard.size)
        assertEquals(4, poneOptimal.keep.size)
        assertEquals(2, poneOptimal.discard.size)
    }

    @Test
    fun `expectedHandValue is positive for a reasonable hand`() {
        val keep = listOf(
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.FIVE, Suit.DIAMONDS),
            Card(Rank.TEN, Suit.CLUBS),
            Card(Rank.JACK, Suit.SPADES)
        )
        val knownCards = keep.toSet()

        val ev = DiscardAnalyzer.expectedHandValue(keep, knownCards)
        // 5-5-10-J should average a good score (pair of 5s, multiple 15s)
        assertTrue(ev > 6.0, "Expected hand value should be > 6 for 5-5-10-J, got $ev")
    }

    @Test
    fun `expectedCribValue is positive`() {
        val discard = listOf(
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.TEN, Suit.CLUBS)
        )
        val knownCards = setOf(
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.TEN, Suit.CLUBS),
            Card(Rank.ACE, Suit.HEARTS),
            Card(Rank.TWO, Suit.HEARTS),
            Card(Rank.THREE, Suit.HEARTS),
            Card(Rank.FOUR, Suit.HEARTS)
        )

        val ev = DiscardAnalyzer.expectedCribValue(discard, knownCards)
        assertTrue(ev > 0.0, "Expected crib value should be positive for 5-10 discard, got $ev")
    }

    @Test
    fun `each option keep plus discard equals original hand`() {
        val hand = listOf(
            Card(Rank.ACE, Suit.HEARTS),
            Card(Rank.THREE, Suit.DIAMONDS),
            Card(Rank.FIVE, Suit.CLUBS),
            Card(Rank.SEVEN, Suit.SPADES),
            Card(Rank.NINE, Suit.HEARTS),
            Card(Rank.KING, Suit.CLUBS)
        )

        val options = DiscardAnalyzer.analyzeAllDiscards(hand, isDealer = false)
        val handSet = hand.toSet()

        for (option in options) {
            val reconstituted = (option.keep + option.discard).toSet()
            assertEquals(handSet, reconstituted, "Keep + discard should equal the original hand")
        }
    }

    @Test
    fun `combinations generates correct count`() {
        val list = listOf(1, 2, 3, 4, 5, 6)
        assertEquals(15, DiscardAnalyzer.combinations(list, 4).size)
        assertEquals(20, DiscardAnalyzer.combinations(list, 3).size)
        assertEquals(6, DiscardAnalyzer.combinations(list, 5).size)
        assertEquals(1, DiscardAnalyzer.combinations(list, 6).size)
    }
}
