package com.jackabee.cribbageclubserver.model.ai

import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.game.GameStage

/**
 * Interface for AI players that can make decisions during a cribbage game.
 */
interface AIPlayer {
    /**
     * The unique identifier for this AI player.
     */
    val playerId: String
    
    /**
     * The display name for this AI player.
     */
    val playerName: String
    
    /**
     * Determines the next action for the AI player given the current game state.
     * 
     * @param gameState The current state of the game
     * @return The action the AI wants to take, or null if no action is needed
     */
    fun getNextAction(gameState: GameState): GameAction?
    
    /**
     * Chooses cards to discard to the crib.
     * 
     * @param hand The AI player's current hand
     * @param isDealer Whether this AI player is the dealer
     * @return List of cards to discard (should be 2 cards)
     */
    fun chooseCardsToDiscard(hand: List<Card>, isDealer: Boolean): List<Card>
    
    /**
     * Chooses a card to play during the pegging phase.
     * 
     * @param hand The AI player's current hand
     * @param playedCards The cards already played in this pegging round
     * @param currentCount The current count in the pegging phase
     * @return The card to play, or null if should announce "go"
     */
    fun chooseCardToPlay(hand: List<Card>, playedCards: List<Card>, currentCount: Int): Card?
}