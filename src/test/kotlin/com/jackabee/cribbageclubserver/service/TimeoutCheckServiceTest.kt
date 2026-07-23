package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.entity.GameEntity
import com.jackabee.cribbageclubserver.model.action.ForfeitReason
import com.jackabee.cribbageclubserver.repository.GameRepository
import org.junit.jupiter.api.Test
import org.mockito.Mockito.mock
import org.mockito.Mockito.never
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import org.mockito.kotlin.any
import org.mockito.kotlin.eq

class TimeoutCheckServiceTest {

    private fun entity(id: String) = GameEntity(
        id = id,
        player1Id = "p1",
        player1Name = "Alice",
        player2Id = "p2",
        player2Name = "Bob",
        currentPlayerId = "p1"
    )

    @Test
    fun `forfeits the player the timer reports as out of time`() {
        val repository = mock(GameRepository::class.java)
        val timer = mock(TurnTimerService::class.java)
        val forfeit = mock(ForfeitService::class.java)
        val game = entity("game_1")

        `when`(repository.findActiveTimedGames()).thenReturn(listOf(game))
        `when`(timer.checkTimeout("game_1", game)).thenReturn("p1")

        TimeoutCheckService(repository, timer, forfeit).checkTimeouts()

        verify(forfeit).forfeitGame("game_1", "p1", ForfeitReason.TIMEOUT)
    }

    @Test
    fun `leaves games alone when nobody is out of time`() {
        val repository = mock(GameRepository::class.java)
        val timer = mock(TurnTimerService::class.java)
        val forfeit = mock(ForfeitService::class.java)
        val game = entity("game_1")

        `when`(repository.findActiveTimedGames()).thenReturn(listOf(game))
        `when`(timer.checkTimeout("game_1", game)).thenReturn(null)

        TimeoutCheckService(repository, timer, forfeit).checkTimeouts()

        verify(forfeit, never()).forfeitGame(any(), any(), any())
    }

    @Test
    fun `keeps sweeping after one game throws`() {
        val repository = mock(GameRepository::class.java)
        val timer = mock(TurnTimerService::class.java)
        val forfeit = mock(ForfeitService::class.java)
        val broken = entity("broken")
        val healthy = entity("healthy")

        `when`(repository.findActiveTimedGames()).thenReturn(listOf(broken, healthy))
        `when`(timer.checkTimeout("broken", broken)).thenThrow(RuntimeException("boom"))
        `when`(timer.checkTimeout("healthy", healthy)).thenReturn("p2")

        TimeoutCheckService(repository, timer, forfeit).checkTimeouts()

        verify(forfeit).forfeitGame(eq("healthy"), eq("p2"), eq(ForfeitReason.TIMEOUT))
    }
}
