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
    fun getLobbies(): ResponseEntity<List<Lobby>> {
        val lobbies = lobbyService.listLobbies()
        return ResponseEntity.ok(lobbies)
    }
    
    /**
     * Gets a list of lobbies that are waiting for players.
     */
    @GetMapping("/waiting")
    fun getWaitingLobbies(): ResponseEntity<List<Lobby>> {
        val lobbies = lobbyService.listWaitingLobbies()
        return ResponseEntity.ok(lobbies)
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
    fun createLobby(@RequestBody request: CreateLobbyRequest): ResponseEntity<Lobby> {
        val lobby = lobbyService.createLobby(
            name = request.name,
            creatorId = request.creatorId,
            creatorName = request.creatorName
        )
        return ResponseEntity.ok(lobby)
    }
    
    /**
     * Joins a lobby.
     */
    @PostMapping("/{lobbyId}/join")
    fun joinLobby(
        @PathVariable lobbyId: String,
        @RequestBody request: JoinLobbyRequest
    ): ResponseEntity<Lobby> {
        return try {
            val lobby = lobbyService.joinLobby(
                lobbyId = lobbyId,
                playerId = request.playerId,
                playerName = request.playerName
            )
            ResponseEntity.ok(lobby)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.badRequest().build()
        }
    }
    
    /**
     * Leaves a lobby.
     */
    @PostMapping("/{lobbyId}/leave")
    fun leaveLobby(
        @PathVariable lobbyId: String,
        @RequestBody request: LeaveLobbyRequest
    ): ResponseEntity<Lobby> {
        return try {
            val lobby = lobbyService.leaveLobby(
                lobbyId = lobbyId,
                playerId = request.playerId
            )
            ResponseEntity.ok(lobby)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.badRequest().build()
        }
    }
    
    /**
     * Starts a game from a lobby.
     */
    @PostMapping("/{lobbyId}/start")
    fun startGame(@PathVariable lobbyId: String): ResponseEntity<GameState> {
        return try {
            val gameState = lobbyService.startGame(lobbyId)
            ResponseEntity.ok(gameState)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.badRequest().build()
        }
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