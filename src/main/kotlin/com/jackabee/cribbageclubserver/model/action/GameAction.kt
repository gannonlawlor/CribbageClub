package com.jackabee.cribbageclubserver.model.action

import com.jackabee.cribbageclubserver.model.card.Card


sealed class GameAction {
    abstract val playerId: String

    data class DiscardToCrib(override val playerId: String, val card: Card) : GameAction()
    data class PlayCard(override val playerId: String, val card: Card) : GameAction()
    data class CutDeck(override val playerId: String) : GameAction()
    data class Go(override val playerId: String) : GameAction()
    data class CountHand(override val playerId: String) : GameAction()
}