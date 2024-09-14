package com.jackabee.cribbageclubserver.model.card

class Deck {
    private val cards: MutableList<Card> = createShuffledDeck()

    /**
     * Draws the top card from the deck.
     *
     * @return The drawn card.
     */
    fun draw(): Card = cards.removeAt(0)

    /**
     * Draws a specified number of cards from the deck.
     *
     * @param n The number of cards to draw.
     * @return A list of the drawn cards.
     */
    fun draw(n: Int): List<Card> = List(n) { draw() }

    /**
     * Returns the middle card of the deck, while removing it from the deck.
     * The middle card is defined as the card at the index that is half of
     * the size of the deck.
     *
     * @return The middle card of the deck.
     */
    fun cut(): Card = cards[cards.size / 2]

    /**
     * Shuffles the deck in-place, so that the order of the cards
     * is randomized.
     */
    fun shuffle() {
        cards.shuffle()
    }

    private fun createShuffledDeck(): MutableList<Card> {
        val deck = mutableListOf<Card>()
        for (suit in Suit.values()) {
            for (rank in Rank.values()) {
                deck.add(Card(rank, suit))
            }
        }
        deck.shuffle()
        return deck
    }
}