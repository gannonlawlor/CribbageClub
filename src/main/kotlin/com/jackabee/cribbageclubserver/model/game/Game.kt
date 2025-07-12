package com.jackabee.cribbageclubserver.model.game

import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Deck
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.player.Player
import com.jackabee.cribbageclubserver.utils.HandCounting.calculateHandScore
import com.jackabee.cribbageclubserver.utils.HandCounting.peggingValue
import com.jackabee.cribbageclubserver.utils.ScoreBreakdownCalculator
import java.time.Instant

class Game(
    val id: String,
    private val players: List<Player>,
    private val deck: Deck = Deck(),
    val creationTime: Instant = Instant.now(),
    private val historyTracker: GameHistoryTracker = ListGameHistoryTracker()
) {
    private var state: GameState = GameState(id, players)
    private val cardsPerHand = 6
    private var currentRound = 1


    init {
        require(players.size == 2) { "This cribbage can only be played with 2 players" }
        dealCards()
    }

    fun getCurrentState(): GameState = state.copy(history = historyTracker.getHistory())

    fun applyAction(action: GameAction): GameState {
        when (action) {
            is GameAction.DiscardToCrib -> discardToCrib(action.playerId, action.card)
            is GameAction.CutDeck -> cutDeck(action.playerId)
            is GameAction.PlayCard -> playCard(action.playerId, action.card)
            is GameAction.Go -> announceGo(action.playerId)
            is GameAction.CountHand -> countHand(action.playerId)
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
        historyTracker.addEvent(GameHistoryEvent.RoundStarted(roundNumber = currentRound))
        
        state = state.copy(
            stage = GameStage.DEALING,
            players = state.players.map { player ->
                player.copy(hand = deck.draw(cardsPerHand))
            },
            currentPlayerId = state.players.first().id
        )
        
        historyTracker.addEvent(GameHistoryEvent.CardsDealt())
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
        
        // Store hands for counting before transitioning to pegging
        val handsForCounting = state.players.associate { it.id to it.hand }
        
        // Check if Jack is cut for dealer scoring
        val dealerScoredNobs = cutCard.rank == Rank.JACK
        
        state = state.copy(
            cutCard = cutCard,
            stage = GameStage.PEGGING,
            currentPlayerId = playerId,
            handsForCounting = handsForCounting
        )

        // If Jack is cut, dealer scores 2 points ("His Nobs")
        if (dealerScoredNobs) {
            val dealerIndex = (players.indexOfFirst { it.id == state.currentPlayerId } - 1 + players.size) % players.size
            val updatedPlayers = state.players.toMutableList()
            val dealer = updatedPlayers[dealerIndex]
            updatedPlayers[dealerIndex] = dealer.copy(score = dealer.score + 2)
            state = state.copy(players = updatedPlayers)
        }
        
        historyTracker.addEvent(GameHistoryEvent.DeckCut(
            cutCard = cutCard,
            cuttingPlayerId = playerId,
            dealerScoredNobs = dealerScoredNobs
        ))
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

        // Create scoring reason for history
        val scoringReason = when {
            newCount == 31 -> "Thirty-one"
            newCount == 15 -> "Fifteen"
            scoreEarned > 0 && updatedPlayedCards.size >= 2 -> {
                val lastCard = updatedPlayedCards.last()
                val sameFaceCards = updatedPlayedCards.reversed().takeWhile { it.rank == lastCard.rank }
                when (sameFaceCards.size) {
                    2 -> "Pair"
                    3 -> "Three of a kind"
                    4 -> "Four of a kind"
                    else -> {
                        // Check for run
                        var runReason: String? = null
                        for (runLength in 7 downTo 3) {
                            if (updatedPlayedCards.takeLast(runLength).isRun()) {
                                runReason = "Run of $runLength"
                                break
                            }
                        }
                        runReason
                    }
                }
            }
            else -> null
        }

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

        // Add to history
        historyTracker.addEvent(GameHistoryEvent.CardPlayed(
            playerId = playerId,
            card = card,
            newCount = newCount,
            pointsScored = scoreEarned,
            scoringReason = scoringReason
        ))

        // Check if pegging round is over
        if (state.players.all { it.hand.isEmpty() }) {
            historyTracker.addEvent(GameHistoryEvent.PeggingEnded())
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

            historyTracker.addEvent(GameHistoryEvent.GoAnnounced(
                playerId = playerId,
                pointsScored = 1
            ))
        } else {
            state = state.copy(
                currentPlayerId = nextPlayerId,
                lastPlayWasGo = true
            )

            historyTracker.addEvent(GameHistoryEvent.GoAnnounced(
                playerId = playerId,
                pointsScored = 0
            ))
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

    private fun countHand(playerId: String) {
        require(state.stage == GameStage.COUNTING) { "Not in counting phase" }
        require(playerId == state.currentPlayerId) { "Not this player's turn to count" }

        val playerIndex = state.players.indexOfFirst { it.id == playerId }
        val player = state.players[playerIndex]
        
        // Use the stored hand for counting
        val handToCount = state.handsForCounting[playerId] ?: emptyList()
        require(handToCount.isNotEmpty()) { "No hand to count for player $playerId" }

        // Count hand score
        val handScore = calculateHandScore(handToCount, state.cutCard!!)
        val scoreBreakdown = ScoreBreakdownCalculator.calculateHandScoreBreakdown(handToCount, state.cutCard!!)
        val updatedPlayer = player.copy(score = player.score + handScore)
        val updatedPlayers = state.players.toMutableList().apply { set(playerIndex, updatedPlayer) }

        // Add to history
        historyTracker.addEvent(GameHistoryEvent.HandCounted(
            playerId = playerId,
            totalPoints = handScore,
            scoreBreakdown = scoreBreakdown
        ))

        // Check if game is over
        if (updatedPlayer.score >= 121) {
            state = state.copy(
                players = updatedPlayers,
                stage = GameStage.GAME_OVER
            )
            
            historyTracker.addEvent(GameHistoryEvent.GameEnded(
                winnerPlayerId = playerId,
                finalScore = updatedPlayer.score
            ))
            return
        }

        // Move to next player or handle crib counting
        val nextPlayerIndex = (playerIndex + 1) % players.size
        if (nextPlayerIndex == 0) {
            // All players have counted, now dealer counts crib
            val dealerIndex = getDealerIndex()
            val dealer = updatedPlayers[dealerIndex]
            val cribScore = calculateHandScore(state.crib, state.cutCard!!, isCrib = true)
            val cribScoreBreakdown = ScoreBreakdownCalculator.calculateHandScoreBreakdown(state.crib, state.cutCard!!, isCrib = true)
            val updatedDealer = dealer.copy(score = dealer.score + cribScore)
            updatedPlayers[dealerIndex] = updatedDealer

            // Add crib to history
            historyTracker.addEvent(GameHistoryEvent.CribCounted(
                dealerPlayerId = dealer.id,
                totalPoints = cribScore,
                scoreBreakdown = cribScoreBreakdown
            ))

            // Check if dealer wins after crib
            if (updatedDealer.score >= 121) {
                state = state.copy(
                    players = updatedPlayers,
                    stage = GameStage.GAME_OVER
                )
                
                historyTracker.addEvent(GameHistoryEvent.GameEnded(
                    winnerPlayerId = dealer.id,
                    finalScore = updatedDealer.score
                ))
                return
            }

            // Start new round
            startNewRound(updatedPlayers)
        } else {
            // Move to next player
            state = state.copy(
                players = updatedPlayers,
                currentPlayerId = players[nextPlayerIndex].id
            )
        }
    }

    private fun getDealerIndex(): Int {
        // For now, assume first player is always dealer
        // In a full implementation, this would track dealer rotation
        return 0
    }

    private fun startNewRound(players: List<Player>) {
        // Reset deck and deal new cards
        deck.shuffle()
        currentRound++
        state = state.copy(
            players = players.map { player ->
                player.copy(hand = deck.draw(cardsPerHand))
            },
            crib = emptyList(),
            cutCard = null,
            currentPlayerId = players.first().id,
            stage = GameStage.DEALING,
            playedCards = emptyList(),
            peggingCount = 0,
            lastPlayWasGo = false,
            handsForCounting = emptyMap()
        )
        transitionToDiscarding()
    }
}