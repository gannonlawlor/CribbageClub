package com.jackabee.cribbageclubserver.utils

import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.game.GameHistoryEvent

/**
 * Utility to calculate detailed score breakdowns for hand and crib counting
 */
object ScoreBreakdownCalculator {

    /**
     * Calculate a detailed breakdown of hand scoring
     */
    fun calculateHandScoreBreakdown(hand: List<Card>, cutCard: Card, isCrib: Boolean = false): GameHistoryEvent.ScoreBreakdown {
        val allCards = hand + cutCard
        
        val fifteens = HandCounting.count15s(allCards)
        val pairs = HandCounting.countPairs(allCards)
        val runs = HandCounting.countRuns(allCards)
        val flushes = HandCounting.countFlushes(hand, cutCard, isCrib)
        val nobs = HandCounting.countNobs(hand, cutCard)
        
        val totalScore = fifteens + pairs + runs + flushes + nobs
        
        return GameHistoryEvent.ScoreBreakdown(
            fifteens = fifteens,
            pairs = pairs,
            runs = runs,
            flushes = flushes,
            nobs = nobs,
            totalScore = totalScore
        )
    }
}