package com.jackabee.cribbageclubserver.model.game

import java.time.Instant

data class GameResponse(
    val gameState: GameState,
    val turnStartedAt: Instant? = null,
    val turnTimeLimitMs: Long = 30000,
    val myTimeBankMs: Long = 120000,
    val opponentTimeBankMs: Long = 120000,
    val isTimed: Boolean = false
)
