package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.config.BotProperties
import com.jackabee.cribbageclubserver.entity.GameEntity
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.repository.GameRepository
import org.junit.jupiter.api.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever
import org.springframework.scheduling.TaskScheduler
import java.time.Instant
import java.util.Optional
import java.util.concurrent.ScheduledFuture
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class BotMoveServiceTest {

    /** Captures scheduled runnables so tests fire them by hand. */
    private class FakeScheduler {
        val tasks = mutableListOf<Runnable>()
        val scheduler: TaskScheduler = mock<TaskScheduler>().also {
            whenever(it.schedule(any<Runnable>(), any<Instant>())).thenAnswer { invocation ->
                tasks.add(invocation.arguments[0] as Runnable)
                mock<ScheduledFuture<*>>()
            }
        }

        fun runNext() {
            val task = tasks.removeAt(0)
            task.run()
        }
    }

    private fun gameEntity(id: String = "game_1") = GameEntity(
        id = id,
        player1Id = "human1", player1Name = "Alice",
        player2Id = "bot1", player2Name = "Sam",
        stage = GameStage.PEGGING.name,
        botPlayerId = "bot1", botDifficulty = "basic",
        timeControl = "RAPID", turnTimeLimitMs = 30_000,
    )

    private class Fixture(
        val service: BotMoveService,
        val gameService: GameService,
        val scheduler: FakeScheduler,
        val props: BotProperties,
    )

    private fun fixture(enabled: Boolean = true): Fixture {
        val gameService = mock<GameService>()
        val gameRepository = mock<GameRepository>()
        whenever(gameRepository.findById(any<String>())).thenReturn(Optional.of(gameEntity()))
        val props = BotProperties().apply { this.enabled = enabled }
        val scheduler = FakeScheduler()
        val service = BotMoveService(gameService, gameRepository, props, scheduler.scheduler)
        return Fixture(service, gameService, scheduler, props)
    }

    @Test
    fun `schedules a single move per game across event and sweep`() {
        val fixture = fixture()

        fixture.service.maybeSchedule("game_1")
        fixture.service.onBotActionPending(BotActionPendingEvent("game_1"))
        fixture.service.maybeSchedule("game_1")

        assertEquals(1, fixture.scheduler.tasks.size)
    }

    @Test
    fun `chains the next step while the bot still owes an action`() {
        val fixture = fixture()
        whenever(fixture.gameService.advanceBotGame("game_1"))
            .thenReturn(BotStepResult(botStillPending = true))
            .thenReturn(BotStepResult(botStillPending = false))

        fixture.service.maybeSchedule("game_1")
        fixture.scheduler.runNext()

        // First step reported another pending action -> a second was queued.
        assertEquals(1, fixture.scheduler.tasks.size)
        fixture.scheduler.runNext()
        assertEquals(0, fixture.scheduler.tasks.size)
    }

    @Test
    fun `a failed move never escapes and leaves the game reschedulable`() {
        val fixture = fixture()
        whenever(fixture.gameService.advanceBotGame("game_1"))
            .thenThrow(RuntimeException("optimistic lock"))

        fixture.service.maybeSchedule("game_1")
        fixture.scheduler.runNext() // must not throw

        // The pending entry was cleared, so the sweep can retry.
        fixture.service.maybeSchedule("game_1")
        assertEquals(1, fixture.scheduler.tasks.size)
    }

    @Test
    fun `does nothing when disabled`() {
        val fixture = fixture(enabled = false)

        fixture.service.maybeSchedule("game_1")
        fixture.service.sweep()

        assertEquals(0, fixture.scheduler.tasks.size)
        verify(fixture.gameService, never()).advanceBotGame(any())
    }

    @Test
    fun `sweep schedules moves for active bot games`() {
        val gameService = mock<GameService>()
        val gameRepository = mock<GameRepository>()
        whenever(gameRepository.findActiveBotGames())
            .thenReturn(listOf(gameEntity("game_1"), gameEntity("game_2")))
        whenever(gameRepository.findById(any<String>())).thenReturn(Optional.of(gameEntity()))
        val scheduler = FakeScheduler()
        val service = BotMoveService(gameService, gameRepository, BotProperties(), scheduler.scheduler)

        service.sweep()
        service.sweep() // second sweep must not double-schedule

        assertEquals(2, scheduler.tasks.size)
    }

    @Test
    fun `timed delays never exceed half the turn limit`() {
        val props = BotProperties()
        repeat(200) {
            // BLITZ: 10s turns -> every stage's delay capped at 5s.
            val delay = props.pickDelayMs(GameStage.DISCARDING_TO_CRIB, 10_000)
            assertTrue(delay <= 5_000, "delay $delay exceeded cap")
        }
    }

    @Test
    fun `untimed delays use the stage's full range`() {
        val props = BotProperties()
        val delays = (1..200).map { props.pickDelayMs(GameStage.DISCARDING_TO_CRIB, null) }
        assertTrue(delays.all { it in 3_000..8_000 })
        // The range must actually be used — an uncapped discard can exceed 5s.
        assertTrue(delays.any { it > 5_000 })
    }
}
