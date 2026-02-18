package com.jackabee.cribbageclubserver.model.lobby

import java.time.Instant

data class Lobby(
    val id: String,
    val name: String,
    val players: List<LobbyPlayer> = emptyList(),
    val maxPlayers: Int = 2,
    val status: LobbyStatus = LobbyStatus.WAITING,
    val createdAt: Instant = Instant.now(),
    val gameId: String? = null,
    val isPrivate: Boolean = false,
    val inviteCode: String? = null,
    val challengedUserId: String? = null
) {
    val isReady: Boolean get() = players.size == maxPlayers
    val hasSpace: Boolean get() = players.size < maxPlayers

    fun addPlayer(player: LobbyPlayer): Lobby {
        require(hasSpace) { "Lobby is full" }
        require(players.none { it.id == player.id }) { "Player already in lobby" }

        return copy(players = players + player)
    }

    fun removePlayer(playerId: String): Lobby {
        return copy(players = players.filter { it.id != playerId })
    }

    fun startGame(gameId: String): Lobby {
        require(isReady) { "Lobby is not ready to start" }
        return copy(status = LobbyStatus.IN_GAME, gameId = gameId)
    }
}

data class LobbyPlayer(
    val id: String,
    val name: String,
    val joinedAt: Instant = Instant.now()
)

enum class LobbyStatus {
    WAITING,
    IN_GAME,
    COMPLETED
}
