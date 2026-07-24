package com.jackabee.cribbageclubserver.model.action

import com.fasterxml.jackson.annotation.JsonSubTypes
import com.fasterxml.jackson.annotation.JsonTypeInfo
import com.jackabee.cribbageclubserver.model.card.Card

@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, property = "type")
@JsonSubTypes(
    JsonSubTypes.Type(value = GameAction.DiscardToCrib::class, name = "DiscardToCrib"),
    JsonSubTypes.Type(value = GameAction.PlayCard::class, name = "PlayCard"),
    JsonSubTypes.Type(value = GameAction.CutDeck::class, name = "CutDeck"),
    JsonSubTypes.Type(value = GameAction.Go::class, name = "Go"),
    JsonSubTypes.Type(value = GameAction.CountHand::class, name = "CountHand"),
    JsonSubTypes.Type(value = GameAction.CountCrib::class, name = "CountCrib"),
    JsonSubTypes.Type(value = GameAction.Forfeit::class, name = "Forfeit")
)
sealed class GameAction {
    abstract val playerId: String

    data class DiscardToCrib(override val playerId: String, val card: Card) : GameAction()
    data class PlayCard(override val playerId: String, val card: Card) : GameAction()
    data class CutDeck(override val playerId: String) : GameAction()
    data class Go(override val playerId: String) : GameAction()
    data class CountHand(override val playerId: String) : GameAction()
    data class CountCrib(override val playerId: String) : GameAction()
    data class Forfeit(override val playerId: String, val reason: ForfeitReason = ForfeitReason.RESIGN) : GameAction()
}

enum class ForfeitReason {
    RESIGN,
    TIMEOUT,
    DISCONNECT
}