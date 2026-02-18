package com.jackabee.cribbageclubserver.model.game

import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Deck
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit
import com.jackabee.cribbageclubserver.model.player.Player
import com.jackabee.cribbageclubserver.utils.HandCounting.peggingValue
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Integration test that plays a complete game from deal through multiple rounds to GAME_OVER.
 * Verifies stage transitions, scoring, and history event completeness.
 */
class FullGameRoundTripTest {

    private val player1 = Player("p1", "Alice")
    private val player2 = Player("p2", "Bob")

    /**
     * Plays a full round: discard -> cut -> peg -> count.
     * Returns the updated GameState after the round.
     */
    private fun playOneRound(game: Game): GameState {
        var state = game.getCurrentState()
        assertEquals(GameStage.DISCARDING_TO_CRIB, state.stage)

        // Each player discards 2 cards to crib
        for (playerState in state.players) {
            val hand = playerState.hand
            assertTrue(hand.size == 6, "Player should have 6 cards, has ${hand.size}")
            game.applyAction(GameAction.DiscardToCrib(playerState.id, hand[0]))
            game.applyAction(GameAction.DiscardToCrib(playerState.id, hand[1]))
        }

        state = game.getCurrentState()
        assertEquals(GameStage.CUTTING, state.stage)
        assertEquals(4, state.crib.size)

        // Non-dealer cuts
        val cutterId = state.currentPlayerId!!
        game.applyAction(GameAction.CutDeck(cutterId))
        state = game.getCurrentState()
        assertEquals(GameStage.PEGGING, state.stage)
        assertNotNull(state.cutCard)

        // Pegging: alternate playing cards or announcing Go
        playPeggingPhase(game)

        state = game.getCurrentState()
        if (state.stage == GameStage.GAME_OVER) return state
        assertEquals(GameStage.COUNTING, state.stage)

        // Count hands: non-dealer first, then dealer
        val countingPlayerId = state.currentPlayerId!!
        game.applyAction(GameAction.CountHand(countingPlayerId))
        state = game.getCurrentState()
        if (state.stage == GameStage.GAME_OVER) return state

        val secondCounterId = state.currentPlayerId!!
        game.applyAction(GameAction.CountHand(secondCounterId))
        state = game.getCurrentState()

        // After dealer counts, crib is auto-scored and new round starts (or game over)
        return state
    }

    /**
     * Plays through the pegging phase by having players play cards when possible,
     * or announce Go when they can't.
     */
    private fun playPeggingPhase(game: Game) {
        var state = game.getCurrentState()
        var safetyCounter = 0
        val maxIterations = 50

        while (state.stage == GameStage.PEGGING && safetyCounter < maxIterations) {
            val currentPlayerId = state.currentPlayerId!!
            val currentPlayer = state.players.first { it.id == currentPlayerId }

            // Try to play a card that doesn't exceed 31
            val playableCard = currentPlayer.hand.firstOrNull { card ->
                state.peggingCount + card.peggingValue() <= 31
            }

            if (playableCard != null) {
                game.applyAction(GameAction.PlayCard(currentPlayerId, playableCard))
            } else {
                game.applyAction(GameAction.Go(currentPlayerId))
            }

            state = game.getCurrentState()
            safetyCounter++
        }

        assertTrue(safetyCounter < maxIterations, "Pegging phase should complete within $maxIterations iterations")
    }

    @Test
    fun `should play a complete game through multiple rounds to GAME_OVER`() {
        val game = Game("test-full-game", listOf(player1, player2))
        var state = game.getCurrentState()
        var roundCount = 0
        val maxRounds = 30

        while (state.stage != GameStage.GAME_OVER && roundCount < maxRounds) {
            state = playOneRound(game)
            roundCount++
        }

        assertEquals(GameStage.GAME_OVER, state.stage, "Game should reach GAME_OVER within $maxRounds rounds")

        // Verify a winner exists with score >= 121
        val winner = state.players.maxByOrNull { it.score }!!
        assertTrue(winner.score >= 121, "Winner should have at least 121 points, has ${winner.score}")

        // Verify history contains expected event types
        val history = state.history
        assertTrue(history.any { it is GameHistoryEvent.RoundStarted })
        assertTrue(history.any { it is GameHistoryEvent.CardsDealt })
        assertTrue(history.any { it is GameHistoryEvent.DeckCut })
        assertTrue(history.any { it is GameHistoryEvent.CardPlayed })
        assertTrue(history.any { it is GameHistoryEvent.GameEnded })

        // Verify GameEnded event
        val gameEndedEvent = history.filterIsInstance<GameHistoryEvent.GameEnded>().single()
        assertEquals(winner.id, gameEndedEvent.winnerPlayerId)
        assertEquals(winner.score, gameEndedEvent.finalScore)
    }

    @Test
    fun `should track scoring correctly through a complete round`() {
        val game = Game("test-scoring", listOf(player1, player2))

        val stateBefore = game.getCurrentState()
        val scoresBefore = stateBefore.players.associate { it.id to it.score }

        playOneRound(game)

        val stateAfter = game.getCurrentState()

        // Scores should only increase or stay the same
        for (player in stateAfter.players) {
            assertTrue(
                player.score >= scoresBefore[player.id]!!,
                "Player ${player.name} score should not decrease"
            )
        }
    }

    @Test
    fun `should rotate dealer between rounds`() {
        val game = Game("test-dealer-rotation", listOf(player1, player2))

        val initialState = game.getCurrentState()
        val firstDealerIndex = initialState.dealerIndex

        playOneRound(game)

        val stateAfterRound = game.getCurrentState()
        if (stateAfterRound.stage != GameStage.GAME_OVER) {
            val expectedNewDealer = (firstDealerIndex + 1) % 2
            assertEquals(expectedNewDealer, stateAfterRound.dealerIndex, "Dealer should rotate after a round")
        }
    }

    @Test
    fun `should have complete and ordered history events for a round`() {
        val game = Game("test-history-order", listOf(player1, player2))

        playOneRound(game)

        val history = game.getCurrentState().history

        // First events should be RoundStarted, then CardsDealt
        assertTrue(history[0] is GameHistoryEvent.RoundStarted)
        assertTrue(history[1] is GameHistoryEvent.CardsDealt)

        // DeckCut should come after discarding
        val deckCutIndex = history.indexOfFirst { it is GameHistoryEvent.DeckCut }
        assertTrue(deckCutIndex > 1, "DeckCut should come after initial events")

        // PeggingEnded should come after card plays
        val peggingEndedIndex = history.indexOfFirst { it is GameHistoryEvent.PeggingEnded }
        assertTrue(peggingEndedIndex > deckCutIndex, "PeggingEnded should come after DeckCut")

        // HandCounted events should come after PeggingEnded
        val handCountedIndices = history.indices.filter { history[it] is GameHistoryEvent.HandCounted }
        if (handCountedIndices.isNotEmpty()) {
            assertTrue(
                handCountedIndices.all { it > peggingEndedIndex },
                "HandCounted events should come after PeggingEnded"
            )
        }
    }

    @Test
    fun `should correctly handle crib scoring for dealer`() {
        val game = Game("test-crib", listOf(player1, player2))

        playOneRound(game)

        val history = game.getCurrentState().history
        val cribCountedEvents = history.filterIsInstance<GameHistoryEvent.CribCounted>()

        if (cribCountedEvents.isNotEmpty()) {
            val cribEvent = cribCountedEvents.first()
            assertTrue(cribEvent.totalPoints >= 0, "Crib score should be non-negative")
            assertNotNull(cribEvent.scoreBreakdown)
        }
    }
}
