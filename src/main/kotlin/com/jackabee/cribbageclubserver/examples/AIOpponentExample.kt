package com.jackabee.cribbageclubserver.examples

import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.service.GameService

/**
 * Example demonstrating how to use the AI opponent in a cribbage game.
 * Requires a GameService instance (injected by Spring or provided in tests).
 */
class AIOpponentExample(private val gameService: GameService) {

    fun runExample() {
        // Create a game with AI opponent
        println("Creating game with AI opponent...")
        val gameState = gameService.createGameWithAI("human123", "Alice")
        val gameId = gameService.listGames().keys.first()

        println("Game created! Players:")
        gameState.players.forEach { player ->
            println("- ${player.name} (${player.id}): ${player.hand.size} cards")
        }

        println("\nGame stage: ${gameState.stage}")
        println("Current player: ${gameState.currentPlayerId}")

        // Example of playing a few turns
        if (gameState.stage == GameStage.DISCARDING_TO_CRIB) {
            println("\n--- Discarding Phase ---")

            // Find human player
            val humanPlayer = gameState.players.find { it.id == "human123" }
            if (humanPlayer != null && gameState.currentPlayerId == humanPlayer.id) {
                println("Human player's hand: ${humanPlayer.hand}")

                // Human player discards first card
                val cardToDiscard = humanPlayer.hand.first()
                println("Human discards: $cardToDiscard")

                val newState = gameService.applyHumanAction(gameId, GameAction.DiscardToCrib(humanPlayer.id, cardToDiscard))
                println("After human action - Current player: ${newState.currentPlayerId}")
                println("Crib now has: ${newState.crib.size} cards")
            }
        }

        // Show final game state
        val finalState = gameService.getGameState(gameId)
        println("\n--- Final State ---")
        println("Game stage: ${finalState.stage}")
        println("Current player: ${finalState.currentPlayerId}")
        println("Crib size: ${finalState.crib.size}")
        finalState.players.forEach { player ->
            println("${player.name}: ${player.hand.size} cards, ${player.score} points")
        }

        // Clean up
        gameService.removeGame(gameId)
        println("\nGame removed.")
    }
}
