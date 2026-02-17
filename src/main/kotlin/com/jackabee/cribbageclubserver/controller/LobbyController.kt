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
     * Creates a new lobby. Uses authenticated user as the creator.
     */
    @PostMapping
    fun createLobby(
        @RequestBody request: CreateLobbyRequest,
        @RequestAttribute("userId") userId: String,
        @RequestAttribute("username") username: String
    ): Lobby {
        return lobbyService.createLobby(
            name = request.name,
            creatorId = userId,
            creatorName = request.creatorName ?: username
        )
    }

    /**
     * Joins a lobby. Uses authenticated user.
     */
    @PostMapping("/{lobbyId}/join")
    fun joinLobby(
        @PathVariable lobbyId: String,
        @RequestAttribute("userId") userId: String,
        @RequestAttribute("username") username: String,
        @RequestBody(required = false) request: JoinLobbyRequest?
    ): Lobby {
        return lobbyService.joinLobby(
            lobbyId = lobbyId,
            playerId = userId,
            playerName = request?.playerName ?: username
        )
    }

    /**
     * Leaves a lobby. Uses authenticated user.
     */
    @PostMapping("/{lobbyId}/leave")
    fun leaveLobby(
        @PathVariable lobbyId: String,
        @RequestAttribute("userId") userId: String
    ): Lobby {
        return lobbyService.leaveLobby(
            lobbyId = lobbyId,
            playerId = userId
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
    val creatorName: String? = null
)

data class JoinLobbyRequest(
    val playerName: String? = null
)
