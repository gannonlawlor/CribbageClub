package com.jackabee.cribbageclubserver.model.game

import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.player.Player
import com.jackabee.cribbageclubserver.utils.HandCounting.peggingValue
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Tests that Game.restore() correctly reconstructs a game from persisted state
 * and that the restored game continues to function identically.
 */
class GameRestoreTest {

    private val player1 = Player("p1", "Alice")
    private val player2 = Player("p2", "Bob")

    @Test
    fun `should restore game in DISCARDING_TO_CRIB stage and continue playing`() {
        val game = Game("restore-test-1", listOf(player1, player2))
        val originalState = game.getCurrentState()
        assertEquals(GameStage.DISCARDING_TO_CRIB, originalState.stage)

        // Restore from this state
        val restored = Game.restore(originalState)
        val restoredState = restored.getCurrentState()

        assertEquals(originalState.gameId, restoredState.gameId)
        assertEquals(originalState.stage, restoredState.stage)
        assertEquals(originalState.players.size, restoredState.players.size)
        assertEquals(originalState.dealerIndex, restoredState.dealerIndex)

        // Verify hands match
        for (i in originalState.players.indices) {
            assertEquals(
                originalState.players[i].hand.toSet(),
                restoredState.players[i].hand.toSet(),
                "Player ${i} hand should match after restore"
            )
        }

        // Continue playing - discard to crib
        for (playerState in restoredState.players) {
            val hand = playerState.hand
            restored.applyAction(GameAction.DiscardToCrib(playerState.id, hand[0]))
            restored.applyAction(GameAction.DiscardToCrib(playerState.id, hand[1]))
        }

        val afterDiscard = restored.getCurrentState()
        assertEquals(GameStage.CUTTING, afterDiscard.stage)
        assertEquals(4, afterDiscard.crib.size)
    }

    @Test
    fun `should restore game in PEGGING stage and continue pegging`() {
        val game = Game("restore-test-2", listOf(player1, player2))
        var state = game.getCurrentState()

        // Discard to crib
        for (playerState in state.players) {
            val hand = playerState.hand
            game.applyAction(GameAction.DiscardToCrib(playerState.id, hand[0]))
            game.applyAction(GameAction.DiscardToCrib(playerState.id, hand[1]))
        }

        // Cut deck
        state = game.getCurrentState()
        game.applyAction(GameAction.CutDeck(state.currentPlayerId!!))
        state = game.getCurrentState()
        assertEquals(GameStage.PEGGING, state.stage)

        // Play one card
        val currentPlayerId = state.currentPlayerId!!
        val currentPlayer = state.players.first { it.id == currentPlayerId }
        val cardToPlay = currentPlayer.hand.first()
        game.applyAction(GameAction.PlayCard(currentPlayerId, cardToPlay))

        // Capture state and restore
        val stateToRestore = game.getCurrentState()
        val restored = Game.restore(stateToRestore)
        val restoredState = restored.getCurrentState()

        assertEquals(GameStage.PEGGING, restoredState.stage)
        assertEquals(stateToRestore.peggingCount, restoredState.peggingCount)
        assertEquals(stateToRestore.currentPlayerId, restoredState.currentPlayerId)
        assertEquals(stateToRestore.playedCards.size, restoredState.playedCards.size)

        // Continue pegging - should be able to play cards or announce go
        val nextPlayerId = restoredState.currentPlayerId!!
        val nextPlayer = restoredState.players.first { it.id == nextPlayerId }
        val playableCard = nextPlayer.hand.firstOrNull { card ->
            restoredState.peggingCount + card.peggingValue() <= 31
        }

        if (playableCard != null) {
            val afterPlay = restored.applyAction(GameAction.PlayCard(nextPlayerId, playableCard))
            assertTrue(afterPlay.peggingCount > restoredState.peggingCount || afterPlay.peggingCount == 0)
        } else {
            restored.applyAction(GameAction.Go(nextPlayerId))
        }
    }

    @Test
    fun `should restore game in COUNTING stage and continue counting`() {
        val game = Game("restore-test-3", listOf(player1, player2))
        var state = game.getCurrentState()

        // Discard to crib
        for (playerState in state.players) {
            val hand = playerState.hand
            game.applyAction(GameAction.DiscardToCrib(playerState.id, hand[0]))
            game.applyAction(GameAction.DiscardToCrib(playerState.id, hand[1]))
        }

        // Cut
        state = game.getCurrentState()
        game.applyAction(GameAction.CutDeck(state.currentPlayerId!!))

        // Peg all cards
        state = game.getCurrentState()
        var safetyCounter = 0
        while (state.stage == GameStage.PEGGING && safetyCounter < 50) {
            val currentPlayerId = state.currentPlayerId!!
            val currentPlayer = state.players.first { it.id == currentPlayerId }
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

        if (state.stage != GameStage.COUNTING) return // Game might have ended during pegging

        // Restore at COUNTING stage
        val stateToRestore = game.getCurrentState()
        val restored = Game.restore(stateToRestore)
        val restoredState = restored.getCurrentState()

        assertEquals(GameStage.COUNTING, restoredState.stage)
        assertNotNull(restoredState.cutCard)
        assertEquals(stateToRestore.currentPlayerId, restoredState.currentPlayerId)

        // Count first player's hand
        val firstCounter = restoredState.currentPlayerId!!
        restored.applyAction(GameAction.CountHand(firstCounter))
        val afterFirstCount = restored.getCurrentState()

        if (afterFirstCount.stage == GameStage.COUNTING) {
            // Count second player's hand
            val secondCounter = afterFirstCount.currentPlayerId!!
            restored.applyAction(GameAction.CountHand(secondCounter))
        }
    }

    @Test
    fun `should restore and play through to completion`() {
        // Play a game partway through
        val game = Game("restore-test-4", listOf(player1, player2))
        var state = game.getCurrentState()

        // Play one full round
        // Discard
        for (playerState in state.players) {
            val hand = playerState.hand
            game.applyAction(GameAction.DiscardToCrib(playerState.id, hand[0]))
            game.applyAction(GameAction.DiscardToCrib(playerState.id, hand[1]))
        }
        state = game.getCurrentState()
        game.applyAction(GameAction.CutDeck(state.currentPlayerId!!))

        // Peg
        state = game.getCurrentState()
        var safetyCounter = 0
        while (state.stage == GameStage.PEGGING && safetyCounter < 50) {
            val pid = state.currentPlayerId!!
            val p = state.players.first { it.id == pid }
            val card = p.hand.firstOrNull { state.peggingCount + it.peggingValue() <= 31 }
            if (card != null) game.applyAction(GameAction.PlayCard(pid, card))
            else game.applyAction(GameAction.Go(pid))
            state = game.getCurrentState()
            safetyCounter++
        }

        // If game already ended, that's fine
        if (state.stage == GameStage.GAME_OVER) return

        // Restore and continue playing to completion
        val midGameState = game.getCurrentState()
        val restored = Game.restore(midGameState)
        var restoredState = restored.getCurrentState()

        // Play to completion
        var roundsPlayed = 0
        val maxRounds = 30

        while (restoredState.stage != GameStage.GAME_OVER && roundsPlayed < maxRounds) {
            when (restoredState.stage) {
                GameStage.DISCARDING_TO_CRIB -> {
                    for (playerState in restoredState.players) {
                        val hand = playerState.hand
                        restored.applyAction(GameAction.DiscardToCrib(playerState.id, hand[0]))
                        restored.applyAction(GameAction.DiscardToCrib(playerState.id, hand[1]))
                    }
                }
                GameStage.CUTTING -> {
                    restored.applyAction(GameAction.CutDeck(restoredState.currentPlayerId!!))
                }
                GameStage.PEGGING -> {
                    val pid = restoredState.currentPlayerId!!
                    val p = restoredState.players.first { it.id == pid }
                    val card = p.hand.firstOrNull { restoredState.peggingCount + it.peggingValue() <= 31 }
                    if (card != null) restored.applyAction(GameAction.PlayCard(pid, card))
                    else restored.applyAction(GameAction.Go(pid))
                }
                GameStage.COUNTING -> {
                    restored.applyAction(GameAction.CountHand(restoredState.currentPlayerId!!))
                    roundsPlayed++
                }
                else -> break
            }
            restoredState = restored.getCurrentState()
        }

        assertEquals(GameStage.GAME_OVER, restoredState.stage, "Restored game should reach GAME_OVER")
        val winner = restoredState.players.maxByOrNull { it.score }!!
        assertTrue(winner.score >= 121, "Winner should have at least 121 points")
    }

    @Test
    fun `should preserve scores after restore`() {
        val game = Game("restore-test-5", listOf(player1, player2))
        var state = game.getCurrentState()

        // Discard to crib
        for (playerState in state.players) {
            val hand = playerState.hand
            game.applyAction(GameAction.DiscardToCrib(playerState.id, hand[0]))
            game.applyAction(GameAction.DiscardToCrib(playerState.id, hand[1]))
        }

        // Cut
        state = game.getCurrentState()
        game.applyAction(GameAction.CutDeck(state.currentPlayerId!!))

        // Play a few cards to potentially score some pegging points
        state = game.getCurrentState()
        var cardsPlayed = 0
        while (state.stage == GameStage.PEGGING && cardsPlayed < 4) {
            val pid = state.currentPlayerId!!
            val p = state.players.first { it.id == pid }
            val card = p.hand.firstOrNull { state.peggingCount + it.peggingValue() <= 31 }
            if (card != null) {
                game.applyAction(GameAction.PlayCard(pid, card))
                cardsPlayed++
            } else {
                game.applyAction(GameAction.Go(pid))
            }
            state = game.getCurrentState()
        }

        // Restore and verify scores match
        val stateToRestore = game.getCurrentState()
        val restored = Game.restore(stateToRestore)
        val restoredState = restored.getCurrentState()

        for (i in stateToRestore.players.indices) {
            assertEquals(
                stateToRestore.players[i].score,
                restoredState.players[i].score,
                "Player ${stateToRestore.players[i].name} score should be preserved after restore"
            )
        }
    }
}
