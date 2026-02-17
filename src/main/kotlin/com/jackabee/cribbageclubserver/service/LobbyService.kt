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
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.stereotype.Service
import java.time.Instant
import java.util.concurrent.ConcurrentHashMap
import kotlin.random.Random

@Service
class LobbyService(
    private val gameService: GameService,
    @Autowired(required = false) private val lobbyRepository: LobbyRepository? = null,
    @Autowired(required = false) private val objectMapper: ObjectMapper? = null
) {
    private val logger = LoggerFactory.getLogger(LobbyService::class.java)

    // Fallback in-memory store when no repository is available
    private val lobbies = ConcurrentHashMap<String, Lobby>()

    private val useDb: Boolean get() = lobbyRepository != null && objectMapper != null

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

        if (useDb) {
            saveLobbyEntity(lobby)
        } else {
            lobbies[lobbyId] = lobby
        }
        logger.info("Created lobby {} by {}", lobbyId, creatorName)
        return lobby
    }

    /**
     * Gets a lobby by ID.
     *
     * @param lobbyId The ID of the lobby
     * @return The lobby if found
     */
    fun getLobby(lobbyId: String): Lobby? {
        if (useDb) {
            val entity = lobbyRepository!!.findById(lobbyId).orElse(null) ?: return null
            return toLobby(entity)
        }
        return lobbies[lobbyId]
    }

    /**
     * Lists all lobbies.
     *
     * @return List of all lobbies
     */
    fun listLobbies(): List<Lobby> {
        if (useDb) {
            return lobbyRepository!!.findAll().map { toLobby(it) }
        }
        return lobbies.values.toList()
    }

    /**
     * Lists lobbies that are waiting for players.
     *
     * @return List of lobbies in WAITING status
     */
    fun listWaitingLobbies(): List<Lobby> {
        if (useDb) {
            return lobbyRepository!!.findByStatus(LobbyStatus.WAITING.name).map { toLobby(it) }
        }
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
        val lobby = getLobby(lobbyId) ?: throw IllegalArgumentException("Lobby not found: $lobbyId")
        require(lobby.status == LobbyStatus.WAITING) { "Lobby is not accepting players" }

        val player = LobbyPlayer(playerId, playerName)
        val updatedLobby = lobby.addPlayer(player)

        if (useDb) {
            saveLobbyEntity(updatedLobby)
        } else {
            lobbies[lobbyId] = updatedLobby
        }
        logger.info("Player {} joined lobby {}", playerName, lobbyId)
        return updatedLobby
    }

    /**
     * Starts a game from a lobby.
     *
     * @param lobbyId The ID of the lobby to start
     * @return The game state of the started game
     */
    fun startGame(lobbyId: String): com.jackabee.cribbageclubserver.model.game.GameState {
        val lobby = getLobby(lobbyId) ?: throw IllegalArgumentException("Lobby not found: $lobbyId")
        require(lobby.isReady) { "Lobby is not ready to start" }
        require(lobby.status == LobbyStatus.WAITING) { "Lobby is not in waiting status" }

        // Convert lobby players to game players
        val gamePlayers = lobby.players.map { lobbyPlayer ->
            Player(lobbyPlayer.id, lobbyPlayer.name)
        }

        // Create game using existing GameService
        val gameState = gameService.createGame(gamePlayers)

        // Update lobby status
        val updatedLobby = lobby.startGame(gameState.gameId)
        if (useDb) {
            saveLobbyEntity(updatedLobby)
        } else {
            lobbies[lobbyId] = updatedLobby
        }
        logger.info("Started game {} from lobby {}", gameState.gameId, lobbyId)

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
        val lobby = getLobby(lobbyId) ?: throw IllegalArgumentException("Lobby not found: $lobbyId")
        require(lobby.status == LobbyStatus.WAITING) { "Cannot leave lobby that is not waiting" }

        val updatedLobby = lobby.removePlayer(playerId)

        // Remove lobby if empty
        if (updatedLobby.players.isEmpty()) {
            if (useDb) {
                lobbyRepository!!.deleteById(lobbyId)
            } else {
                lobbies.remove(lobbyId)
            }
            logger.info("Lobby {} removed (empty)", lobbyId)
        } else {
            if (useDb) {
                saveLobbyEntity(updatedLobby)
            } else {
                lobbies[lobbyId] = updatedLobby
            }
        }

        return updatedLobby
    }

    /**
     * Removes lobbies that have been inactive (still WAITING) since before the threshold.
     * Started lobbies (IN_GAME) are also removed if stale.
     *
     * @return The list of removed lobby IDs
     */
    fun removeInactiveLobbies(inactiveThreshold: Instant): List<String> {
        val removed = mutableListOf<String>()

        if (useDb) {
            val allLobbies = lobbyRepository!!.findAll()
            for (entity in allLobbies) {
                if (entity.updatedAt.isBefore(inactiveThreshold)) {
                    lobbyRepository.deleteById(entity.id)
                    removed.add(entity.id)
                }
            }
        } else {
            for ((lobbyId, lobby) in lobbies) {
                if (lobby.createdAt.isBefore(inactiveThreshold)) {
                    lobbies.remove(lobbyId)
                    removed.add(lobbyId)
                }
            }
        }

        if (removed.isNotEmpty()) {
            logger.info("Cleaned up {} inactive lobbies", removed.size)
        }
        return removed
    }

    /**
     * Removes a lobby.
     *
     * @param lobbyId The ID of the lobby to remove
     */
    fun removeLobby(lobbyId: String) {
        if (useDb) {
            lobbyRepository!!.deleteById(lobbyId)
        } else {
            lobbies.remove(lobbyId)
        }
        logger.info("Removed lobby {}", lobbyId)
    }

    private fun saveLobbyEntity(lobby: Lobby) {
        val mapper = objectMapper ?: return
        val repo = lobbyRepository ?: return

        val entity = LobbyEntity(
            id = lobby.id,
            name = lobby.name,
            maxPlayers = lobby.maxPlayers,
            status = lobby.status.name,
            gameId = lobby.gameId,
            createdAt = lobby.createdAt,
            updatedAt = Instant.now(),
            playersJson = mapper.writeValueAsString(lobby.players)
        )
        repo.save(entity)
    }

    private fun toLobby(entity: LobbyEntity): Lobby {
        val mapper = objectMapper!!
        val players: List<LobbyPlayer> = mapper.readValue(entity.playersJson)
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
