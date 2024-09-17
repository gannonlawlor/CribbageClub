package com.jackabee.cribbageclubserver.model.action

import com.jackabee.cribbageclubserver.model.card.Card


data class GameAction(
    val playerId: String,
    val actionType: ActionType,
    val card: Card? = null
)