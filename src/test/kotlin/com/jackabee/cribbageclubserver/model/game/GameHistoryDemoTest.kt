package com.jackabee.cribbageclubserver.model.game

import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Deck
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit
import com.jackabee.cribbageclubserver.model.player.Player
import org.junit.jupiter.api.Test
import org.mockito.Mockito.mock
import org.mockito.kotlin.whenever

class GameHistoryDemoTest {

    @Test
    fun `Demonstrate complete game history tracking`() {
        // Create players
        val players = listOf(
            Player("alice", "Alice"),
            Player("bob", "Bob")
        )

        // Create mock deck with predictable cards
        val mockDeck = mock<Deck>()
        
        // Setup specific cards for testing
        val aliceCards = listOf(
            Card(Rank.FIVE, Suit.HEARTS),
            Card(Rank.TEN, Suit.HEARTS),
            Card(Rank.JACK, Suit.HEARTS),
            Card(Rank.QUEEN, Suit.HEARTS),
            Card(Rank.KING, Suit.HEARTS),
            Card(Rank.ACE, Suit.HEARTS)
        )
        
        val bobCards = listOf(
            Card(Rank.FIVE, Suit.SPADES),
            Card(Rank.SIX, Suit.SPADES),
            Card(Rank.SEVEN, Suit.SPADES),
            Card(Rank.EIGHT, Suit.SPADES),
            Card(Rank.NINE, Suit.SPADES),
            Card(Rank.TEN, Suit.SPADES)
        )

        whenever(mockDeck.draw(6)).thenReturn(aliceCards, bobCards)
        whenever(mockDeck.cut()).thenReturn(Card(Rank.FIVE, Suit.DIAMONDS))

        // Create game
        val game = Game("demo", players, mockDeck)
        
        // Print initial history
        println("=== INITIAL GAME STATE ===")
        printGameHistory(game)
        
        // Each player discards 2 cards to crib
        println("\n=== DISCARDING TO CRIB ===")
        game.applyAction(GameAction.DiscardToCrib("alice", aliceCards[0])) // 5H
        game.applyAction(GameAction.DiscardToCrib("alice", aliceCards[1])) // 10H
        game.applyAction(GameAction.DiscardToCrib("bob", bobCards[0])) // 5S
        game.applyAction(GameAction.DiscardToCrib("bob", bobCards[1])) // 6S
        
        // Cut the deck
        println("\n=== CUTTING THE DECK ===")
        game.applyAction(GameAction.CutDeck("alice"))
        printGameHistory(game)
        
        // Play some cards in pegging
        println("\n=== PEGGING PHASE ===")
        val peggingState = game.getCurrentState()
        val aliceHand = peggingState.players.first { it.id == "alice" }.hand
        val bobHand = peggingState.players.first { it.id == "bob" }.hand
        
        // Alice plays first card
        game.applyAction(GameAction.PlayCard("alice", aliceHand[0]))
        
        // Bob plays a card
        val bobState = game.getCurrentState()
        val bobHandAfterAlice = bobState.players.first { it.id == "bob" }.hand
        game.applyAction(GameAction.PlayCard("bob", bobHandAfterAlice[0]))
        
        // Alice announces go
        game.applyAction(GameAction.Go("alice"))
        
        printGameHistory(game)
        
        println("\n=== GAME HISTORY SUMMARY ===")
        val finalState = game.getCurrentState()
        finalState.history.forEach { event ->
            when (event) {
                is GameHistoryEvent.RoundStarted -> println("Round ${event.roundNumber} started")
                is GameHistoryEvent.CardsDealt -> println("Cards dealt to all players")
                is GameHistoryEvent.DeckCut -> println("Deck cut: ${event.cutCard} (cut by ${event.cuttingPlayerId})")
                is GameHistoryEvent.CardPlayed -> println("${event.playerId} played ${event.card}, count: ${event.newCount}, scored: ${event.pointsScored}")
                is GameHistoryEvent.GoAnnounced -> println("${event.playerId} announced Go, scored: ${event.pointsScored}")
                is GameHistoryEvent.HandCounted -> println("${event.playerId} counted hand: ${event.totalPoints} points")
                is GameHistoryEvent.CribCounted -> println("${event.dealerPlayerId} counted crib: ${event.totalPoints} points")
                is GameHistoryEvent.GameEnded -> println("Game ended! Winner: ${event.winnerPlayerId} with ${event.finalScore} points")
                else -> println("Other event: ${event.javaClass.simpleName}")
            }
        }
    }

    private fun printGameHistory(game: Game) {
        val state = game.getCurrentState()
        println("Current Stage: ${state.stage}")
        println("Players: ${state.players.map { "${it.name} (${it.score} points)" }}")
        println("History Events: ${state.history.size}")
        state.history.takeLast(3).forEach { event ->
            println("  - ${event.javaClass.simpleName}: ${event.timestamp}")
        }
    }
}