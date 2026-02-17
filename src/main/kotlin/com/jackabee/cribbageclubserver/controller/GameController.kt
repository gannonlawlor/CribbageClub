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
        @RequestBody action: GameAction
    ): GameState {
        return gameService.applyHumanAction(gameId, action)
    }

    /**
     * Creates a new game against an AI opponent.
     */
    @PostMapping("/ai")
    fun createGameWithAI(@RequestBody request: CreateAIGameRequest): GameState {
        return gameService.createGameWithAI(
            humanPlayerId = request.playerId,
            humanPlayerName = request.playerName,
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
    val playerId: String,
    val playerName: String,
    val difficulty: String? = null
)
