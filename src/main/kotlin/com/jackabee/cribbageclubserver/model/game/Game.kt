package com.jackabee.cribbageclubserver.model.game

import com.jackabee.cribbageclubserver.model.action.ActionType
import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Deck
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.player.Player
import java.time.Instant

class Game(
    val id: String,
    private val players: List<Player>,
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
        when (action) {
            is GameAction.DiscardToCrib -> discardToCrib(action.playerId, action.card)
            is GameAction.CutDeck -> cutDeck(action.playerId)
            is GameAction.PlayCard -> playCard(action.playerId, action.card)
            is GameAction.Go -> throw Exception("Not yet implemented") // announceGo(action.playerId)
            is GameAction.CountHand -> throw Exception("Not yet implemented") // countHand(action.playerId)
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

    private fun cutDeck(playerId: String) {
        require(state.stage == GameStage.CUTTING) { "Not in cutting phase" }
        require(playerId == state.currentPlayerId) { "Not this player's turn to cut" }

        val cutCard = deck.cut()
        state = state.copy(
            cutCard = cutCard,
            stage = GameStage.PEGGING,
            currentPlayerId = playerId
        )

        // If Jack is cut, dealer scores 2 points ("His Nobs")
        if (cutCard.rank == Rank.JACK) {
            val dealerIndex = (players.indexOfFirst { it.id == state.currentPlayerId } - 1 + players.size) % players.size
            val updatedPlayers = state.players.toMutableList()
            val dealer = updatedPlayers[dealerIndex]
            updatedPlayers[dealerIndex] = dealer.copy(score = dealer.score + 2)
            state = state.copy(players = updatedPlayers)
        }
    }

    private fun transitionToCutting() {
        state = state.copy(
            stage = GameStage.CUTTING,
            currentPlayerId = state.players.first().id
        )
    }

    private fun playCard(playerId: String, card: Card) {
        require(state.stage == GameStage.PEGGING) { "Not in pegging phase" }
        require(playerId == state.currentPlayerId) { "Not this player's turn" }

        val playerIndex = state.players.indexOfFirst { it.id == playerId }
        val player = state.players[playerIndex]
        require(card in player.hand) { "Card not in player's hand" }

        val newCount = state.peggingCount + card.peggingValue()
        require(newCount <= 31) { "Playing this card would exceed 31" }

        // Update player's hand and played cards
        val updatedPlayer = player.copy(hand = player.hand - card)
        val updatedPlayers = state.players.toMutableList().apply { set(playerIndex, updatedPlayer) }
        val updatedPlayedCards = state.playedCards + card

        // Calculate score for this play
        val scoreEarned = calculatePeggingScore(updatedPlayedCards, newCount)
        val playerWithUpdatedScore = updatedPlayer.copy(score = updatedPlayer.score + scoreEarned)
        updatedPlayers[playerIndex] = playerWithUpdatedScore

        // Move to next player
        val nextPlayerIndex = (playerIndex + 1) % players.size
        val nextPlayerId = players[nextPlayerIndex].id

        state = state.copy(
            players = updatedPlayers,
            playedCards = updatedPlayedCards,
            peggingCount = newCount,
            currentPlayerId = nextPlayerId,
            lastPlayWasGo = false
        )

        // Check if pegging round is over
        if (state.players.all { it.hand.isEmpty() }) {
            transitionToHandCounting()
        }
    }

    private fun announceGo(playerId: String) {
        require(state.stage == GameStage.PEGGING) { "Not in pegging phase" }
        require(playerId == state.currentPlayerId) { "Not this player's turn" }

        val playerIndex = state.players.indexOfFirst { it.id == playerId }
        val nextPlayerIndex = (playerIndex + 1) % players.size
        val nextPlayerId = players[nextPlayerIndex].id

        // If this is the second consecutive "Go", reset the count and award a point
        if (state.lastPlayWasGo) {
            val currentPlayer = state.players[playerIndex]
            val updatedPlayer = currentPlayer.copy(score = currentPlayer.score + 1)
            val updatedPlayers = state.players.toMutableList().apply { set(playerIndex, updatedPlayer) }

            state = state.copy(
                players = updatedPlayers,
                peggingCount = 0,
                playedCards = emptyList(),
                currentPlayerId = nextPlayerId,
                lastPlayWasGo = false
            )
        } else {
            state = state.copy(
                currentPlayerId = nextPlayerId,
                lastPlayWasGo = true
            )
        }
    }

    private fun calculatePeggingScore(playedCards: List<Card>, count: Int): Int {
        var score = 0

        // Check for 15 or 31
        if (count == 15 || count == 31) score += 2

        // Check for pairs, trips, quads
        val lastCard = playedCards.last()
        val sameFaceCards = playedCards.reversed().takeWhile { it.rank == lastCard.rank }
        when (sameFaceCards.size) {
            2 -> score += 2  // Pair
            3 -> score += 6  // Trip
            4 -> score += 12 // Quad
        }

        // Check for runs
        for (runLength in 7 downTo 3) {
            if (playedCards.takeLast(runLength).isRun()) {
                score += runLength
                break
            }
        }

        return score
    }

    private fun transitionToHandCounting() {
        state = state.copy(
            stage = GameStage.COUNTING,
            currentPlayerId = players.first().id,
            peggingCount = 0,
            playedCards = emptyList()
        )
    }

    private fun List<Card>.isRun(): Boolean {
        if (this.size < 3) return false
        val sortedRanks = this.map { it.rank.ordinal }.sorted()
        return sortedRanks.zipWithNext().all { (a, b) -> b - a == 1 }
    }

    private fun Card.peggingValue(): Int = when (rank) {
        Rank.ACE -> 1
        Rank.JACK, Rank.QUEEN, Rank.KING -> 10
        else -> rank.ordinal + 1
    }
}