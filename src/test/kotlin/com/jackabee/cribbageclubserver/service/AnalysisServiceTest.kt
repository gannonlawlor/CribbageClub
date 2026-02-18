package com.jackabee.cribbageclubserver.service

import com.fasterxml.jackson.databind.DeserializationFeature
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.jackabee.cribbageclubserver.bridge.CribbageEngineLib
import com.jackabee.cribbageclubserver.bridge.RustEngineAdapter
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit
import com.jackabee.cribbageclubserver.model.game.GameHistoryEvent
import com.jackabee.cribbageclubserver.model.game.GameHistoryEvent.ScoreBreakdown
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.player.Player
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class AnalysisServiceTest {

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

    private val gameService = mock(GameService::class.java)
    private val analysisService = AnalysisService(gameService, adapter)

    private val p1 = "player1"
    private val p2 = "player2"

    // 6-card dealt hands
    private val p1DealtHand = listOf(
        Card(Rank.ACE, Suit.HEARTS),
        Card(Rank.TWO, Suit.HEARTS),
        Card(Rank.THREE, Suit.HEARTS),
        Card(Rank.FOUR, Suit.HEARTS),
        Card(Rank.FIVE, Suit.HEARTS),
        Card(Rank.SIX, Suit.HEARTS)
    )
    private val p2DealtHand = listOf(
        Card(Rank.SEVEN, Suit.CLUBS),
        Card(Rank.EIGHT, Suit.CLUBS),
        Card(Rank.NINE, Suit.CLUBS),
        Card(Rank.TEN, Suit.CLUBS),
        Card(Rank.JACK, Suit.CLUBS),
        Card(Rank.QUEEN, Suit.CLUBS)
    )

    // 4-card kept hands (discarded last 2)
    private val p1KeptHand = p1DealtHand.take(4)
    private val p2KeptHand = p2DealtHand.take(4)

    private val cutCard = Card(Rank.KING, Suit.SPADES)

    private fun buildSingleRoundHistory(): List<GameHistoryEvent> = listOf(
        GameHistoryEvent.RoundStarted(roundNumber = 1),
        GameHistoryEvent.CardsDealt(dealtHands = mapOf(p1 to p1DealtHand, p2 to p2DealtHand)),
        GameHistoryEvent.DeckCut(cutCard = cutCard, cuttingPlayerId = p1, dealerScoredNobs = false),
        // Pegging events omitted for brevity
        GameHistoryEvent.PeggingEnded(),
        GameHistoryEvent.HandCounted(
            playerId = p1,
            hand = p1KeptHand,
            totalPoints = 7,
            scoreBreakdown = ScoreBreakdown(fifteens = 2, pairs = 0, runs = 5)
        ),
        GameHistoryEvent.HandCounted(
            playerId = p2,
            hand = p2KeptHand,
            totalPoints = 4,
            scoreBreakdown = ScoreBreakdown(runs = 4)
        ),
        GameHistoryEvent.CribCounted(
            dealerPlayerId = p2,
            totalPoints = 2,
            scoreBreakdown = ScoreBreakdown(fifteens = 2),
            cribCards = listOf(
                p1DealtHand[4], p1DealtHand[5], p2DealtHand[4], p2DealtHand[5]
            )
        ),
        GameHistoryEvent.GameEnded(winnerPlayerId = p1, finalScore = 121)
    )

    @Test
    fun `parses single-round game into one RoundAnalysis`() {
        val history = buildSingleRoundHistory()
        val rounds = analysisService.parseRounds(history)

        assertEquals(1, rounds.size)
        assertEquals(1, rounds[0].roundNumber)
        assertEquals(cutCard, rounds[0].cutCard)
    }

    @Test
    fun `identifies dealer correctly from DeckCut cuttingPlayerId`() {
        val history = buildSingleRoundHistory()
        val rounds = analysisService.parseRounds(history)

        // p1 cuts, so p2 is dealer
        assertEquals(p2, rounds[0].dealerPlayerId)
    }

    @Test
    fun `produces analysis for both players`() {
        val history = buildSingleRoundHistory()
        val rounds = analysisService.parseRounds(history)

        assertEquals(2, rounds[0].playerAnalyses.size)

        val p1Analysis = rounds[0].playerAnalyses.find { it.playerId == p1 }
        val p2Analysis = rounds[0].playerAnalyses.find { it.playerId == p2 }

        assertNotNull(p1Analysis)
        assertNotNull(p2Analysis)

        assertEquals(false, p1Analysis.isDealer)
        assertEquals(true, p2Analysis.isDealer)
    }

    @Test
    fun `player analysis includes correct dealt hand and kept hand`() {
        val history = buildSingleRoundHistory()
        val rounds = analysisService.parseRounds(history)
        val p1Analysis = rounds[0].playerAnalyses.find { it.playerId == p1 }!!

        assertEquals(p1DealtHand, p1Analysis.dealtHand)
        assertEquals(p1KeptHand, p1Analysis.keptHand)
        assertEquals(p1DealtHand.drop(4).toSet(), p1Analysis.discarded.toSet())
    }

    @Test
    fun `evDifference is non-negative`() {
        val history = buildSingleRoundHistory()
        val rounds = analysisService.parseRounds(history)

        for (analysis in rounds[0].playerAnalyses) {
            assertTrue(
                analysis.evDifference >= -0.001,
                "EV difference should be >= 0, got ${analysis.evDifference} for ${analysis.playerId}"
            )
        }
    }

    @Test
    fun `dealer analysis includes actual crib score`() {
        val history = buildSingleRoundHistory()
        val rounds = analysisService.parseRounds(history)
        val dealerAnalysis = rounds[0].playerAnalyses.find { it.isDealer }!!

        assertEquals(2, dealerAnalysis.actualCribScore)
    }

    @Test
    fun `non-dealer analysis has null crib score`() {
        val history = buildSingleRoundHistory()
        val rounds = analysisService.parseRounds(history)
        val poneAnalysis = rounds[0].playerAnalyses.find { !it.isDealer }!!

        assertEquals(null, poneAnalysis.actualCribScore)
    }

    @Test
    fun `rejects active games`() {
        val state = GameState(
            gameId = "game1",
            players = listOf(Player(p1, "Alice"), Player(p2, "Bob")),
            stage = GameStage.PEGGING
        )
        `when`(gameService.getGameState("game1")).thenReturn(state)

        assertThrows<IllegalArgumentException> {
            analysisService.analyzeGame("game1")
        }
    }

    @Test
    fun `handles missing dealtHands gracefully`() {
        val history = listOf(
            GameHistoryEvent.RoundStarted(roundNumber = 1),
            GameHistoryEvent.CardsDealt(), // empty dealtHands (old game)
            GameHistoryEvent.GameEnded(winnerPlayerId = p1, finalScore = 121)
        )

        val rounds = analysisService.parseRounds(history)
        // Round should be skipped since no dealt hands data
        assertEquals(0, rounds.size)
    }

    @Test
    fun `handles multi-round games`() {
        val round2DealtP1 = listOf(
            Card(Rank.KING, Suit.HEARTS),
            Card(Rank.QUEEN, Suit.HEARTS),
            Card(Rank.JACK, Suit.HEARTS),
            Card(Rank.TEN, Suit.HEARTS),
            Card(Rank.NINE, Suit.HEARTS),
            Card(Rank.EIGHT, Suit.HEARTS)
        )
        val round2DealtP2 = listOf(
            Card(Rank.ACE, Suit.DIAMONDS),
            Card(Rank.TWO, Suit.DIAMONDS),
            Card(Rank.THREE, Suit.DIAMONDS),
            Card(Rank.FOUR, Suit.DIAMONDS),
            Card(Rank.FIVE, Suit.DIAMONDS),
            Card(Rank.SIX, Suit.DIAMONDS)
        )

        val history = buildSingleRoundHistory().dropLast(1) + listOf(
            // Round 2
            GameHistoryEvent.RoundStarted(roundNumber = 2),
            GameHistoryEvent.CardsDealt(dealtHands = mapOf(p1 to round2DealtP1, p2 to round2DealtP2)),
            GameHistoryEvent.DeckCut(cutCard = Card(Rank.ACE, Suit.SPADES), cuttingPlayerId = p2, dealerScoredNobs = false),
            GameHistoryEvent.PeggingEnded(),
            GameHistoryEvent.HandCounted(
                playerId = p2,
                hand = round2DealtP2.take(4),
                totalPoints = 5,
                scoreBreakdown = ScoreBreakdown(fifteens = 2, runs = 3)
            ),
            GameHistoryEvent.HandCounted(
                playerId = p1,
                hand = round2DealtP1.take(4),
                totalPoints = 6,
                scoreBreakdown = ScoreBreakdown(runs = 4, pairs = 2)
            ),
            GameHistoryEvent.CribCounted(
                dealerPlayerId = p1,
                totalPoints = 0,
                scoreBreakdown = ScoreBreakdown(),
                cribCards = listOf(round2DealtP1[4], round2DealtP1[5], round2DealtP2[4], round2DealtP2[5])
            ),
            GameHistoryEvent.GameEnded(winnerPlayerId = p1, finalScore = 121)
        )

        val rounds = analysisService.parseRounds(history)
        assertEquals(2, rounds.size)
        assertEquals(1, rounds[0].roundNumber)
        assertEquals(2, rounds[1].roundNumber)

        // In round 2, p2 cuts so p1 is dealer
        assertEquals(p1, rounds[1].dealerPlayerId)
    }
}
