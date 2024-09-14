package com.jackabee.cribbageclubserver.model.card

class Deck {

    private val cards: MutableList<Card> = createShuffledDeck()

    fun draw(): Card = cards.removeAt(0)

    fun shuffle() {
        cards.shuffle()
    }

    private fun createShuffledDeck(): MutableList<Card> {
        val deck = mutableListOf<Card>()
        for (suit in Suit.entries) {
            for (rank in Rank.entries) {
                deck.add(Card(rank, suit))
            }
        }
        deck.shuffle()
        return deck
    }
}