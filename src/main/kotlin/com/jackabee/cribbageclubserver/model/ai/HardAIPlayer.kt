package com.jackabee.cribbageclubserver.model.ai

import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.utils.HandCounting
import com.jackabee.cribbageclubserver.utils.HandCounting.peggingValue

/**
 * Hard difficulty AI with optimal discard selection and advanced pegging.
 *
 * Discard: Evaluates all 15 possible 4-card keeps considering both the
 * expected hand score AND the expected crib score (positive for dealer,
 * negative for non-dealer).
 *
 * Pegging: Full scoring evaluation — considers pairs, trips, runs,
 * and trap plays (e.g. playing a card to bait opponent into a pair
 * when we hold trips).
 */
class HardAIPlayer(
    override val playerId: String,
    override val playerName: String = "AI Player (Hard)"
) : AIPlayer {

    override fun getNextAction(gameState: GameState): GameAction? {
        if (gameState.currentPlayerId != playerId) return null
        val player = gameState.players.find { it.id == playerId } ?: return null

        return when (gameState.stage) {
            GameStage.DISCARDING_TO_CRIB -> {
                val thisPlayerDiscarded = 6 - player.hand.size
                if (thisPlayerDiscarded < 2) {
                    val isDealer = isDealer(gameState)
                    val cardsToDiscard = chooseCardsToDiscard(player.hand, isDealer)
                    cardsToDiscard.getOrNull(thisPlayerDiscarded)?.let { card ->
                        GameAction.DiscardToCrib(playerId, card)
                    }
                } else null
            }
            GameStage.CUTTING -> GameAction.CutDeck(playerId)
            GameStage.PEGGING -> {
                val cardToPlay = chooseCardToPlay(player.hand, gameState.playedCards, gameState.peggingCount)
                if (cardToPlay != null) GameAction.PlayCard(playerId, cardToPlay)
                else GameAction.Go(playerId)
            }
            GameStage.COUNTING -> GameAction.CountHand(playerId)
            else -> null
        }
    }

    override fun chooseCardsToDiscard(hand: List<Card>, isDealer: Boolean): List<Card> {
        if (hand.size <= 4) return emptyList()

        var bestDiscard: List<Card> = hand.take(2)
        var bestNetScore = Double.MIN_VALUE

        val allKeeps = hand.combinations(4)
        for (keep in allKeeps) {
            val discard = hand - keep.toSet()
            val handAvg = averageHandScore(keep)
            val cribAvg = averageCribScore(discard)

            // Dealer wants high crib score, non-dealer wants low crib score
            val netScore = if (isDealer) {
                handAvg + cribAvg
            } else {
                handAvg - cribAvg
            }

            if (netScore > bestNetScore) {
                bestNetScore = netScore
                bestDiscard = discard
            }
        }

        return bestDiscard
    }

    override fun chooseCardToPlay(hand: List<Card>, playedCards: List<Card>, currentCount: Int): Card? {
        val playableCards = hand.filter { currentCount + it.peggingValue() <= 31 }
        if (playableCards.isEmpty()) return null

        // Score each playable card
        val scoredCards = playableCards.map { card ->
            card to evaluatePeggingPlay(card, playableCards, playedCards, currentCount)
        }

        return scoredCards.maxByOrNull { it.second }?.first
    }

    /**
     * Scores a potential pegging play considering immediate points,
     * defensive positioning, and trap potential.
     */
    private fun evaluatePeggingPlay(
        card: Card,
        allPlayable: List<Card>,
        playedCards: List<Card>,
        currentCount: Int
    ): Double {
        val newCount = currentCount + card.peggingValue()
        var score = 0.0

        // Immediate scoring
        if (newCount == 31) score += 20.0
        if (newCount == 15) score += 20.0

        // Pair scoring
        if (playedCards.isNotEmpty() && playedCards.last().rank == card.rank) {
            // Check if we have trips
            val weHaveAnother = allPlayable.count { it.rank == card.rank } >= 2
            if (weHaveAnother) {
                score += 15.0 // Pair now, trips next turn
            } else {
                score += 10.0 // Just the pair
            }
        }

        // Run scoring
        if (playedCards.size >= 2) {
            val runLength = checkRunLength(playedCards + card)
            if (runLength >= 3) score += runLength * 4.0
        }

        // Trap play: if we have a pair in hand, play one to bait opponent into pairing
        // so we can play trips
        val pairsInHand = allPlayable.groupBy { it.rank }.filter { it.value.size >= 2 }
        if (pairsInHand.containsKey(card.rank) && playedCards.isEmpty()) {
            score += 3.0 // Bait for trips
        }

        // Defensive: penalize dangerous counts
        if (newCount == 5) score -= 8.0   // Easy 15 for opponent (any 10-value)
        if (newCount == 21) score -= 6.0  // Easy 31 for opponent (any 10-value)
        if (newCount == 16) score -= 3.0  // Easy 15 setup

        // Prefer leaving count at hard-to-score values
        if (newCount in listOf(22, 23, 24, 25, 26, 27)) score += 1.0

        // Slight preference for higher cards early to maintain flexibility
        if (currentCount < 10) score += card.peggingValue() * 0.1

        return score
    }

    /**
     * Checks if the most recent sequence of played cards forms a run.
     */
    private fun checkRunLength(cards: List<Card>): Int {
        for (length in minOf(cards.size, 7) downTo 3) {
            val recent = cards.takeLast(length)
            val ranks = recent.map { it.rank.ordinal }.sorted()
            if (ranks.zipWithNext().all { (a, b) -> b - a == 1 }) {
                return length
            }
        }
        return 0
    }

    private fun averageHandScore(keep: List<Card>): Double {
        var totalScore = 0
        var cutCount = 0

        for (rank in Rank.entries) {
            for (suit in Suit.entries) {
                val cutCard = Card(rank, suit)
                if (cutCard in keep) continue
                totalScore += HandCounting.calculateHandScore(keep, cutCard)
                cutCount++
            }
        }

        return if (cutCount > 0) totalScore.toDouble() / cutCount else 0.0
    }

    /**
     * Estimates the average crib score for the two discarded cards,
     * assuming random opponent discards and random cut card.
     * Uses a simplified estimation: score the 2 discard cards with
     * each possible cut card (ignoring unknown opponent discards).
     */
    private fun averageCribScore(discard: List<Card>): Double {
        if (discard.size != 2) return 0.0

        var totalScore = 0
        var count = 0

        // Approximate: evaluate the 2 crib cards with every possible cut card
        // This underestimates actual crib value but captures the relative ranking
        for (rank in Rank.entries) {
            for (suit in Suit.entries) {
                val cutCard = Card(rank, suit)
                if (cutCard in discard) continue

                // Score just our 2 discard cards + cut card for 15s and pairs
                val allCards = discard + cutCard
                var score = 0

                // 15s from our discards + cut
                val values = allCards.map { it.peggingValue() }
                for (i in 1 until (1 shl allCards.size)) {
                    var sum = 0
                    for (j in allCards.indices) {
                        if ((i shr j) and 1 == 1) sum += values[j]
                    }
                    if (sum == 15) score += 2
                }

                // Pair between our two discards
                if (discard[0].rank == discard[1].rank) score += 2

                totalScore += score
                count++
            }
        }

        return if (count > 0) totalScore.toDouble() / count else 0.0
    }

    private fun isDealer(gameState: GameState): Boolean {
        return gameState.players.getOrNull(gameState.dealerIndex)?.id == playerId
    }

    private fun <T> List<T>.combinations(size: Int): List<List<T>> {
        if (size == 0) return listOf(emptyList())
        if (isEmpty()) return emptyList()
        val head = first()
        val tail = drop(1)
        return tail.combinations(size - 1).map { listOf(head) + it } + tail.combinations(size)
    }

    private fun Card.peggingValue(): Int = HandCounting.run { this@peggingValue.peggingValue() }
}
