package com.jackabee.cribbageclubserver.utils

import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.game.GameHistoryEvent
import com.jackabee.cribbageclubserver.utils.HandCounting.countingValue

/**
 * Utility to calculate detailed score breakdowns for hand and crib counting
 */
object ScoreBreakdownCalculator {

    /**
     * Calculate a detailed breakdown of hand scoring
     */
    fun calculateHandScoreBreakdown(hand: List<Card>, cutCard: Card, isCrib: Boolean = false): GameHistoryEvent.ScoreBreakdown {
        val allCards = hand + cutCard
        
        val fifteens = count15s(allCards)
        val pairs = countPairs(allCards)
        val runs = countRuns(allCards)
        val flushes = countFlushes(hand, cutCard, isCrib)
        val nobs = countNobs(hand, cutCard)
        
        return GameHistoryEvent.ScoreBreakdown(
            fifteens = fifteens,
            pairs = pairs,
            runs = runs,
            flushes = flushes,
            nobs = nobs
        )
    }

    private fun count15s(cards: List<Card>): Int {
        var count = 0
        val values = cards.map { it.countingValue() }

        // Check all possible combinations
        for (i in 1 until (1 shl cards.size)) {
            var sum = 0
            for (j in cards.indices) {
                if ((i shr j) and 1 == 1) {
                    sum += values[j]
                }
            }
            if (sum == 15) count++
        }
        return count * 2 // Each 15 is worth 2 points
    }

    private fun countPairs(cards: List<Card>): Int {
        val rankCounts = cards.groupingBy { it.rank }.eachCount()
        var score = 0
        for (count in rankCounts.values) {
            if (count >= 2) {
                score += count * (count - 1) // n choose 2 pairs
            }
        }
        return score
    }

    private fun countRuns(cards: List<Card>): Int {
        val rankCounts = cards.groupingBy { it.rank }.eachCount()
        val sortedRanks = rankCounts.keys.sortedBy { it.ordinal }

        if (sortedRanks.size < 3) return 0

        // Find longest consecutive sequence
        var longestRunLength = 1
        var currentRunLength = 1
        var runStart = 0

        for (i in 1 until sortedRanks.size) {
            if (sortedRanks[i].ordinal == sortedRanks[i - 1].ordinal + 1) {
                currentRunLength++
            } else {
                if (currentRunLength > longestRunLength) {
                    longestRunLength = currentRunLength
                    runStart = i - currentRunLength
                }
                currentRunLength = 1
            }
        }

        // Check final run
        if (currentRunLength > longestRunLength) {
            longestRunLength = currentRunLength
            runStart = sortedRanks.size - currentRunLength
        }

        if (longestRunLength >= 3) {
            // Calculate score: run length * product of counts for each rank in run
            var multiplier = 1
            for (i in runStart until runStart + longestRunLength) {
                multiplier *= rankCounts[sortedRanks[i]]!!
            }
            return longestRunLength * multiplier
        }
        return 0
    }

    private fun countFlushes(hand: List<Card>, cutCard: Card, isCrib: Boolean): Int {
        val handSuits = hand.map { it.suit }
        val handFlush = handSuits.all { it == handSuits[0] }

        if (handFlush && cutCard.suit == handSuits[0]) {
            return 5 // All cards same suit
        } else if (handFlush && !isCrib) {
            return 4 // Hand flush but not crib
        }
        return 0
    }

    private fun countNobs(hand: List<Card>, cutCard: Card): Int {
        return if (hand.any { it.rank == Rank.JACK && it.suit == cutCard.suit }) 1 else 0
    }
}