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
    fun getGameState(@PathVariable gameId: String): ResponseEntity<GameState> {
        return try {
            val gameState = gameService.getGameState(gameId)
            ResponseEntity.ok(gameState)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        }
    }
    
    /**
     * Applies an action to a game.
     */
    @PostMapping("/{gameId}/actions")
    fun applyAction(
        @PathVariable gameId: String,
        @RequestBody action: GameAction
    ): ResponseEntity<GameState> {
        return try {
            val gameState = gameService.applyHumanAction(gameId, action)
            ResponseEntity.ok(gameState)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.badRequest().build()
        }
    }
    
    /**
     * Lists all active games.
     */
    @GetMapping
    fun listGames(): ResponseEntity<Map<String, GameState>> {
        val games = gameService.listGames()
        return ResponseEntity.ok(games)
    }
}