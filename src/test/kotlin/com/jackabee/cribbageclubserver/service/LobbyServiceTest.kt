package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.model.lobby.LobbyStatus
import com.jackabee.cribbageclubserver.repository.GameRepository
import com.jackabee.cribbageclubserver.repository.LobbyRepository
import com.fasterxml.jackson.databind.ObjectMapper
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest
import org.springframework.context.annotation.Import
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

@DataJpaTest
@Import(LobbyService::class, GameService::class, ObjectMapper::class)
class LobbyServiceTest {

    @Autowired
    private lateinit var lobbyService: LobbyService

    @Autowired
    private lateinit var lobbyRepository: LobbyRepository

    @Test
    fun `should create lobby and persist to database`() {
        val lobby = lobbyService.createLobby("Test Lobby", "creator1", "Alice")

        assertNotNull(lobby.id)
        assertEquals("Test Lobby", lobby.name)
        assertEquals(1, lobby.players.size)
        assertEquals("creator1", lobby.players[0].id)

        // Verify in database
        val entity = lobbyRepository.findById(lobby.id)
        assertTrue(entity.isPresent)
        assertEquals("Test Lobby", entity.get().name)
        assertEquals("WAITING", entity.get().status)
    }

    @Test
    fun `should list lobbies from database`() {
        lobbyService.createLobby("Lobby 1", "c1", "Alice")
        lobbyService.createLobby("Lobby 2", "c2", "Bob")

        val lobbies = lobbyService.listLobbies()
        assertEquals(2, lobbies.size)
    }

    @Test
    fun `should list only waiting lobbies`() {
        lobbyService.createLobby("Lobby 1", "c1", "Alice")
        lobbyService.createLobby("Lobby 2", "c2", "Bob")

        val waiting = lobbyService.listWaitingLobbies()
        assertEquals(2, waiting.size)
    }

    @Test
    fun `should join lobby and persist updated state`() {
        val lobby = lobbyService.createLobby("Test Lobby", "c1", "Alice")
        val updated = lobbyService.joinLobby(lobby.id, "p2", "Bob")

        assertEquals(2, updated.players.size)
        assertEquals("p2", updated.players[1].id)

        // Verify via fresh read from DB
        val fromDb = lobbyService.getLobby(lobby.id)
        assertNotNull(fromDb)
        assertEquals(2, fromDb.players.size)
    }

    @Test
    fun `should leave lobby and persist`() {
        val lobby = lobbyService.createLobby("Test Lobby", "c1", "Alice")
        lobbyService.joinLobby(lobby.id, "p2", "Bob")

        val updated = lobbyService.leaveLobby(lobby.id, "p2")
        assertEquals(1, updated.players.size)
    }

    @Test
    fun `should delete lobby when last player leaves`() {
        val lobby = lobbyService.createLobby("Test Lobby", "c1", "Alice")
        lobbyService.leaveLobby(lobby.id, "c1")

        val fromDb = lobbyService.getLobby(lobby.id)
        assertNull(fromDb)
    }

    @Test
    fun `should start game from lobby`() {
        val lobby = lobbyService.createLobby("Test Lobby", "c1", "Alice")
        lobbyService.joinLobby(lobby.id, "p2", "Bob")

        val gameState = lobbyService.startGame(lobby.id)

        assertNotNull(gameState.gameId)
        assertEquals(2, gameState.players.size)

        // Lobby should be IN_GAME status
        val updatedLobby = lobbyService.getLobby(lobby.id)
        assertNotNull(updatedLobby)
        assertEquals(LobbyStatus.IN_GAME, updatedLobby.status)
        assertEquals(gameState.gameId, updatedLobby.gameId)
    }

    @Test
    fun `should not start game from lobby that is not ready`() {
        val lobby = lobbyService.createLobby("Test Lobby", "c1", "Alice")

        assertThrows<IllegalArgumentException> {
            lobbyService.startGame(lobby.id)
        }
    }

    @Test
    fun `should remove lobby`() {
        val lobby = lobbyService.createLobby("Test Lobby", "c1", "Alice")
        lobbyService.removeLobby(lobby.id)

        assertNull(lobbyService.getLobby(lobby.id))
    }
}
