package com.jackabee.cribbageclubserver.model.game

import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.player.Player

data class GameState(
    val players: List<Player>,
    val crib: List<Card> = emptyList(),
    val cutCard: Card? = null,
    val currentPlayerId: String? = null,
    val stage: GameStage = GameStage.DEALING,
    val playedCards: List<Card> = emptyList(),
    val peggingCount: Int = 0,
    val lastPlayWasGo: Boolean = false
)