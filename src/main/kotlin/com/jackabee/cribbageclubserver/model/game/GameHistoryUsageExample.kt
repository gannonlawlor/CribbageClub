package com.jackabee.cribbageclubserver.model.game

import com.jackabee.cribbageclubserver.model.player.Player

/**
 * Example showing how to use the game history system
 */
class GameHistoryUsageExample {
    
    fun demonstrateHistoryUsage() {
        // Create a game
        val players = listOf(
            Player("alice", "Alice"),
            Player("bob", "Bob")
        )
        val game = Game("example-game", players)
        
        // Get current state (includes history)
        val state = game.getCurrentState()
        
        // Access full history
        val fullHistory = state.history
        println("Total events in history: ${fullHistory.size}")
        
        // Filter for specific event types
        val peggingEvents = fullHistory.filterIsInstance<GameHistoryEvent.CardPlayed>()
        println("Pegging plays: ${peggingEvents.size}")
        
        // Get scoring events
        val scoringEvents = fullHistory.filter { event ->
            when (event) {
                is GameHistoryEvent.CardPlayed -> event.pointsScored > 0
                is GameHistoryEvent.GoAnnounced -> event.pointsScored > 0
                is GameHistoryEvent.HandCounted -> event.totalPoints > 0
                is GameHistoryEvent.CribCounted -> event.totalPoints > 0
                else -> false
            }
        }
        println("Scoring events: ${scoringEvents.size}")
        
        // Generate a game summary
        generateGameSummary(fullHistory)
    }
    
    private fun generateGameSummary(history: List<GameHistoryEvent>) {
        println("\n=== GAME SUMMARY ===")
        
        val rounds = history.filterIsInstance<GameHistoryEvent.RoundStarted>().size
        println("Rounds played: $rounds")
        
        val totalPeggingPoints = history.filterIsInstance<GameHistoryEvent.CardPlayed>()
            .sumOf { it.pointsScored }
        println("Total pegging points: $totalPeggingPoints")
        
        val totalHandPoints = history.filterIsInstance<GameHistoryEvent.HandCounted>()
            .sumOf { it.totalPoints }
        println("Total hand points: $totalHandPoints")
        
        val totalCribPoints = history.filterIsInstance<GameHistoryEvent.CribCounted>()
            .sumOf { it.totalPoints }
        println("Total crib points: $totalCribPoints")
        
        // Show recent significant events
        val significantEvents = history.filter { event ->
            when (event) {
                is GameHistoryEvent.DeckCut -> event.dealerScoredNobs
                is GameHistoryEvent.CardPlayed -> event.pointsScored > 0
                is GameHistoryEvent.HandCounted -> event.totalPoints >= 10
                is GameHistoryEvent.CribCounted -> event.totalPoints >= 10
                is GameHistoryEvent.GameEnded -> true
                else -> false
            }
        }
        
        println("\nSignificant events:")
        significantEvents.forEach { event ->
            when (event) {
                is GameHistoryEvent.DeckCut -> println("  - Jack cut for nobs!")
                is GameHistoryEvent.CardPlayed -> println("  - ${event.playerId} scored ${event.pointsScored} in pegging (${event.scoringReason})")
                is GameHistoryEvent.HandCounted -> println("  - ${event.playerId} scored ${event.totalPoints} in hand counting")
                is GameHistoryEvent.CribCounted -> println("  - ${event.dealerPlayerId} scored ${event.totalPoints} in crib")
                is GameHistoryEvent.GameEnded -> println("  - Game won by ${event.winnerPlayerId} with ${event.finalScore} points!")
                else -> {}
            }
        }
    }
    
    /**
     * Example of analyzing hand counting patterns
     */
    fun analyzeHandCountingPatterns(history: List<GameHistoryEvent>) {
        val handCountingEvents = history.filterIsInstance<GameHistoryEvent.HandCounted>()
        
        println("\n=== HAND COUNTING ANALYSIS ===")
        
        // Average points per hand
        val avgPoints = handCountingEvents.map { it.totalPoints }.average()
        println("Average points per hand: ${"%.1f".format(avgPoints)}")
        
        // Breakdown analysis
        val breakdowns = handCountingEvents.map { it.scoreBreakdown }
        val avgFifteens = breakdowns.map { it.fifteens }.average()
        val avgPairs = breakdowns.map { it.pairs }.average()
        val avgRuns = breakdowns.map { it.runs }.average()
        val avgFlushes = breakdowns.map { it.flushes }.average()
        val avgNobs = breakdowns.map { it.nobs }.average()
        
        println("Average points from:")
        println("  - Fifteens: ${"%.1f".format(avgFifteens)}")
        println("  - Pairs: ${"%.1f".format(avgPairs)}")
        println("  - Runs: ${"%.1f".format(avgRuns)}")
        println("  - Flushes: ${"%.1f".format(avgFlushes)}")
        println("  - Nobs: ${"%.1f".format(avgNobs)}")
        
        // High-scoring hands
        val highScoringHands = handCountingEvents.filter { it.totalPoints >= 15 }
        println("\nHigh-scoring hands (15+ points): ${highScoringHands.size}")
        highScoringHands.forEach { event ->
            println("  - ${event.playerId}: ${event.totalPoints} points")
        }
    }
}