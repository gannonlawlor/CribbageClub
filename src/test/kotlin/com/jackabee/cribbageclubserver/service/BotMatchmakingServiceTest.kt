package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.config.BotProperties
import com.jackabee.cribbageclubserver.entity.GameEntity
import com.jackabee.cribbageclubserver.entity.LobbyEntity
import com.jackabee.cribbageclubserver.entity.PlayerStatsEntity
import com.jackabee.cribbageclubserver.entity.UserEntity
import com.jackabee.cribbageclubserver.model.lobby.Lobby
import com.jackabee.cribbageclubserver.model.lobby.LobbyPlayer
import com.jackabee.cribbageclubserver.repository.GameRepository
import com.jackabee.cribbageclubserver.repository.LobbyRepository
import com.jackabee.cribbageclubserver.repository.PlayerStatsRepository
import com.jackabee.cribbageclubserver.repository.UserRepository
import com.jackabee.cribbageclubserver.websocket.WebSocketSessionRegistry
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.eq
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever
import java.time.Instant
import java.util.Optional
import kotlin.test.assertTrue

class BotMatchmakingServiceTest {

    private val lobbyService = mock<LobbyService>()
    private val lobbyRepository = mock<LobbyRepository>()
    private val userRepository = mock<UserRepository>()
    private val playerStatsRepository = mock<PlayerStatsRepository>()
    private val gameRepository = mock<GameRepository>()
    private val sessionRegistry = mock<WebSocketSessionRegistry>()
    private val props = BotProperties()
    private val mapper: ObjectMapper = jacksonObjectMapper().registerModule(JavaTimeModule())

    private lateinit var service: BotMatchmakingService

    @BeforeEach
    fun setUp() {
        service = BotMatchmakingService(
            lobbyService, lobbyRepository, userRepository, playerStatsRepository,
            gameRepository, sessionRegistry, props, mapper,
        )
    }

    private fun bot(id: String, username: String, rating: Double): UserEntity {
        whenever(playerStatsRepository.findById(id))
            .thenReturn(Optional.of(PlayerStatsEntity(playerId = id, rating = rating)))
        return UserEntity(id = id, username = username, isBot = true, botDifficulty = "basic")
    }

    private fun waitingLobby(
        id: String = "lobby_1",
        waiterId: String = "u1",
        ageSeconds: Long = 120,
        isQuickMatch: Boolean = true,
        players: List<LobbyPlayer> = listOf(LobbyPlayer(waiterId, "Alice")),
    ) = LobbyEntity(
        id = id,
        name = "Quick Game",
        status = "WAITING",
        createdAt = Instant.now().minusSeconds(ageSeconds),
        playersJson = mapper.writeValueAsString(players),
        timeControl = "RAPID",
        isQuickMatch = isQuickMatch,
    )

    private fun stubLobbies(vararg lobbies: LobbyEntity) {
        whenever(lobbyRepository.findByStatusAndIsPrivateFalseAndChallengedUserIdIsNull("WAITING"))
            .thenReturn(lobbies.toList())
    }

    private fun stubJoinSucceeds() {
        whenever(lobbyService.joinLobbyById(any(), any(), any()))
            .thenReturn(LobbyService.JoinByCodeResult(lobby = Lobby(id = "lobby_1", name = "Quick Game")))
    }

    @Test
    fun `fills a stale quick-match lobby with a closely rated bot`() {
        stubLobbies(waitingLobby())
        whenever(sessionRegistry.isUserOnline("u1")).thenReturn(true)
        whenever(playerStatsRepository.findById("u1"))
            .thenReturn(Optional.of(PlayerStatsEntity(playerId = "u1", rating = 1200.0)))
        val bots = listOf(
            bot("b1", "mollyq", 1160.0),
            bot("b2", "tom_59", 1210.0),
            bot("b3", "lindad", 1250.0),
            bot("b4", "vpatel88", 1800.0),
            bot("b5", "the_cut_card", 1940.0),
        )
        whenever(userRepository.findByIsBotTrue()).thenReturn(bots)
        stubJoinSucceeds()

        service.sweep()

        // Chosen randomly among the closest few — never the far-off hard bots.
        val botId = argumentCaptor<String>()
        verify(lobbyService).joinLobbyById(eq("lobby_1"), botId.capture(), any())
        assertTrue(botId.firstValue in setOf("b1", "b2", "b3"))
    }

    @Test
    fun `leaves young lobbies for humans`() {
        stubLobbies(waitingLobby(ageSeconds = 5))

        service.sweep()

        verify(lobbyService, never()).joinLobbyById(any(), any(), any())
    }

    @Test
    fun `never fills user-created public lobbies`() {
        stubLobbies(waitingLobby(isQuickMatch = false))

        service.sweep()

        verify(lobbyService, never()).joinLobbyById(any(), any(), any())
    }

    @Test
    fun `skips offline waiters`() {
        // Matching an absent player would start their clock and cost them a rated game.
        stubLobbies(waitingLobby())
        whenever(sessionRegistry.isUserOnline("u1")).thenReturn(false)

        service.sweep()

        verify(lobbyService, never()).joinLobbyById(any(), any(), any())
    }

    @Test
    fun `skips lobbies that are no longer single-player`() {
        stubLobbies(waitingLobby(players = listOf(LobbyPlayer("u1", "Alice"), LobbyPlayer("u2", "Bob"))))
        service.sweep()
        verify(lobbyService, never()).joinLobbyById(any(), any(), any())
    }

    @Test
    fun `excludes bots already playing the waiter`() {
        stubLobbies(waitingLobby())
        whenever(sessionRegistry.isUserOnline("u1")).thenReturn(true)
        val bots = listOf(
            bot("b1", "mollyq", 1500.0),
            bot("b2", "tom_59", 1100.0),
        )
        whenever(userRepository.findByIsBotTrue()).thenReturn(bots)
        // b1 is already mid-game with the waiter, despite being the closer match.
        whenever(gameRepository.findActiveGamesByPlayer("u1")).thenReturn(listOf(
            GameEntity(
                id = "game_1",
                player1Id = "u1", player1Name = "Alice",
                player2Id = "b1", player2Name = "Molly Quinn",
            )
        ))
        stubJoinSucceeds()

        service.sweep()

        verify(lobbyService).joinLobbyById(eq("lobby_1"), eq("b2"), any())
    }

    @Test
    fun `a failed join is contained and later lobbies still fill`() {
        val first = waitingLobby(id = "lobby_1", waiterId = "u1")
        val second = waitingLobby(id = "lobby_2", waiterId = "u2", players = listOf(LobbyPlayer("u2", "Bob")))
        stubLobbies(first, second)
        whenever(sessionRegistry.isUserOnline(any())).thenReturn(true)
        val bots = listOf(bot("b1", "mollyq", 1500.0))
        whenever(userRepository.findByIsBotTrue()).thenReturn(bots)
        // A human won the race on lobby_1 — the bot's join throws.
        whenever(lobbyService.joinLobbyById(eq("lobby_1"), any(), any()))
            .thenThrow(IllegalStateException("Lobby is not accepting players"))
        whenever(lobbyService.joinLobbyById(eq("lobby_2"), any(), any()))
            .thenReturn(LobbyService.JoinByCodeResult(lobby = Lobby(id = "lobby_2", name = "Quick Game")))

        service.sweep() // must not throw

        verify(lobbyService).joinLobbyById(eq("lobby_2"), eq("b1"), any())
    }

    @Test
    fun `does nothing when disabled`() {
        props.enabled = false
        stubLobbies(waitingLobby())

        service.sweep()

        verify(lobbyService, never()).joinLobbyById(any(), any(), any())
    }
}
