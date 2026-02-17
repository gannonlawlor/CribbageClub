package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.entity.LobbyEntity
import com.jackabee.cribbageclubserver.model.lobby.Lobby
import com.jackabee.cribbageclubserver.model.lobby.LobbyPlayer
import com.jackabee.cribbageclubserver.model.lobby.LobbyStatus
import com.jackabee.cribbageclubserver.model.player.Player
import com.jackabee.cribbageclubserver.repository.LobbyRepository
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import java.time.Instant
import kotlin.random.Random

@Service
class LobbyService(
    private val gameService: GameService,
    private val lobbyRepository: LobbyRepository,
    private val objectMapper: ObjectMapper
) {
    private val logger = LoggerFactory.getLogger(LobbyService::class.java)

    /**
     * Creates a new lobby.
     */
    fun createLobby(name: String, creatorId: String, creatorName: String): Lobby {
        val lobbyId = generateLobbyId()
        val creator = LobbyPlayer(creatorId, creatorName)
        val lobby = Lobby(id = lobbyId, name = name, players = listOf(creator))

        saveLobbyEntity(lobby)
        logger.info("Created lobby {} by {}", lobbyId, creatorName)
        return lobby
    }

    /**
     * Gets a lobby by ID.
     */
    fun getLobby(lobbyId: String): Lobby? {
        val entity = lobbyRepository.findById(lobbyId).orElse(null) ?: return null
        return toLobby(entity)
    }

    /**
     * Lists all lobbies.
     */
    fun listLobbies(): List<Lobby> {
        return lobbyRepository.findAll().map { toLobby(it) }
    }

    /**
     * Lists lobbies that are waiting for players.
     */
    fun listWaitingLobbies(): List<Lobby> {
        return lobbyRepository.findByStatus(LobbyStatus.WAITING.name).map { toLobby(it) }
    }

    /**
     * Joins a player to a lobby.
     */
    fun joinLobby(lobbyId: String, playerId: String, playerName: String): Lobby {
        val lobby = getLobby(lobbyId) ?: throw IllegalArgumentException("Lobby not found: $lobbyId")
        require(lobby.status == LobbyStatus.WAITING) { "Lobby is not accepting players" }

        val player = LobbyPlayer(playerId, playerName)
        val updatedLobby = lobby.addPlayer(player)

        saveLobbyEntity(updatedLobby)
        logger.info("Player {} joined lobby {}", playerName, lobbyId)
        return updatedLobby
    }

    /**
     * Starts a game from a lobby.
     */
    fun startGame(lobbyId: String): com.jackabee.cribbageclubserver.model.game.GameState {
        val lobby = getLobby(lobbyId) ?: throw IllegalArgumentException("Lobby not found: $lobbyId")
        require(lobby.isReady) { "Lobby is not ready to start" }
        require(lobby.status == LobbyStatus.WAITING) { "Lobby is not in waiting status" }

        val gamePlayers = lobby.players.map { lobbyPlayer ->
            Player(lobbyPlayer.id, lobbyPlayer.name)
        }

        val gameState = gameService.createGame(gamePlayers)

        val updatedLobby = lobby.startGame(gameState.gameId)
        saveLobbyEntity(updatedLobby)
        logger.info("Started game {} from lobby {}", gameState.gameId, lobbyId)

        return gameState
    }

    /**
     * Removes a player from a lobby.
     */
    fun leaveLobby(lobbyId: String, playerId: String): Lobby {
        val lobby = getLobby(lobbyId) ?: throw IllegalArgumentException("Lobby not found: $lobbyId")
        require(lobby.status == LobbyStatus.WAITING) { "Cannot leave lobby that is not waiting" }

        val updatedLobby = lobby.removePlayer(playerId)

        if (updatedLobby.players.isEmpty()) {
            lobbyRepository.deleteById(lobbyId)
            logger.info("Lobby {} removed (empty)", lobbyId)
        } else {
            saveLobbyEntity(updatedLobby)
        }

        return updatedLobby
    }

    /**
     * Removes a lobby.
     */
    fun removeLobby(lobbyId: String) {
        lobbyRepository.deleteById(lobbyId)
        logger.info("Removed lobby {}", lobbyId)
    }

    private fun saveLobbyEntity(lobby: Lobby) {
        val entity = LobbyEntity(
            id = lobby.id,
            name = lobby.name,
            maxPlayers = lobby.maxPlayers,
            status = lobby.status.name,
            gameId = lobby.gameId,
            createdAt = lobby.createdAt,
            updatedAt = Instant.now(),
            playersJson = objectMapper.writeValueAsString(lobby.players)
        )
        lobbyRepository.save(entity)
    }

    private fun toLobby(entity: LobbyEntity): Lobby {
        val players: List<LobbyPlayer> = objectMapper.readValue(entity.playersJson)
        return Lobby(
            id = entity.id,
            name = entity.name,
            players = players,
            maxPlayers = entity.maxPlayers,
            status = LobbyStatus.valueOf(entity.status),
            createdAt = entity.createdAt,
            gameId = entity.gameId
        )
    }

    private fun generateLobbyId(): String {
        return "lobby_${System.currentTimeMillis()}_${Random.nextInt(1000, 9999)}"
    }
}
