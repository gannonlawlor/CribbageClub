package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.service.GameService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/games")
class GameController(
    private val gameService: GameService
) {

    /**
     * Gets the current state of a game.
     */
    @GetMapping("/{gameId}")
    fun getGameState(@PathVariable gameId: String): GameState {
        return gameService.getGameState(gameId)
    }

    /**
     * Applies an action to a game.
     */
    @PostMapping("/{gameId}/actions")
    fun applyAction(
        @PathVariable gameId: String,
        @RequestBody action: GameAction,
        @RequestAttribute("userId") userId: String
    ): GameState {
        return gameService.applyHumanAction(gameId, action)
    }

    /**
     * Creates a new game against an AI opponent.
     * Uses the authenticated user as the human player.
     */
    @PostMapping("/ai")
    fun createGameWithAI(
        @RequestBody request: CreateAIGameRequest,
        @RequestAttribute("userId") userId: String,
        @RequestAttribute("username") username: String
    ): GameState {
        return gameService.createGameWithAI(
            humanPlayerId = userId,
            humanPlayerName = request.playerName ?: username,
            aiDifficulty = request.difficulty ?: "basic"
        )
    }

    /**
     * Deletes a game.
     */
    @DeleteMapping("/{gameId}")
    fun deleteGame(@PathVariable gameId: String): ResponseEntity<Void> {
        gameService.getGameState(gameId) // verify it exists, throws if not found
        gameService.removeGame(gameId)
        return ResponseEntity.noContent().build()
    }

    /**
     * Lists all active games.
     */
    @GetMapping
    fun listGames(): Map<String, GameState> {
        return gameService.listGames()
    }
}

data class CreateAIGameRequest(
    val playerName: String? = null,
    val difficulty: String? = null
)
