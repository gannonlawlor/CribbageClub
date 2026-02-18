package com.jackabee.cribbageclubserver.model.game

import com.jackabee.cribbageclubserver.model.player.Player

/**
 * Filters a GameState to produce a player-specific view that hides
 * private information (opponent's hand, deck, crib before counting, etc.).
 *
 * Applied at delivery boundaries (REST, WebSocket) so internal logic
 * (AI, persistence) continues to use the full unfiltered state.
 */
object GameStateFilter {

    /**
     * Returns a copy of [state] filtered for [viewingPlayerId].
     *
     * - Opponent's hand is always hidden (empty list).
     * - [GameState.remainingDeck] is always hidden (empty list).
     * - [GameState.crib] is hidden until COUNTING or GAME_OVER.
     * - [GameState.handsForCounting] hides the opponent's entry until COUNTING or GAME_OVER.
     *
     * If [viewingPlayerId] is blank or does not match any player, a spectator
     * view is returned where all hands are hidden.
     */
    fun forPlayer(state: GameState, viewingPlayerId: String): GameState {
        val revealCrib = state.stage == GameStage.COUNTING || state.stage == GameStage.GAME_OVER

        val filteredPlayers = state.players.map { player ->
            if (player.id == viewingPlayerId) {
                player // viewer keeps their own hand
            } else {
                player.copy(hand = emptyList())
            }
        }

        val filteredCrib = if (revealCrib) state.crib else emptyList()

        val filteredHandsForCounting = if (revealCrib) {
            state.handsForCounting
        } else {
            state.handsForCounting.filterKeys { it == viewingPlayerId }
        }

        return state.copy(
            players = filteredPlayers,
            remainingDeck = emptyList(),
            crib = filteredCrib,
            handsForCounting = filteredHandsForCounting
        )
    }
}
