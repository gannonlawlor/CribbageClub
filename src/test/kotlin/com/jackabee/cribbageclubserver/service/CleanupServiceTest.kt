package com.jackabee.cribbageclubserver.service

import org.junit.jupiter.api.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

class CleanupServiceTest {

    private val gameService: GameService = mock()
    private val lobbyService: LobbyService = mock()
    private val cleanupService = CleanupService(gameService, lobbyService)

    @Test
    fun `cleanupInactiveResources calls both services`() {
        whenever(gameService.removeInactiveGames(any())).thenReturn(emptyList())
        whenever(lobbyService.removeInactiveLobbies(any())).thenReturn(emptyList())

        cleanupService.cleanupInactiveResources()

        verify(gameService).removeInactiveGames(any())
        verify(lobbyService).removeInactiveLobbies(any())
    }

    @Test
    fun `cleanupInactiveResources handles removed items`() {
        whenever(gameService.removeInactiveGames(any())).thenReturn(listOf("game1", "game2"))
        whenever(lobbyService.removeInactiveLobbies(any())).thenReturn(listOf("lobby1"))

        cleanupService.cleanupInactiveResources()

        verify(gameService).removeInactiveGames(any())
        verify(lobbyService).removeInactiveLobbies(any())
    }
}
