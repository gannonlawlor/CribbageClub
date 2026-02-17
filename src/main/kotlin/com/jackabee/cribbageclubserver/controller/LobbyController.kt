package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.model.lobby.Lobby
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.service.LobbyService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/lobbies")
class LobbyController(
    private val lobbyService: LobbyService
) {

    /**
     * Gets a list of all lobbies.
     */
    @GetMapping
    fun getLobbies(): List<Lobby> {
        return lobbyService.listLobbies()
    }

    /**
     * Gets a list of lobbies that are waiting for players.
     */
    @GetMapping("/waiting")
    fun getWaitingLobbies(): List<Lobby> {
        return lobbyService.listWaitingLobbies()
    }

    /**
     * Gets a specific lobby by ID.
     */
    @GetMapping("/{lobbyId}")
    fun getLobby(@PathVariable lobbyId: String): ResponseEntity<Lobby> {
        val lobby = lobbyService.getLobby(lobbyId)
        return if (lobby != null) {
            ResponseEntity.ok(lobby)
        } else {
            ResponseEntity.notFound().build()
        }
    }

    /**
     * Creates a new lobby.
     */
    @PostMapping
    fun createLobby(@RequestBody request: CreateLobbyRequest): Lobby {
        return lobbyService.createLobby(
            name = request.name,
            creatorId = request.creatorId,
            creatorName = request.creatorName
        )
    }

    /**
     * Joins a lobby.
     */
    @PostMapping("/{lobbyId}/join")
    fun joinLobby(
        @PathVariable lobbyId: String,
        @RequestBody request: JoinLobbyRequest
    ): Lobby {
        return lobbyService.joinLobby(
            lobbyId = lobbyId,
            playerId = request.playerId,
            playerName = request.playerName
        )
    }

    /**
     * Leaves a lobby.
     */
    @PostMapping("/{lobbyId}/leave")
    fun leaveLobby(
        @PathVariable lobbyId: String,
        @RequestBody request: LeaveLobbyRequest
    ): Lobby {
        return lobbyService.leaveLobby(
            lobbyId = lobbyId,
            playerId = request.playerId
        )
    }

    /**
     * Starts a game from a lobby.
     */
    @PostMapping("/{lobbyId}/start")
    fun startGame(@PathVariable lobbyId: String): GameState {
        return lobbyService.startGame(lobbyId)
    }
}

// Request DTOs
data class CreateLobbyRequest(
    val name: String,
    val creatorId: String,
    val creatorName: String
)

data class JoinLobbyRequest(
    val playerId: String,
    val playerName: String
)

data class LeaveLobbyRequest(
    val playerId: String
)
