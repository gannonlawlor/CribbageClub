package com.jackabee.cribbageclubserver.websocket

import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.game.GameState
import java.time.Instant

/**
 * WebSocket message types for game communication
 */

// Messages sent from client to server
data class GameActionMessage(
    val gameId: String,
    val action: GameAction
)

data class JoinGameMessage(
    val gameId: String
)

data class LeaveGameMessage(
    val gameId: String
)

// Messages sent from server to client
data class GameStateUpdateMessage(
    val gameId: String,
    val gameState: GameState,
    val turnStartedAt: Instant? = null,
    val turnTimeLimitMs: Long = 30000,
    val player1TimeBankMs: Long = 120000,
    val player2TimeBankMs: Long = 120000,
    val isTimed: Boolean = false,
    val timeControl: String = "RAPID",
    val timestamp: Long = System.currentTimeMillis(),
    /**
     * Which filtered view [gameState] is: "PLAYER" (a participant's own view,
     * sent on their user queue) or "SPECTATOR" (all hands hidden, sent on the
     * game topic). Participants must ignore SPECTATOR frames — the topic frame
     * arrives after their queue frame and would wipe their own hand from the UI.
     */
    val view: String = "PLAYER"
)

data class PlayerJoinedMessage(
    val gameId: String,
    val playerId: String,
    val playerName: String,
    val timestamp: Long = System.currentTimeMillis()
)

data class PlayerLeftMessage(
    val gameId: String,
    val playerId: String,
    val timestamp: Long = System.currentTimeMillis()
)

data class GameErrorMessage(
    val gameId: String,
    val error: String,
    val timestamp: Long = System.currentTimeMillis()
)
