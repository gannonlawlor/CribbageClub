package com.jackabee.cribbageclubserver.model.game

import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.player.Player

data class GameState(
    val gameId: String,
    val players: List<Player>,
    val crib: List<Card> = emptyList(),
    val cutCard: Card? = null,
    val currentPlayerId: String? = null,
    val stage: GameStage = GameStage.DEALING,
    val playedCards: List<Card> = emptyList(),
    val peggingCount: Int = 0,
    val lastPlayWasGo: Boolean = false,
    val handsForCounting: Map<String, List<Card>> = emptyMap(),
    val history: List<GameHistoryEvent> = emptyList(),
    val dealerIndex: Int = 0,
    val remainingDeck: List<Card> = emptyList()
)