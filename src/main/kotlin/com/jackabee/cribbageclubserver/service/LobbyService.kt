package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.model.lobby.Lobby
import com.jackabee.cribbageclubserver.model.lobby.LobbyPlayer
import com.jackabee.cribbageclubserver.model.lobby.LobbyStatus
import com.jackabee.cribbageclubserver.model.player.Player
import org.springframework.stereotype.Service
import java.util.concurrent.ConcurrentHashMap
import kotlin.random.Random

@Service
class LobbyService(
    private val gameService: GameService
) {
    
    private val lobbies = ConcurrentHashMap<String, Lobby>()
    
    /**
     * Creates a new lobby.
     * 
     * @param name The name of the lobby
     * @param creatorId The ID of the player creating the lobby
     * @param creatorName The name of the player creating the lobby
     * @return The created lobby
     */
    fun createLobby(name: String, creatorId: String, creatorName: String): Lobby {
        val lobbyId = generateLobbyId()
        val creator = LobbyPlayer(creatorId, creatorName)
        val lobby = Lobby(id = lobbyId, name = name, players = listOf(creator))
        
        lobbies[lobbyId] = lobby
        return lobby
    }
    
    /**
     * Gets a lobby by ID.
     * 
     * @param lobbyId The ID of the lobby
     * @return The lobby if found
     */
    fun getLobby(lobbyId: String): Lobby? {
        return lobbies[lobbyId]
    }
    
    /**
     * Lists all lobbies.
     * 
     * @return List of all lobbies
     */
    fun listLobbies(): List<Lobby> {
        return lobbies.values.toList()
    }
    
    /**
     * Lists lobbies that are waiting for players.
     * 
     * @return List of lobbies in WAITING status
     */
    fun listWaitingLobbies(): List<Lobby> {
        return lobbies.values.filter { it.status == LobbyStatus.WAITING }
    }
    
    /**
     * Joins a player to a lobby.
     * 
     * @param lobbyId The ID of the lobby to join
     * @param playerId The ID of the player joining
     * @param playerName The name of the player joining
     * @return The updated lobby
     */
    fun joinLobby(lobbyId: String, playerId: String, playerName: String): Lobby {
        val lobby = lobbies[lobbyId] ?: throw IllegalArgumentException("Lobby not found: $lobbyId")
        require(lobby.status == LobbyStatus.WAITING) { "Lobby is not accepting players" }
        
        val player = LobbyPlayer(playerId, playerName)
        val updatedLobby = lobby.addPlayer(player)
        
        lobbies[lobbyId] = updatedLobby
        return updatedLobby
    }
    
    /**
     * Starts a game from a lobby.
     * 
     * @param lobbyId The ID of the lobby to start
     * @return The game state of the started game
     */
    fun startGame(lobbyId: String): com.jackabee.cribbageclubserver.model.game.GameState {
        val lobby = lobbies[lobbyId] ?: throw IllegalArgumentException("Lobby not found: $lobbyId")
        require(lobby.isReady) { "Lobby is not ready to start" }
        require(lobby.status == LobbyStatus.WAITING) { "Lobby is not in waiting status" }
        
        // Convert lobby players to game players
        val gamePlayers = lobby.players.map { lobbyPlayer ->
            Player(lobbyPlayer.id, lobbyPlayer.name)
        }
        
        // Create game using existing GameService (update it to handle human vs human)
        val gameState = gameService.createGame(gamePlayers)
        
        // Update lobby status
        val updatedLobby = lobby.startGame(gameState.gameId)
        lobbies[lobbyId] = updatedLobby
        
        return gameState
    }
    
    /**
     * Removes a player from a lobby.
     * 
     * @param lobbyId The ID of the lobby
     * @param playerId The ID of the player to remove
     * @return The updated lobby
     */
    fun leaveLobby(lobbyId: String, playerId: String): Lobby {
        val lobby = lobbies[lobbyId] ?: throw IllegalArgumentException("Lobby not found: $lobbyId")
        require(lobby.status == LobbyStatus.WAITING) { "Cannot leave lobby that is not waiting" }
        
        val updatedLobby = lobby.removePlayer(playerId)
        
        // Remove lobby if empty
        if (updatedLobby.players.isEmpty()) {
            lobbies.remove(lobbyId)
        } else {
            lobbies[lobbyId] = updatedLobby
        }
        
        return updatedLobby
    }
    
    /**
     * Removes a lobby.
     * 
     * @param lobbyId The ID of the lobby to remove
     */
    fun removeLobby(lobbyId: String) {
        lobbies.remove(lobbyId)
    }
    
    private fun generateLobbyId(): String {
        return "lobby_${System.currentTimeMillis()}_${Random.nextInt(1000, 9999)}"
    }
}