package com.jackabee.cribbageclubserver.model.card

import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

class DeckTest {

    private lateinit var deck: Deck

    @BeforeEach
    fun setUp() {
        deck = Deck()
    }

    @Test
    fun `Deck should have 52 cards when created`() {
        val cards = List(52) { deck.draw() }
        assertThrows<IndexOutOfBoundsException> { deck.draw() }
        assertEquals(52, cards.size)
    }

    @Test
    fun `Deck should have all unique cards`() {
        val cards = List(52) { deck.draw() }
        assertEquals(52, cards.toSet().size)
    }

    @Test
    fun `Deck should have correct number of each suit and rank`() {
        val cards = List(52) { deck.draw() }
        Suit.entries.forEach { suit ->
            assertEquals(13, cards.count { it.suit == suit })
        }
        Rank.entries.forEach { rank ->
            assertEquals(4, cards.count { it.rank == rank })
        }
    }

    @Test
    fun `draw should return correct number of cards`() {
        val drawnCards = deck.draw(5)
        assertEquals(5, drawnCards.size)
        assertEquals(47, List(47) { deck.draw() }.size)
        assertThrows<IndexOutOfBoundsException> { deck.draw() }
    }

    @Test
    fun `cut should return a card from the middle of the deck`() {
        val cutCard = deck.cut()
        val remainingCards = List(52) { deck.draw() }
        assertTrue(cutCard in remainingCards)
        val cutIndex = remainingCards.indexOf(cutCard)
        assertTrue(cutIndex in 20..32) // Allowing some flexibility due to shuffling
    }

    @Test
    fun `shuffle should reorder cards`() {
        val originalOrder = List(52) { deck.draw() }
        deck = Deck() // Reset deck
        deck.shuffle()
        val newOrder = List(52) { deck.draw() }
        assertFalse(originalOrder == newOrder)
    }

    @Test
    fun `multiple shuffles should result in different orders`() {
        val orders = mutableListOf<List<Card>>()
        repeat(3) {
            deck = Deck()
            deck.shuffle()
            orders.add(List(52) { deck.draw() })
        }
        assertNotEquals(orders[0], orders[1])
        assertNotEquals(orders[1], orders[2])
        assertNotEquals(orders[0], orders[2])
    }

}