package com.jackabee.cribbageclubserver.websocket

import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.game.GameState

/**
 * WebSocket message types for game communication
 */

// Messages sent from client to server
data class GameActionMessage(
    val gameId: String,
    val action: GameAction
)

data class JoinGameMessage(
    val gameId: String,
    val playerId: String,
    val playerName: String
)

data class LeaveGameMessage(
    val gameId: String,
    val playerId: String
)

// Messages sent from server to client
data class GameStateUpdateMessage(
    val gameId: String,
    val gameState: GameState,
    val timestamp: Long = System.currentTimeMillis()
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

// Connection management
data class GameConnectionEvent(
    val gameId: String,
    val playerId: String,
    val eventType: ConnectionEventType,
    val timestamp: Long = System.currentTimeMillis()
)

enum class ConnectionEventType {
    CONNECTED,
    DISCONNECTED
}