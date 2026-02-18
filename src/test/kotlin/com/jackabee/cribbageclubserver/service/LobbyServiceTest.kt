package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.model.lobby.LobbyStatus
import com.jackabee.cribbageclubserver.repository.LobbyRepository
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

@SpringBootTest
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
    fun `should get lobby from database`() {
        val lobby = lobbyService.createLobby("Get Lobby", "c1", "Alice")

        val fetched = lobbyService.getLobby(lobby.id)
        assertNotNull(fetched)
        assertEquals("Get Lobby", fetched.name)
        assertEquals(1, fetched.players.size)
    }

    @Test
    fun `should list lobbies from database`() {
        val initialCount = lobbyService.listLobbies().size
        lobbyService.createLobby("Lobby A", "c1", "Alice")
        lobbyService.createLobby("Lobby B", "c2", "Bob")

        val lobbies = lobbyService.listLobbies()
        assertEquals(initialCount + 2, lobbies.size)
    }

    @Test
    fun `should list only waiting lobbies`() {
        val initialWaiting = lobbyService.listWaitingLobbies().size
        lobbyService.createLobby("Waiting Lobby", "c1", "Alice")

        val waiting = lobbyService.listWaitingLobbies()
        assertTrue(waiting.size >= initialWaiting + 1)
    }

    @Test
    fun `should join lobby and persist updated state`() {
        val lobby = lobbyService.createLobby("Join Lobby", "c1", "Alice")
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
        val lobby = lobbyService.createLobby("Leave Lobby", "c1", "Alice")
        lobbyService.joinLobby(lobby.id, "p2", "Bob")

        val updated = lobbyService.leaveLobby(lobby.id, "p2")
        assertEquals(1, updated.players.size)
    }

    @Test
    fun `should delete lobby when last player leaves`() {
        val lobby = lobbyService.createLobby("Delete Lobby", "c1", "Alice")
        lobbyService.leaveLobby(lobby.id, "c1")

        val fromDb = lobbyService.getLobby(lobby.id)
        assertNull(fromDb)
    }

    @Test
    fun `should start game from lobby`() {
        val lobby = lobbyService.createLobby("Start Lobby", "c1", "Alice")
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
        val lobby = lobbyService.createLobby("Not Ready Lobby", "c1", "Alice")

        assertThrows<IllegalArgumentException> {
            lobbyService.startGame(lobby.id)
        }
    }

    @Test
    fun `should remove lobby`() {
        val lobby = lobbyService.createLobby("Remove Lobby", "c1", "Alice")
        lobbyService.removeLobby(lobby.id)

        assertNull(lobbyService.getLobby(lobby.id))
    }

    @Test
    fun `should create private lobby with invite code`() {
        val lobby = lobbyService.createLobby("Private Lobby", "c1", "Alice", isPrivate = true)

        assertTrue(lobby.isPrivate)
        assertNotNull(lobby.inviteCode)
        assertTrue(lobby.inviteCode!!.startsWith("CRIB-"))
        assertEquals(9, lobby.inviteCode!!.length) // "CRIB-" + 4 chars
    }

    @Test
    fun `should create public lobby without invite code`() {
        val lobby = lobbyService.createLobby("Public Lobby", "c1", "Alice", isPrivate = false)

        assertFalse(lobby.isPrivate)
        assertNull(lobby.inviteCode)
    }

    @Test
    fun `should not list private lobbies in waiting list`() {
        lobbyService.createLobby("Secret Lobby", "c1", "Alice", isPrivate = true)

        val waiting = lobbyService.listWaitingLobbies()
        assertTrue(waiting.none { it.name == "Secret Lobby" })
    }

    @Test
    fun `should join private lobby by invite code`() {
        val lobby = lobbyService.createLobby("Code Lobby", "c1", "Alice", isPrivate = true)
        val result = lobbyService.joinLobbyByCode(lobby.inviteCode!!, "p2", "Bob")

        assertEquals(2, result.lobby.players.size)
    }

    @Test
    fun `should auto-start game when joining by code fills lobby`() {
        val lobby = lobbyService.createLobby("Auto Start", "c1", "Alice", isPrivate = true)
        val result = lobbyService.joinLobbyByCode(lobby.inviteCode!!, "p2", "Bob")

        assertNotNull(result.gameState)
        assertEquals(LobbyStatus.IN_GAME, result.lobby.status)
        assertNotNull(result.lobby.gameId)
    }

    @Test
    fun `should reject join by invalid invite code`() {
        assertThrows<IllegalArgumentException> {
            lobbyService.joinLobbyByCode("CRIB-ZZZZ", "p2", "Bob")
        }
    }

    @Test
    fun `should persist private lobby fields in database`() {
        val lobby = lobbyService.createLobby("Persist Private", "c1", "Alice", isPrivate = true)

        val fromDb = lobbyService.getLobby(lobby.id)
        assertNotNull(fromDb)
        assertTrue(fromDb.isPrivate)
        assertEquals(lobby.inviteCode, fromDb.inviteCode)
    }
}
