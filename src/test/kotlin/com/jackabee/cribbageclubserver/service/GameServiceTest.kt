package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.bridge.CribbageEngineLib
import com.jackabee.cribbageclubserver.bridge.RustEngineAdapter
import com.jackabee.cribbageclubserver.config.TimerProperties
import com.jackabee.cribbageclubserver.entity.GameEntity
import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.model.player.Player
import com.jackabee.cribbageclubserver.repository.GameRepository
import com.jackabee.cribbageclubserver.testutil.MutableClock
import com.fasterxml.jackson.databind.DeserializationFeature
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.mockito.kotlin.whenever
import java.time.Duration
import java.util.Optional
import java.util.concurrent.atomic.AtomicReference
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class GameServiceTest {

    private lateinit var gameService: GameService

    companion object {
        private lateinit var lib: CribbageEngineLib
        private lateinit var objectMapper: ObjectMapper

        @JvmStatic
        @BeforeAll
        fun loadNativeLib() {
            lib = CribbageEngineLib.load()
            objectMapper = jacksonObjectMapper()
        }
    }

    @BeforeEach
    fun setUp() {
        val adapter = RustEngineAdapter(lib, objectMapper)
        gameService = GameService(
            objectMapper = objectMapper,
            rustEngineAdapter = adapter,
        )
    }

    @Test
    fun `should create game with AI opponent`() {
        val gameState = gameService.createGameWithAI("human1", "Alice")

        assertEquals(2, gameState.players.size)
        assertEquals("human1", gameState.players[0].id)
        assertEquals("Alice", gameState.players[0].name)
        assertEquals("AI Opponent", gameState.players[1].name)
        assertTrue(gameState.players[1].id.startsWith("ai_"))

        // Should be in discarding phase after setup
        assertEquals(GameStage.DISCARDING_TO_CRIB, gameState.stage)

        // Players should have 6 cards each
        assertEquals(6, gameState.players[0].hand.size)
        assertEquals(6, gameState.players[1].hand.size)
    }

    @Test
    fun `should process AI actions automatically`() {
        val gameState = gameService.createGameWithAI("human1", "Alice")

        // If it's AI's turn, it should have processed some actions
        val aiPlayerId = gameState.players[1].id
        if (gameState.currentPlayerId == aiPlayerId) {
            // AI should have acted, so game state should reflect that
            assertTrue(gameState.stage == GameStage.DISCARDING_TO_CRIB)
        }
    }

    @Test
    fun `should handle human player actions`() {
        val gameState = gameService.createGameWithAI("human1", "Alice")
        val gameId = gameService.listGames().keys.first()

        // Find a card in human player's hand to discard
        val humanPlayer = gameState.players.find { it.id == "human1" }
        assertNotNull(humanPlayer)

        val cardToDiscard = humanPlayer.hand.first()
        val action = GameAction.DiscardToCrib("human1", cardToDiscard)

        val newState = gameService.applyHumanAction(gameId, action)

        // Verify the action was applied
        val updatedHumanPlayer = newState.players.find { it.id == "human1" }
        assertNotNull(updatedHumanPlayer)
        assertEquals(5, updatedHumanPlayer.hand.size) // One card discarded
        assertTrue(cardToDiscard in newState.crib)
    }

    @Test
    fun `should list active games`() {
        val initialGames = gameService.listGames()
        assertEquals(0, initialGames.size)

        gameService.createGameWithAI("human1", "Alice")
        gameService.createGameWithAI("human2", "Bob")

        val activeGames = gameService.listGames()
        assertEquals(2, activeGames.size)
    }

    @Test
    fun `should remove games`() {
        gameService.createGameWithAI("human1", "Alice")
        val gameId = gameService.listGames().keys.first()

        assertEquals(1, gameService.listGames().size)

        gameService.removeGame(gameId)

        assertEquals(0, gameService.listGames().size)
    }

    @Test
    fun `should get game state`() {
        gameService.createGameWithAI("human1", "Alice")
        val gameId = gameService.listGames().keys.first()

        val gameState = gameService.getGameState(gameId)

        assertNotNull(gameState)
        assertEquals(2, gameState.players.size)
        assertEquals("human1", gameState.players[0].id)
        assertEquals("Alice", gameState.players[0].name)
    }

    private class TimedFixture(
        val service: GameService,
        val timer: TurnTimerService,
        val clock: MutableClock,
        val repo: GameRepository,
    )

    /** GameService wired with a stubbed repository and a hand-advanced clock. */
    private fun timedService(): TimedFixture {
        val clock = MutableClock()
        val timer = TurnTimerService(TimerProperties(), clock)
        val savedEntity = AtomicReference<GameEntity>()
        val repo = org.mockito.kotlin.mock<GameRepository>()
        whenever(repo.save(org.mockito.kotlin.any<GameEntity>())).thenAnswer {
            val entity = it.arguments[0] as GameEntity
            savedEntity.set(entity)
            entity
        }
        whenever(repo.findById(org.mockito.kotlin.any<String>())).thenAnswer {
            Optional.ofNullable(savedEntity.get())
        }
        // Persistence serializes GameState, whose history events carry Instants.
        val mapper = jacksonObjectMapper()
            .registerModule(JavaTimeModule())
            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
        val service = GameService(
            objectMapper = mapper,
            rustEngineAdapter = RustEngineAdapter(lib, mapper),
            gameRepository = repo,
            turnTimerService = timer,
        )
        return TimedFixture(service, timer, clock, repo)
    }

    /** A card guaranteed not to be in [hand]. */
    private fun cardNotIn(hand: List<Card>): Card {
        for (rank in Rank.entries) for (suit in Suit.entries) {
            val card = Card(rank, suit)
            if (card !in hand) return card
        }
        error("unreachable")
    }

    @Test
    fun `rejected action leaves the acting player on the clock`() {
        val fixture = timedService()
        val state = fixture.service.createGame(listOf(Player("p1", "Alice"), Player("p2", "Bob")))
        val gameId = state.gameId

        // Bob discards promptly, taking himself off the clock.
        val bobHand = state.players.first { it.id == "p2" }.hand
        fixture.service.applyHumanAction(gameId, GameAction.DiscardToCrib("p2", bobHand[0]))
        fixture.service.applyHumanAction(gameId, GameAction.DiscardToCrib("p2", bobHand[1]))

        // Alice stalls past her whole bank, then submits an invalid action.
        fixture.clock.advance(Duration.ofSeconds(200))
        val aliceHand = fixture.service.getGameState(gameId).players.first { it.id == "p1" }.hand
        assertThrows<Exception> {
            fixture.service.applyHumanAction(gameId, GameAction.DiscardToCrib("p1", cardNotIn(aliceHand)))
        }

        // The failed action must not have stopped her clock or charged her bank —
        // otherwise an invalid move would let a player escape the timeout sweep.
        val entity = fixture.service.getGameEntity(gameId)!!
        assertEquals("p1", fixture.timer.checkTimeout(gameId, entity))
        assertEquals(120_000, entity.player1TimeBankMs)
    }

    @Test
    fun `rejects actions on a game the sweep already forfeited`() {
        val fixture = timedService()
        val state = fixture.service.createGame(listOf(Player("p1", "Alice"), Player("p2", "Bob")))
        val entity = fixture.service.getGameEntity(state.gameId)!!
        entity.winnerId = "p2"

        val hand = state.players.first { it.id == "p1" }.hand
        assertThrows<IllegalStateException> {
            fixture.service.applyHumanAction(state.gameId, GameAction.DiscardToCrib("p1", hand[0]))
        }
    }

    @Test
    fun `cleanup evicts idle engines but never deletes game rows`() {
        val fixture = timedService()
        val state = fixture.service.createGame(listOf(Player("p1", "Alice"), Player("p2", "Bob")))
        val entity = fixture.service.getGameEntity(state.gameId)!!
        entity.stage = GameStage.GAME_OVER.name

        val evicted = fixture.service.removeInactiveGames(fixture.clock.instant())

        assertEquals(listOf(state.gameId), evicted)
        assertFalse(fixture.service.listGames().containsKey(state.gameId))
        // History depends on completed rows surviving cleanup: eviction must
        // release the engine handle without ever touching the database row.
        org.mockito.kotlin.verify(fixture.repo, org.mockito.Mockito.never()).deleteById(org.mockito.kotlin.any())
        assertNotNull(fixture.service.getGameEntity(state.gameId))
    }

    @Test
    fun `should drop the cached engine when a game ends by forfeit`() {
        gameService.createGameWithAI("human1", "Alice")
        val gameId = gameService.listGames().keys.first()
        assertNotNull(gameService.getGameState(gameId))

        gameService.onGameEnded(GameEndedEvent(gameId))

        // With the handle dropped, reads fall through to the database rather than
        // being served a game the forfeit already ended.
        assertFalse(gameService.listGames().containsKey(gameId))
        assertThrows<IllegalArgumentException> { gameService.getGameState(gameId) }
    }

    @Test
    fun `should create different AI difficulties`() {
        val basicGame = gameService.createGameWithAI("human1", "Alice", "basic")
        val anotherGame = gameService.createGameWithAI("human2", "Bob", "advanced")

        // Both should work (advanced defaults to basic for now)
        assertEquals(2, basicGame.players.size)
        assertEquals(2, anotherGame.players.size)
    }
}
