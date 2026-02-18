package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.entity.LobbyEntity
import com.jackabee.cribbageclubserver.model.lobby.Lobby
import com.jackabee.cribbageclubserver.model.lobby.LobbyPlayer
import com.jackabee.cribbageclubserver.model.lobby.LobbyStatus
import com.jackabee.cribbageclubserver.model.player.Player
import com.jackabee.cribbageclubserver.repository.LobbyRepository
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue
import org.springframework.transaction.annotation.Transactional
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

    companion object {
        private const val INVITE_CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        private const val INVITE_CODE_LENGTH = 4
    }

    /**
     * Creates a new lobby.
     *
     * @param name The name of the lobby
     * @param creatorId The ID of the player creating the lobby
     * @param creatorName The name of the player creating the lobby
     * @param isPrivate Whether the lobby is private (invite-only)
     * @return The created lobby
     */
    fun createLobby(name: String, creatorId: String, creatorName: String, isPrivate: Boolean = false): Lobby {
        val lobbyId = generateLobbyId()
        val creator = LobbyPlayer(creatorId, creatorName)
        val inviteCode = if (isPrivate) generateInviteCode() else null
        val lobby = Lobby(
            id = lobbyId,
            name = name,
            players = listOf(creator),
            isPrivate = isPrivate,
            inviteCode = inviteCode
        )

        saveLobbyEntity(lobby)
        logger.info("Created {} lobby {} by {}", if (isPrivate) "private" else "public", lobbyId, creatorName)
        return lobby
    }

    /**
     * Gets a lobby by ID.
     *
     * @param lobbyId The ID of the lobby
     * @return The lobby if found
     */
    fun getLobby(lobbyId: String): Lobby? {
        val entity = lobbyRepository.findById(lobbyId).orElse(null) ?: return null
        return toLobby(entity)
    }

    /**
     * Lists all lobbies.
     *
     * @return List of all lobbies
     */
    fun listLobbies(): List<Lobby> {
        return lobbyRepository.findAll().map { toLobby(it) }
    }

    /**
     * Lists public lobbies that are waiting for players.
     *
     * @return List of public lobbies in WAITING status
     */
    fun listWaitingLobbies(): List<Lobby> {
        return lobbyRepository.findByStatusAndIsPrivateFalse(LobbyStatus.WAITING.name).map { toLobby(it) }
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

        saveLobbyEntity(updatedLobby)
        logger.info("Player {} joined lobby {}", playerName, lobbyId)
        return updatedLobby
    }

    /**
     * Joins a player to a private lobby by invite code and auto-starts if full.
     *
     * @param inviteCode The invite code for the private lobby
     * @param playerId The ID of the player joining
     * @param playerName The name of the player joining
     * @return The game state if auto-started, or the updated lobby
     */
    @Transactional
    fun joinLobbyByCode(inviteCode: String, playerId: String, playerName: String): JoinByCodeResult {
        val entity = lobbyRepository.findByInviteCode(inviteCode.uppercase())
            ?: throw IllegalArgumentException("Invalid invite code")
        val lobby = toLobby(entity)
        require(lobby.status == LobbyStatus.WAITING) { "Lobby is not accepting players" }

        val player = LobbyPlayer(playerId, playerName)
        val updatedLobby = lobby.addPlayer(player)
        saveLobbyEntity(updatedLobby)

        // Auto-start if full
        if (updatedLobby.isReady) {
            val gamePlayers = updatedLobby.players.map { Player(it.id, it.name) }
            val gameState = gameService.createGame(gamePlayers)
            val startedLobby = updatedLobby.startGame(gameState.gameId)
            saveLobbyEntity(startedLobby)
            logger.info("Auto-started game {} from private lobby {}", gameState.gameId, lobby.id)
            return JoinByCodeResult(lobby = startedLobby, gameState = gameState)
        }

        return JoinByCodeResult(lobby = updatedLobby)
    }

    /**
     * Starts a game from a lobby.
     *
     * @param lobbyId The ID of the lobby to start
     * @return The game state of the started game
     */
    @Transactional
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
        saveLobbyEntity(updatedLobby)
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
            lobbyRepository.deleteById(lobbyId)
            logger.info("Lobby {} removed (empty)", lobbyId)
        } else {
            saveLobbyEntity(updatedLobby)
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

        val allLobbies = lobbyRepository.findAll()
        for (entity in allLobbies) {
            if (entity.updatedAt.isBefore(inactiveThreshold)) {
                lobbyRepository.deleteById(entity.id)
                removed.add(entity.id)
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
        lobbyRepository.deleteById(lobbyId)
        logger.info("Removed lobby {}", lobbyId)
    }

    /**
     * Creates a challenge lobby (private lobby with challengedUserId).
     */
    fun createChallenge(challengerId: String, challengerName: String, challengedUserId: String): Lobby {
        val lobbyId = generateLobbyId()
        val creator = LobbyPlayer(challengerId, challengerName)
        val inviteCode = generateInviteCode()
        val lobby = Lobby(
            id = lobbyId,
            name = "$challengerName's Challenge",
            players = listOf(creator),
            isPrivate = true,
            inviteCode = inviteCode,
            challengedUserId = challengedUserId
        )

        saveLobbyEntity(lobby)
        logger.info("Created challenge lobby {} from {} to {}", lobbyId, challengerId, challengedUserId)
        return lobby
    }

    /**
     * Gets pending challenges for a user.
     */
    fun getPendingChallengesForUser(userId: String): List<Lobby> {
        return lobbyRepository.findByChallengedUserIdAndStatus(userId, LobbyStatus.WAITING.name)
            .map { toLobby(it) }
    }

    /**
     * Joins a lobby by ID and auto-starts if full (used for accepting challenges).
     */
    @Transactional
    fun joinLobbyById(lobbyId: String, playerId: String, playerName: String): JoinByCodeResult {
        val entity = lobbyRepository.findById(lobbyId).orElseThrow {
            IllegalArgumentException("Lobby not found: $lobbyId")
        }
        val lobby = toLobby(entity)
        require(lobby.status == LobbyStatus.WAITING) { "Lobby is not accepting players" }

        val player = LobbyPlayer(playerId, playerName)
        val updatedLobby = lobby.addPlayer(player)
        saveLobbyEntity(updatedLobby)

        // Auto-start if full
        if (updatedLobby.isReady) {
            val gamePlayers = updatedLobby.players.map { Player(it.id, it.name) }
            val gameState = gameService.createGame(gamePlayers)
            val startedLobby = updatedLobby.startGame(gameState.gameId)
            saveLobbyEntity(startedLobby)
            logger.info("Auto-started game {} from lobby {}", gameState.gameId, lobbyId)
            return JoinByCodeResult(lobby = startedLobby, gameState = gameState)
        }

        return JoinByCodeResult(lobby = updatedLobby)
    }

    private fun saveLobbyEntity(lobby: Lobby) {
        val existing = lobbyRepository.findById(lobby.id).orElse(null)
        if (existing != null) {
            existing.status = lobby.status.name
            existing.gameId = lobby.gameId
            existing.updatedAt = Instant.now()
            existing.playersJson = objectMapper.writeValueAsString(lobby.players)
            lobbyRepository.save(existing)
        } else {
            val entity = LobbyEntity(
                id = lobby.id,
                name = lobby.name,
                maxPlayers = lobby.maxPlayers,
                status = lobby.status.name,
                gameId = lobby.gameId,
                isPrivate = lobby.isPrivate,
                inviteCode = lobby.inviteCode,
                challengedUserId = lobby.challengedUserId,
                createdAt = lobby.createdAt,
                updatedAt = Instant.now(),
                playersJson = objectMapper.writeValueAsString(lobby.players)
            )
            lobbyRepository.save(entity)
        }
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
            gameId = entity.gameId,
            isPrivate = entity.isPrivate,
            inviteCode = entity.inviteCode,
            challengedUserId = entity.challengedUserId
        )
    }

    private fun generateLobbyId(): String {
        return "lobby_${System.currentTimeMillis()}_${Random.nextInt(1000, 9999)}"
    }

    private fun generateInviteCode(): String {
        repeat(10) {
            val code = "CRIB-" + (1..INVITE_CODE_LENGTH)
                .map { INVITE_CODE_CHARS[Random.nextInt(INVITE_CODE_CHARS.length)] }
                .joinToString("")
            if (lobbyRepository.findByInviteCode(code) == null) {
                return code
            }
        }
        throw IllegalStateException("Failed to generate unique invite code")
    }

    data class JoinByCodeResult(
        val lobby: Lobby,
        val gameState: com.jackabee.cribbageclubserver.model.game.GameState? = null
    )
}
