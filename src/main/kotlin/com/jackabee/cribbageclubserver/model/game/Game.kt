package com.jackabee.cribbageclubserver.model.game

import com.jackabee.cribbageclubserver.model.action.ActionType
import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Deck
import com.jackabee.cribbageclubserver.model.player.Player
import java.time.Instant

class Game(
    val id: String,
    val players: List<Player>,
    private val deck: Deck = Deck(),
    val creationTime: Instant = Instant.now()
) {
    private var state: GameState = GameState(players)
    private val cardsPerHand = 6


    init {
        require(players.size == 2) { "This cribbage can only be played with 2 players" }
        dealCards()
    }

    fun getCurrentState(): GameState = state.copy()

    fun applyAction(action: GameAction): GameState {
        when (action.actionType) {
            ActionType.DISCARD_TO_CRIB -> discardToCrib(action.playerId, action.card!!)
            ActionType.CUT_DECK, // cutDeck(action.playerId)
            ActionType.PLAY_CARD, //playCard(action.playerId, action.card!!)
            ActionType.GO,  //announceGo(action.playerId)
            ActionType.COUNT_HAND -> //countHand(action.playerId)
                throw Exception("Not yet implemented")
        }
        return getCurrentState()
    }

    /**
     * Deals cards to each player in the game, then transitions to the discarding stage.
     *
     * @see GameStage.DEALING
     * @see transitionToDiscarding
     */
    private fun dealCards() {
        state = state.copy(
            stage = GameStage.DEALING,
            players = state.players.map { player ->
                player.copy(hand = deck.draw(cardsPerHand))
            },
            currentPlayerId = state.players.first().id
        )
        transitionToDiscarding()
    }

    /**
     * Transitions the game to the discarding stage. The discarding stage is the first part of the game where the starter
     * card is cut, and each player discards one card to the crib.
     *
     * @see GameStage.DISCARDING_TO_CRIB
     */
    private fun transitionToDiscarding() {
        state = state.copy(stage = GameStage.DISCARDING_TO_CRIB)
    }

    /**
     * Discards a card from a player's hand to the crib. Requires that the game is in the
     * [GameStage.DISCARDING_TO_CRIB] phase.
     *
     * @param playerId The ID of the player who is discarding
     * @param card The card to discard
     */
    private fun discardToCrib(playerId: String, card: Card) {
        require(state.stage == GameStage.DISCARDING_TO_CRIB) { "Not in discard phase" }

        val playerIndex = state.players.indexOfFirst { it.id == playerId }
        require(playerIndex != -1) { "Player not found" }

        val player = state.players[playerIndex]
        require(card in player.hand) { "Card not in player's hand" }

        val updatedPlayer = player.copy(hand = player.hand - card)
        val updatedPlayers = state.players.toMutableList().apply { set(playerIndex, updatedPlayer) }

        state = state.copy(
            players = updatedPlayers,
            crib = state.crib + card
        )

        if (state.crib.size == players.size * 2) {
            transitionToCutting()
        }
    }

    private fun transitionToCutting() {
        state = state.copy(
            stage = GameStage.CUTTING,
            currentPlayerId = state.players.first().id
        )
    }
}