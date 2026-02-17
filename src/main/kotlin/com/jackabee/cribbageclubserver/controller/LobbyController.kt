package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.model.lobby.Lobby
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.service.LobbyService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/lobbies")
@Tag(name = "Lobbies", description = "Lobby management and matchmaking")
class LobbyController(
    private val lobbyService: LobbyService
) {

    @Operation(summary = "List all lobbies")
    @GetMapping
    fun getLobbies(): List<Lobby> {
        return lobbyService.listLobbies()
    }

    @Operation(summary = "List lobbies waiting for players")
    @GetMapping("/waiting")
    fun getWaitingLobbies(): List<Lobby> {
        return lobbyService.listWaitingLobbies()
    }

    @Operation(summary = "Get a lobby by ID")
    @GetMapping("/{lobbyId}")
    fun getLobby(@PathVariable lobbyId: String): ResponseEntity<Lobby> {
        val lobby = lobbyService.getLobby(lobbyId)
        return if (lobby != null) {
            ResponseEntity.ok(lobby)
        } else {
            ResponseEntity.notFound().build()
        }
    }

    @Operation(summary = "Create a new lobby")
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

    @Operation(summary = "Join a lobby")
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

    @Operation(summary = "Leave a lobby")
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

    @Operation(summary = "Start a game from a full lobby")
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
