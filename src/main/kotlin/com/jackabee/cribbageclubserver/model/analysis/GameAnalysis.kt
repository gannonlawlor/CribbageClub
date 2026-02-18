package com.jackabee.cribbageclubserver.model.analysis

import com.jackabee.cribbageclubserver.model.card.Card

data class DiscardOption(
    val keep: List<Card>,
    val discard: List<Card>,
    val expectedHandValue: Double,
    val expectedCribValue: Double,
    val expectedCombinedValue: Double
)

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
    val optimalDiscard: DiscardOption,
    val playerDiscard: DiscardOption,
    val evDifference: Double
)
