package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.config.TimerProperties
import com.jackabee.cribbageclubserver.entity.GameEntity
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.game.TimeControl
import com.jackabee.cribbageclubserver.model.player.Player
import org.junit.jupiter.api.Test
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

/** A clock the test advances by hand, so timing behaviour is verified without sleeping. */
private class MutableClock(var instant: Instant = Instant.parse("2026-01-01T00:00:00Z")) : Clock() {
    override fun getZone(): ZoneId = ZoneOffset.UTC
    override fun withZone(zone: ZoneId): Clock = this
    override fun instant(): Instant = instant

    fun advance(duration: Duration) {
        instant = instant.plus(duration)
    }
}

class TurnTimerServiceTest {

    private val gameId = "game_1"
    private val alice = "p1"
    private val bob = "p2"

    private fun entity(
        timeControl: TimeControl = TimeControl.RAPID,
        currentPlayerId: String? = alice,
        isAIGame: Boolean = false
    ): GameEntity {
        val settings = TimerProperties().resolve(timeControl)
        return GameEntity(
            id = gameId,
            player1Id = alice,
            player1Name = "Alice",
            player2Id = bob,
            player2Name = "Bob",
            currentPlayerId = currentPlayerId,
            isAIGame = isAIGame,
            timeControl = settings.timeControl.name,
            turnTimeLimitMs = settings.turnTimeLimitMs,
            player1TimeBankMs = settings.timeBankMs,
            player2TimeBankMs = settings.timeBankMs
        )
    }

    /** A card each player is holding; only the hand *size* matters to the timer. */
    private fun hand(size: Int): List<Card> =
        Rank.entries.take(size).map { Card(it, Suit.CLUBS) }

    private fun discardState(aliceCards: Int, bobCards: Int, currentPlayerId: String = alice) = GameState(
        gameId = gameId,
        players = listOf(
            Player(alice, "Alice", hand(aliceCards)),
            Player(bob, "Bob", hand(bobCards))
        ),
        currentPlayerId = currentPlayerId,
        stage = GameStage.DISCARDING_TO_CRIB
    )

    private fun peggingState(currentPlayerId: String) = GameState(
        gameId = gameId,
        players = listOf(Player(alice, "Alice", hand(4)), Player(bob, "Bob", hand(4))),
        currentPlayerId = currentPlayerId,
        stage = GameStage.PEGGING
    )

    // ── Charging the right player ─────────────────────────────────────────

    @Test
    fun `charges overage to the acting player, not their opponent`() {
        val clock = MutableClock()
        val service = TurnTimerService(TimerProperties(), clock)
        val entity = entity(currentPlayerId = alice)

        // Both players owe discards, so both clocks start together.
        service.onTurnStart(gameId, entity, discardState(aliceCards = 6, bobCards = 6))

        // Bob dawdles 50s past the 30s limit, then acts. Alice must not be charged.
        clock.advance(Duration.ofSeconds(80))
        service.onActionReceived(gameId, bob, entity)

        assertEquals(120_000, entity.player1TimeBankMs, "Alice's bank should be untouched")
        assertEquals(70_000, entity.player2TimeBankMs, "Bob should be charged 50s of overage")
    }

    @Test
    fun `an opponent's move does not reset a stalling player's clock`() {
        val clock = MutableClock()
        val service = TurnTimerService(TimerProperties(), clock)
        val entity = entity(currentPlayerId = alice)

        service.onTurnStart(gameId, entity, discardState(aliceCards = 6, bobCards = 6))

        // Alice discards promptly at t+5s; Bob has still not moved.
        clock.advance(Duration.ofSeconds(5))
        service.onActionReceived(gameId, alice, entity)
        service.onTurnStart(gameId, entity, discardState(aliceCards = 4, bobCards = 6, currentPlayerId = bob))

        // 40s after the round began, Bob is 10s over — measured from his own start,
        // not from Alice's move.
        clock.advance(Duration.ofSeconds(35))
        service.onActionReceived(gameId, bob, entity)

        assertEquals(120_000, entity.player1TimeBankMs)
        assertEquals(110_000, entity.player2TimeBankMs, "Bob owes 10s, not 5s")
    }

    @Test
    fun `does not charge a player who acts within the turn limit`() {
        val clock = MutableClock()
        val service = TurnTimerService(TimerProperties(), clock)
        val entity = entity()

        service.onTurnStart(gameId, entity, peggingState(alice))
        clock.advance(Duration.ofSeconds(29))
        service.onActionReceived(gameId, alice, entity)

        assertEquals(120_000, entity.player1TimeBankMs)
    }

    @Test
    fun `time bank floors at zero rather than going negative`() {
        val clock = MutableClock()
        val service = TurnTimerService(TimerProperties(), clock)
        val entity = entity()

        service.onTurnStart(gameId, entity, peggingState(alice))
        clock.advance(Duration.ofMinutes(30))
        service.onActionReceived(gameId, alice, entity)

        assertEquals(0, entity.player1TimeBankMs)
    }

    // ── Timeout detection ─────────────────────────────────────────────────

    @Test
    fun `reports no timeout while the bank still has time`() {
        val clock = MutableClock()
        val service = TurnTimerService(TimerProperties(), clock)
        val entity = entity()

        service.onTurnStart(gameId, entity, peggingState(alice))
        clock.advance(Duration.ofSeconds(100))

        assertNull(service.checkTimeout(gameId, entity), "30s limit + 120s bank = 150s")
    }

    @Test
    fun `reports a timeout once the bank is exhausted`() {
        val clock = MutableClock()
        val service = TurnTimerService(TimerProperties(), clock)
        val entity = entity()

        service.onTurnStart(gameId, entity, peggingState(alice))
        clock.advance(Duration.ofSeconds(151))

        assertEquals(alice, service.checkTimeout(gameId, entity))
    }

    @Test
    fun `catches a stalling player who is not the nominal current player`() {
        val clock = MutableClock()
        val service = TurnTimerService(TimerProperties(), clock)
        // Bob is stalling but the engine still names Alice as current player.
        val entity = entity(currentPlayerId = alice)

        service.onTurnStart(gameId, entity, discardState(aliceCards = 6, bobCards = 6))

        // Alice discards; Bob never does.
        clock.advance(Duration.ofSeconds(2))
        service.onActionReceived(gameId, alice, entity)
        service.onTurnStart(gameId, entity, discardState(aliceCards = 4, bobCards = 6, currentPlayerId = alice))

        clock.advance(Duration.ofSeconds(160))

        assertEquals(bob, service.checkTimeout(gameId, entity), "Bob's clock must be checked too")
    }

    @Test
    fun `falls back to the persisted clock when in-memory state is lost`() {
        val clock = MutableClock()
        val service = TurnTimerService(TimerProperties(), clock)
        val entity = entity(currentPlayerId = alice)

        // Simulates a restart: nothing in memory, only what the row carries.
        entity.turnStartedAt = clock.instant().minus(Duration.ofSeconds(200))

        assertEquals(alice, service.checkTimeout(gameId, entity))
    }

    // ── Untimed games ─────────────────────────────────────────────────────

    @Test
    fun `never charges or times out an AI game`() {
        val clock = MutableClock()
        val service = TurnTimerService(TimerProperties(), clock)
        val entity = entity(timeControl = TimeControl.UNLIMITED, isAIGame = true)

        service.onTurnStart(gameId, entity, peggingState(alice))
        clock.advance(Duration.ofHours(3))
        service.onActionReceived(gameId, alice, entity)

        assertNull(service.checkTimeout(gameId, entity))
        assertNull(entity.turnStartedAt)
        assertEquals(false, service.getTimingFields(gameId, entity).isTimed)
    }

    @Test
    fun `never times out an UNLIMITED human game`() {
        val clock = MutableClock()
        val service = TurnTimerService(TimerProperties(), clock)
        val entity = entity(timeControl = TimeControl.UNLIMITED)

        service.onTurnStart(gameId, entity, peggingState(alice))
        clock.advance(Duration.ofHours(3))

        assertNull(service.checkTimeout(gameId, entity))
    }

    // ── Time control wiring ───────────────────────────────────────────────

    @Test
    fun `freezes the resolved preset onto a new game`() {
        val service = TurnTimerService(TimerProperties(), MutableClock())
        val entity = entity()

        service.initializeGame(entity, TimeControl.BLITZ)

        assertEquals("BLITZ", entity.timeControl)
        assertEquals(10_000, entity.turnTimeLimitMs)
        assertEquals(60_000, entity.player1TimeBankMs)
        assertEquals(60_000, entity.player2TimeBankMs)
    }

    @Test
    fun `applies configured overrides when freezing a preset`() {
        val properties = TimerProperties().apply {
            overrides[TimeControl.BLITZ] = TimerProperties.Override().apply {
                turnTimeLimitMs = 15_000
                timeBankMs = 45_000
            }
        }
        val service = TurnTimerService(properties, MutableClock())
        val entity = entity()

        service.initializeGame(entity, TimeControl.BLITZ)

        assertEquals(15_000, entity.turnTimeLimitMs)
        assertEquals(45_000, entity.player1TimeBankMs)
    }

    @Test
    fun `enforces the per-game limit rather than a global constant`() {
        val clock = MutableClock()
        val service = TurnTimerService(TimerProperties(), clock)
        val entity = entity(timeControl = TimeControl.BLITZ)

        service.onTurnStart(gameId, entity, peggingState(alice))

        // 25s is fine under RAPID but 15s over the BLITZ limit.
        clock.advance(Duration.ofSeconds(25))
        service.onActionReceived(gameId, alice, entity)

        assertEquals(45_000, entity.player1TimeBankMs)
    }

    // ── Client-facing timing ──────────────────────────────────────────────

    @Test
    fun `reports the viewer's own clock during a concurrent discard`() {
        val clock = MutableClock()
        val service = TurnTimerService(TimerProperties(), clock)
        val entity = entity(currentPlayerId = alice)

        service.onTurnStart(gameId, entity, discardState(aliceCards = 6, bobCards = 6))
        val roundStart = clock.instant()

        clock.advance(Duration.ofSeconds(10))
        service.onActionReceived(gameId, alice, entity)
        val state = discardState(aliceCards = 4, bobCards = 6, currentPlayerId = bob)
        service.onTurnStart(gameId, entity, state)

        val bobView = service.buildGameResponse(gameId, entity, state, bob)
        assertEquals(roundStart, bobView.turnStartedAt, "Bob's deadline dates from the round start")
        assertEquals(30_000, bobView.turnTimeLimitMs)
        assertEquals("RAPID", bobView.timeControl)
    }

    @Test
    fun `reports each player's own bank as myTimeBankMs`() {
        val service = TurnTimerService(TimerProperties(), MutableClock())
        val entity = entity()
        entity.player1TimeBankMs = 90_000
        entity.player2TimeBankMs = 45_000

        val aliceView = service.buildGameResponse(gameId, entity, peggingState(alice), alice)
        val bobView = service.buildGameResponse(gameId, entity, peggingState(alice), bob)

        assertEquals(90_000, aliceView.myTimeBankMs)
        assertEquals(45_000, aliceView.opponentTimeBankMs)
        assertEquals(45_000, bobView.myTimeBankMs)
        assertEquals(90_000, bobView.opponentTimeBankMs)
    }

    @Test
    fun `stops all clocks when the game ends`() {
        val clock = MutableClock()
        val service = TurnTimerService(TimerProperties(), clock)
        val entity = entity()

        service.onTurnStart(gameId, entity, peggingState(alice))
        assertNotNull(entity.turnStartedAt)

        val over = peggingState(alice).copy(stage = GameStage.GAME_OVER)
        service.onTurnStart(gameId, entity, over)

        assertNull(entity.turnStartedAt)
        assertNull(service.checkTimeout(gameId, entity))
    }
}
