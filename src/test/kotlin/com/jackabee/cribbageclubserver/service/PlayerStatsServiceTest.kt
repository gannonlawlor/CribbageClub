package com.jackabee.cribbageclubserver.service

import com.fasterxml.jackson.databind.DeserializationFeature
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.jackabee.cribbageclubserver.bridge.CribbageEngineLib
import com.jackabee.cribbageclubserver.bridge.RustEngineAdapter
import com.jackabee.cribbageclubserver.entity.PlayerStatsEntity
import com.jackabee.cribbageclubserver.repository.PlayerStatsRepository
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.mockito.kotlin.*
import java.util.Optional
import kotlin.test.assertEquals

class PlayerStatsServiceTest {

    companion object {
        private lateinit var adapter: RustEngineAdapter

        @JvmStatic
        @BeforeAll
        fun setup() {
            val lib = CribbageEngineLib.load()
            val objectMapper = jacksonObjectMapper()
                .registerModule(JavaTimeModule())
                .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
            adapter = RustEngineAdapter(lib, objectMapper)
        }
    }

    private val repository: PlayerStatsRepository = mock()
    private val service = PlayerStatsService(repository, adapter)

    @Test
    fun `getStats returns existing stats`() {
        val existing = PlayerStatsEntity(playerId = "p1", gamesPlayed = 5, gamesWon = 3)
        whenever(repository.findById("p1")).thenReturn(Optional.of(existing))

        val stats = service.getStats("p1")
        assertEquals(5, stats.gamesPlayed)
        assertEquals(3, stats.gamesWon)
    }

    @Test
    fun `getStats returns empty stats for unknown player`() {
        whenever(repository.findById("unknown")).thenReturn(Optional.empty())

        val stats = service.getStats("unknown")
        assertEquals(0, stats.gamesPlayed)
    }

    @Test
    fun `recordGameResult updates winner and loser stats`() {
        whenever(repository.findById("winner")).thenReturn(Optional.empty())
        whenever(repository.findById("loser")).thenReturn(Optional.empty())
        whenever(repository.save(any<PlayerStatsEntity>())).thenAnswer { it.arguments[0] }

        service.recordGameResult("winner", "loser", 121, 95)

        verify(repository, times(2)).save(argThat<PlayerStatsEntity> {
            when (playerId) {
                "winner" -> {
                    gamesPlayed == 1 && gamesWon == 1 && gamesLost == 0 &&
                        totalPointsScored == 121L && currentWinStreak == 1
                }
                "loser" -> {
                    gamesPlayed == 1 && gamesWon == 0 && gamesLost == 1 &&
                        totalPointsScored == 95L && currentWinStreak == 0
                }
                else -> false
            }
        })
    }

    @Test
    fun `recordGameResult increments win streak`() {
        val existing = PlayerStatsEntity(
            playerId = "p1", gamesPlayed = 2, gamesWon = 2,
            currentWinStreak = 2, longestWinStreak = 2
        )
        whenever(repository.findById("p1")).thenReturn(Optional.of(existing))
        whenever(repository.findById("p2")).thenReturn(Optional.empty())
        whenever(repository.save(any<PlayerStatsEntity>())).thenAnswer { it.arguments[0] }

        service.recordGameResult("p1", "p2", 121, 100)

        verify(repository).save(argThat<PlayerStatsEntity> {
            playerId == "p1" && currentWinStreak == 3 && longestWinStreak == 3
        })
    }

    @Test
    fun `recordGameResult resets loser win streak`() {
        val existing = PlayerStatsEntity(
            playerId = "p2", gamesPlayed = 3, gamesWon = 3,
            currentWinStreak = 3, longestWinStreak = 3
        )
        whenever(repository.findById("winner")).thenReturn(Optional.empty())
        whenever(repository.findById("p2")).thenReturn(Optional.of(existing))
        whenever(repository.save(any<PlayerStatsEntity>())).thenAnswer { it.arguments[0] }

        service.recordGameResult("winner", "p2", 121, 80)

        verify(repository).save(argThat<PlayerStatsEntity> {
            playerId == "p2" && currentWinStreak == 0 && longestWinStreak == 3
        })
    }

    @Test
    fun `getLeaderboard delegates to repository`() {
        val leaders = listOf(
            PlayerStatsEntity(playerId = "p1", gamesWon = 10),
            PlayerStatsEntity(playerId = "p2", gamesWon = 8)
        )
        whenever(repository.findTop10ExcludingPrefixes("ai_%", "guest_%")).thenReturn(leaders)

        val result = service.getLeaderboard()
        assertEquals(2, result.size)
        assertEquals("p1", result[0].playerId)
    }
}
