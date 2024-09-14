package com.jackabee.cribbageclubserver.model.player

import com.jackabee.cribbageclubserver.model.card.Card

data class Player(
    val id: String,
    val name: String,
    var hand: List<Card> = emptyList(),
    var score: Int = 0
)