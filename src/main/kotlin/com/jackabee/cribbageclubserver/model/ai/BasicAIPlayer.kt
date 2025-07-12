package com.jackabee.cribbageclubserver.model.ai

import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.utils.HandCounting.peggingValue
import kotlin.random.Random

/**
 * A basic AI player implementation that uses simple strategies to play cribbage.
 * 
 * This AI uses basic heuristics for decision making:
 * - Discarding: Removes lowest value cards unless dealer, then tries to keep good crib cards
 * - Pegging: Tries to make 15s and 31s, avoids giving opponent easy scores
 */
class BasicAIPlayer(
    override val playerId: String,
    override val playerName: String = "AI Player"
) : AIPlayer {

    override fun getNextAction(gameState: GameState): GameAction? {
        // Only make decisions if it's this AI's turn
        if (gameState.currentPlayerId != playerId) return null
        
        val player = gameState.players.find { it.id == playerId } ?: return null
        
        return when (gameState.stage) {
            GameStage.DISCARDING_TO_CRIB -> {
                // Count how many cards this player has already discarded
                val thisPlayerDiscarded = 6 - player.hand.size
                
                // Each player needs to discard 2 cards, check if this player still needs to discard
                if (thisPlayerDiscarded < 2) {
                    val cardsToDiscard = chooseCardsToDiscard(player.hand, isDealer(gameState))
                    // Return first card to discard that hasn't been discarded yet
                    cardsToDiscard.getOrNull(thisPlayerDiscarded)?.let { card ->
                        GameAction.DiscardToCrib(playerId, card)
                    }
                } else null
            }
            
            GameStage.CUTTING -> {
                GameAction.CutDeck(playerId)
            }
            
            GameStage.PEGGING -> {
                val cardToPlay = chooseCardToPlay(player.hand, gameState.playedCards, gameState.peggingCount)
                if (cardToPlay != null) {
                    GameAction.PlayCard(playerId, cardToPlay)
                } else {
                    GameAction.Go(playerId)
                }
            }
            
            GameStage.COUNTING -> {
                GameAction.CountHand(playerId)
            }
            
            else -> null
        }
    }

    override fun chooseCardsToDiscard(hand: List<Card>, isDealer: Boolean): List<Card> {
        if (hand.size < 2) return hand
        
        return if (isDealer) {
            // As dealer, try to keep cards that work well together and discard others
            // Simple strategy: keep pairs and cards that make 15s, discard the rest
            chooseDealerDiscards(hand)
        } else {
            // As non-dealer, try to give dealer bad cards for the crib
            // Simple strategy: discard high cards that might help dealer
            chooseNonDealerDiscards(hand)
        }
    }
    
    private fun chooseDealerDiscards(hand: List<Card>): List<Card> {
        // As dealer, we want to keep good cards and put potentially useful cards in our crib
        val sortedByValue = hand.sortedBy { it.peggingValue() }
        
        // Look for pairs
        val pairs = hand.groupBy { it.rank }.filter { it.value.size >= 2 }
        if (pairs.isNotEmpty()) {
            // Keep pairs, discard other cards
            val pairCards = pairs.values.flatten()
            val nonPairCards = hand - pairCards.toSet()
            return nonPairCards.take(2)
        }
        
        // Look for 15s combinations
        val fifteenCombos = findFifteenCombinations(hand)
        if (fifteenCombos.isNotEmpty()) {
            // Keep first 15 combination, discard others
            val keepCards = fifteenCombos.first()
            val discardCards = hand - keepCards.toSet()
            return discardCards.take(2)
        }
        
        // Default: discard two lowest cards
        return sortedByValue.take(2)
    }
    
    private fun chooseNonDealerDiscards(hand: List<Card>): List<Card> {
        // As non-dealer, we want to avoid giving the dealer good crib cards
        // Simple strategy: avoid discarding pairs or cards that make 15s
        val sortedByValue = hand.sortedByDescending { it.peggingValue() }
        
        // Try to avoid discarding pairs or cards that sum to 15
        val candidates = mutableListOf<Card>()
        
        for (card in sortedByValue) {
            if (candidates.size >= 2) break
            
            // Check if this card would make a pair with existing candidates
            val wouldMakePair = candidates.any { it.rank == card.rank }
            
            // Check if this card would make 15 with existing candidates
            val wouldMakeFifteen = candidates.any { it.peggingValue() + card.peggingValue() == 15 }
            
            // Prefer cards that don't make pairs or 15s
            if (!wouldMakePair && !wouldMakeFifteen) {
                candidates.add(card)
            }
        }
        
        // If we couldn't find 2 non-problematic cards, just take the first 2
        if (candidates.size < 2) {
            return sortedByValue.take(2)
        }
        
        return candidates.take(2)
    }

    override fun chooseCardToPlay(hand: List<Card>, playedCards: List<Card>, currentCount: Int): Card? {
        // Filter playable cards (won't exceed 31)
        val playableCards = hand.filter { currentCount + it.peggingValue() <= 31 }
        
        if (playableCards.isEmpty()) return null
        
        // Try to make 31 (scores 2 points)
        val thirtyOneCard = playableCards.find { currentCount + it.peggingValue() == 31 }
        if (thirtyOneCard != null) return thirtyOneCard
        
        // Try to make 15 (scores 2 points)
        val fifteenCard = playableCards.find { currentCount + it.peggingValue() == 15 }
        if (fifteenCard != null) return fifteenCard
        
        // Try to make a pair (scores 2 points)
        if (playedCards.isNotEmpty()) {
            val lastCard = playedCards.last()
            val pairCard = playableCards.find { it.rank == lastCard.rank }
            if (pairCard != null) return pairCard
        }
        
        // Try to continue a run
        if (playedCards.size >= 2) {
            val runCard = findRunContinuation(playableCards, playedCards)
            if (runCard != null) return runCard
        }
        
        // Avoid giving opponent easy scores
        // Don't play cards that would make it easy for opponent to score
        val safeCards = playableCards.filter { card ->
            val newCount = currentCount + card.peggingValue()
            // Avoid counts that make it easy for opponent to hit 15 or 31
            newCount != 5 && newCount != 16 && newCount != 21
        }
        
        if (safeCards.isNotEmpty()) {
            // Play the highest safe card to get closer to 31
            return safeCards.maxByOrNull { it.peggingValue() }
        }
        
        // If no safe cards, play the lowest card
        return playableCards.minByOrNull { it.peggingValue() }
    }
    
    private fun isDealer(gameState: GameState): Boolean {
        // Simple heuristic: assume first player is dealer
        // In a full implementation, this would track dealer rotation
        return gameState.players.firstOrNull()?.id == playerId
    }
    
    private fun findFifteenCombinations(cards: List<Card>): List<List<Card>> {
        val combinations = mutableListOf<List<Card>>()
        
        // Check all possible combinations of 2-5 cards
        for (size in 2..minOf(5, cards.size)) {
            for (combo in cards.combinations(size)) {
                if (combo.sumOf { it.peggingValue() } == 15) {
                    combinations.add(combo)
                }
            }
        }
        
        return combinations
    }
    
    private fun findRunContinuation(playableCards: List<Card>, playedCards: List<Card>): Card? {
        // Look for cards that would continue the current run
        // This is a simplified version - full implementation would be more complex
        val recentCards = playedCards.takeLast(3)
        if (recentCards.size < 2) return null
        
        val recentRanks = recentCards.map { it.rank.ordinal }.sorted()
        val isConsecutive = recentRanks.zipWithNext().all { (a, b) -> b - a == 1 }
        
        if (isConsecutive) {
            // Try to extend the run at either end
            val minRank = recentRanks.min()
            val maxRank = recentRanks.max()
            
            return playableCards.find { card ->
                val rank = card.rank.ordinal
                rank == minRank - 1 || rank == maxRank + 1
            }
        }
        
        return null
    }
    
    // Extension function to generate combinations
    private fun <T> List<T>.combinations(size: Int): List<List<T>> {
        if (size == 0) return listOf(emptyList())
        if (isEmpty()) return emptyList()
        
        val head = first()
        val tail = drop(1)
        
        return tail.combinations(size - 1).map { listOf(head) + it } + tail.combinations(size)
    }
}