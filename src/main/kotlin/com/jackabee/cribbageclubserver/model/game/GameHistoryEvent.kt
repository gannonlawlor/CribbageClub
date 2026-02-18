package com.jackabee.cribbageclubserver.model.game

import com.fasterxml.jackson.annotation.JsonSubTypes
import com.fasterxml.jackson.annotation.JsonTypeInfo
import com.jackabee.cribbageclubserver.model.card.Card
import java.time.Instant

/**
 * Represents different types of events that occur during a cribbage game.
 * Only tracks information that would be visible to both players.
 */
@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, property = "type")
@JsonSubTypes(
    JsonSubTypes.Type(value = GameHistoryEvent.RoundStarted::class, name = "RoundStarted"),
    JsonSubTypes.Type(value = GameHistoryEvent.CardsDealt::class, name = "CardsDealt"),
    JsonSubTypes.Type(value = GameHistoryEvent.DeckCut::class, name = "DeckCut"),
    JsonSubTypes.Type(value = GameHistoryEvent.CardPlayed::class, name = "CardPlayed"),
    JsonSubTypes.Type(value = GameHistoryEvent.GoAnnounced::class, name = "GoAnnounced"),
    JsonSubTypes.Type(value = GameHistoryEvent.PeggingEnded::class, name = "PeggingEnded"),
    JsonSubTypes.Type(value = GameHistoryEvent.HandCounted::class, name = "HandCounted"),
    JsonSubTypes.Type(value = GameHistoryEvent.CribCounted::class, name = "CribCounted"),
    JsonSubTypes.Type(value = GameHistoryEvent.GameEnded::class, name = "GameEnded")
)
sealed class GameHistoryEvent {
    abstract val timestamp: Instant

    /**
     * A new round has started
     */
    data class RoundStarted(
        override val timestamp: Instant = Instant.now(),
        val roundNumber: Int
    ) : GameHistoryEvent()

    /**
     * Cards have been dealt to players
     */
    data class CardsDealt(
        override val timestamp: Instant = Instant.now(),
        val dealtHands: Map<String, List<Card>> = emptyMap()
    ) : GameHistoryEvent()

    /**
     * The deck has been cut and the cut card revealed
     */
    data class DeckCut(
        override val timestamp: Instant = Instant.now(),
        val cutCard: Card,
        val cuttingPlayerId: String,
        val dealerScoredNobs: Boolean = false
    ) : GameHistoryEvent()

    /**
     * A card was played during pegging
     */
    data class CardPlayed(
        override val timestamp: Instant = Instant.now(),
        val playerId: String,
        val card: Card,
        val newCount: Int,
        val pointsScored: Int,
        val scoringReason: String? = null
    ) : GameHistoryEvent()

    /**
     * A player announced "Go" during pegging
     */
    data class GoAnnounced(
        override val timestamp: Instant = Instant.now(),
        val playerId: String,
        val pointsScored: Int = 0
    ) : GameHistoryEvent()

    /**
     * Pegging round has ended
     */
    data class PeggingEnded(
        override val timestamp: Instant = Instant.now()
    ) : GameHistoryEvent()

    /**
     * A player's hand was counted
     */
    data class HandCounted(
        override val timestamp: Instant = Instant.now(),
        val playerId: String,
        val hand: List<Card> = emptyList(),
        val totalPoints: Int,
        val scoreBreakdown: ScoreBreakdown
    ) : GameHistoryEvent()

    /**
     * The crib was counted
     */
    data class CribCounted(
        override val timestamp: Instant = Instant.now(),
        val dealerPlayerId: String,
        val totalPoints: Int,
        val scoreBreakdown: ScoreBreakdown,
        val cribCards: List<Card> = emptyList()
    ) : GameHistoryEvent()

    /**
     * The game has ended
     */
    data class GameEnded(
        override val timestamp: Instant = Instant.now(),
        val winnerPlayerId: String,
        val finalScore: Int
    ) : GameHistoryEvent()

    /**
     * Breakdown of how points were scored in hand or crib counting
     */
    data class ScoreBreakdown(
        val fifteens: Int = 0,
        val pairs: Int = 0,
        val runs: Int = 0,
        val flushes: Int = 0,
        val nobs: Int = 0
    ) {
        val totalScore: Int get() = fifteens + pairs + runs + flushes + nobs
    }
}