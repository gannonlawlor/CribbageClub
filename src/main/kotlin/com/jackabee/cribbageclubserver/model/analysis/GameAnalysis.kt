package com.jackabee.cribbageclubserver.model.analysis

import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.utils.DiscardAnalyzer

data class GameAnalysis(
    val gameId: String,
    val rounds: List<RoundAnalysis>
)

data class RoundAnalysis(
    val roundNumber: Int,
    val cutCard: Card?,
    val dealerPlayerId: String,
    val playerAnalyses: List<PlayerRoundAnalysis>
)

data class PlayerRoundAnalysis(
    val playerId: String,
    val isDealer: Boolean,
    val dealtHand: List<Card>,
    val keptHand: List<Card>,
    val discarded: List<Card>,
    val actualHandScore: Int,
    val actualCribScore: Int?,
    val optimalDiscard: DiscardAnalyzer.DiscardOption,
    val playerDiscard: DiscardAnalyzer.DiscardOption,
    val evDifference: Double
)
