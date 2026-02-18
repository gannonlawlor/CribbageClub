package com.jackabee.cribbageclubserver.utils

import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit

/**
 * Analyzes all possible discard options from a 6-card hand in cribbage,
 * computing expected hand value and expected crib value for each option.
 *
 * Used for post-game discard analysis and AI decision-making.
 */
object DiscardAnalyzer {

    data class DiscardOption(
        val keep: List<Card>,
        val discard: List<Card>,
        val expectedHandValue: Double,
        val expectedCribValue: Double,
        val expectedCombinedValue: Double
    )

    private val ALL_CARDS: List<Card> = Rank.entries.flatMap { rank ->
        Suit.entries.map { suit -> Card(rank, suit) }
    }

    /**
     * Analyzes all 15 possible 4-card keeps from a 6-card hand.
     *
     * @param hand 6-card dealt hand
     * @param isDealer true if this player is the dealer (crib value is added, not subtracted)
     * @return all 15 discard options sorted by expectedCombinedValue descending
     */
    fun analyzeAllDiscards(hand: List<Card>, isDealer: Boolean): List<DiscardOption> {
        require(hand.size == 6) { "Hand must have exactly 6 cards" }

        val handSet = hand.toSet()

        return combinations(hand, 4).map { keep ->
            val discard = hand.filter { it !in keep }
            val expectedHand = expectedHandValue(keep, handSet)
            val expectedCrib = expectedCribValue(discard, handSet)
            val combined = if (isDealer) expectedHand + expectedCrib else expectedHand - expectedCrib

            DiscardOption(
                keep = keep,
                discard = discard,
                expectedHandValue = expectedHand,
                expectedCribValue = expectedCrib,
                expectedCombinedValue = combined
            )
        }.sortedByDescending { it.expectedCombinedValue }
    }

    /**
     * Returns the optimal discard option (highest expectedCombinedValue).
     */
    fun findOptimalDiscard(hand: List<Card>, isDealer: Boolean): DiscardOption {
        return analyzeAllDiscards(hand, isDealer).first()
    }

    /**
     * Expected hand score across all possible cut cards.
     * Iterates over all 52 cards, skipping those in the dealt hand (46 remaining).
     */
    internal fun expectedHandValue(keep: List<Card>, knownCards: Set<Card>): Double {
        var totalScore = 0
        var cutCount = 0

        for (card in ALL_CARDS) {
            if (card in knownCards) continue
            totalScore += HandCounting.calculateHandScore(keep, card)
            cutCount++
        }

        return if (cutCount > 0) totalScore.toDouble() / cutCount else 0.0
    }

    /**
     * Expected crib value via full enumeration.
     *
     * For the 2 discarded cards, iterate all C(46,2) = 1035 possible opponent
     * discard pairs from the remaining deck, then for each of the 44 remaining
     * cut cards, score the 4-card crib.
     *
     * Total: 1035 × 44 = 45,540 evaluations per discard option.
     */
    internal fun expectedCribValue(discard: List<Card>, knownCards: Set<Card>): Double {
        val remaining = ALL_CARDS.filter { it !in knownCards }

        var totalScore = 0L
        var count = 0

        for (i in remaining.indices) {
            for (j in i + 1 until remaining.size) {
                val opponentCard1 = remaining[i]
                val opponentCard2 = remaining[j]
                val crib = listOf(discard[0], discard[1], opponentCard1, opponentCard2)

                for (k in remaining.indices) {
                    if (k == i || k == j) continue
                    val cutCard = remaining[k]
                    totalScore += HandCounting.calculateHandScore(crib, cutCard, isCrib = true)
                    count++
                }
            }
        }

        return if (count > 0) totalScore.toDouble() / count else 0.0
    }

    /**
     * Generates all k-combinations from the given list.
     */
    internal fun <T> combinations(list: List<T>, k: Int): List<List<T>> {
        if (k == 0) return listOf(emptyList())
        if (list.isEmpty()) return emptyList()
        val head = list.first()
        val tail = list.drop(1)
        return combinations(tail, k - 1).map { listOf(head) + it } + combinations(tail, k)
    }
}
