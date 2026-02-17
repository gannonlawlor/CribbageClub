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
 * Medium difficulty AI that uses hand scoring to optimize discard decisions
 * and smarter pegging strategy.
 *
 * Discard: Evaluates all 15 possible 4-card keeps, picks the one with
 * the highest average hand score across all possible cut cards.
 *
 * Pegging: Same priority as Basic (31, 15, pair, run) but also avoids
 * setting up opponent for pairs and prefers playing cards that maintain
 * scoring flexibility.
 */
class MediumAIPlayer(
    override val playerId: String,
    override val playerName: String = "AI Player (Medium)"
) : AIPlayer {

    override fun getNextAction(gameState: GameState): GameAction? {
        if (gameState.currentPlayerId != playerId) return null
        val player = gameState.players.find { it.id == playerId } ?: return null

        return when (gameState.stage) {
            GameStage.DISCARDING_TO_CRIB -> {
                val thisPlayerDiscarded = 6 - player.hand.size
                if (thisPlayerDiscarded < 2) {
                    val cardsToDiscard = chooseCardsToDiscard(player.hand, isDealer(gameState))
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

        // Evaluate all possible 4-card keeps and pick the best
        var bestDiscard: List<Card> = hand.take(2)
        var bestScore = -1.0

        val allCombos = hand.combinations(4)
        for (keep in allCombos) {
            val avgScore = averageHandScore(keep)
            if (avgScore > bestScore) {
                bestScore = avgScore
                bestDiscard = hand - keep.toSet()
            }
        }

        return bestDiscard
    }

    override fun chooseCardToPlay(hand: List<Card>, playedCards: List<Card>, currentCount: Int): Card? {
        val playableCards = hand.filter { currentCount + it.peggingValue() <= 31 }
        if (playableCards.isEmpty()) return null

        // Priority 1: Make 31
        playableCards.find { currentCount + it.peggingValue() == 31 }?.let { return it }

        // Priority 2: Make 15
        playableCards.find { currentCount + it.peggingValue() == 15 }?.let { return it }

        // Priority 3: Make a pair (but check if opponent could make trips)
        if (playedCards.isNotEmpty()) {
            val lastCard = playedCards.last()
            val pairCard = playableCards.find { it.rank == lastCard.rank }
            if (pairCard != null) {
                // Only pair if we also have a third (trips) or opponent is unlikely to have one
                val weHaveTrips = playableCards.count { it.rank == lastCard.rank } >= 2
                if (weHaveTrips || playedCards.count { it.rank == lastCard.rank } == 1) {
                    return pairCard
                }
            }
        }

        // Priority 4: Continue a run
        if (playedCards.size >= 2) {
            findRunContinuation(playableCards, playedCards)?.let { return it }
        }

        // Priority 5: Avoid dangerous counts and avoid setting up opponent for pairs
        val safeCards = playableCards.filter { card ->
            val newCount = currentCount + card.peggingValue()
            newCount != 5 && newCount != 16 && newCount != 21
        }

        if (safeCards.isNotEmpty()) {
            // Among safe cards, prefer ones that don't match the last played card's neighbors
            return safeCards.maxByOrNull { it.peggingValue() }
        }

        return playableCards.minByOrNull { it.peggingValue() }
    }

    /**
     * Calculates the average hand score across all 46 possible cut cards.
     */
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

    private fun isDealer(gameState: GameState): Boolean {
        return gameState.players.getOrNull(gameState.dealerIndex)?.id == playerId
    }

    private fun findRunContinuation(playableCards: List<Card>, playedCards: List<Card>): Card? {
        val recentCards = playedCards.takeLast(3)
        if (recentCards.size < 2) return null

        val recentRanks = recentCards.map { it.rank.ordinal }.sorted()
        val isConsecutive = recentRanks.zipWithNext().all { (a, b) -> b - a == 1 }

        if (isConsecutive) {
            val minRank = recentRanks.min()
            val maxRank = recentRanks.max()
            return playableCards.find { card ->
                val rank = card.rank.ordinal
                rank == minRank - 1 || rank == maxRank + 1
            }
        }
        return null
    }

    private fun <T> List<T>.combinations(size: Int): List<List<T>> {
        if (size == 0) return listOf(emptyList())
        if (isEmpty()) return emptyList()
        val head = first()
        val tail = drop(1)
        return tail.combinations(size - 1).map { listOf(head) + it } + tail.combinations(size)
    }
}
