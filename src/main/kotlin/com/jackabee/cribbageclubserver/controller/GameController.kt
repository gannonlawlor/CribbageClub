package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.game.GameStateFilter
import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.service.GameService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/games")
@Tag(name = "Games", description = "Game CRUD and gameplay actions")
class GameController(
    private val gameService: GameService
) {

    @Operation(summary = "Get current game state")
    @GetMapping("/{gameId}")
    fun getGameState(
        @PathVariable gameId: String,
        @RequestAttribute("userId") userId: String
    ): GameState {
        val state = gameService.getGameState(gameId)
        return GameStateFilter.forPlayer(state, userId)
    }

    @Operation(summary = "Apply a game action (discard, play card, cut, count, go)")
    @PostMapping("/{gameId}/actions")
    fun applyAction(
        @PathVariable gameId: String,
        @RequestBody action: GameAction,
        @RequestAttribute("userId") userId: String
    ): GameState {
        val state = gameService.applyHumanAction(gameId, action)
        return GameStateFilter.forPlayer(state, userId)
    }

    @Operation(summary = "Create a game against an AI opponent", description = "Difficulty: basic, medium, or hard")
    @PostMapping("/ai")
    fun createGameWithAI(
        @RequestBody request: CreateAIGameRequest,
        @RequestAttribute("userId") userId: String,
        @RequestAttribute("username") username: String
    ): GameState {
        val state = gameService.createGameWithAI(
            humanPlayerId = userId,
            humanPlayerName = request.playerName ?: username,
            aiDifficulty = request.difficulty ?: "basic"
        )
        return GameStateFilter.forPlayer(state, userId)
    }

    @Operation(summary = "Delete a game")
    @DeleteMapping("/{gameId}")
    fun deleteGame(@PathVariable gameId: String): ResponseEntity<Void> {
        gameService.getGameState(gameId) // verify it exists, throws if not found
        gameService.removeGame(gameId)
        return ResponseEntity.noContent().build()
    }

    @Operation(summary = "List all active games")
    @GetMapping
    fun listGames(@RequestAttribute("userId") userId: String): Map<String, GameState> {
        return gameService.listGames().mapValues { (_, state) ->
            GameStateFilter.forPlayer(state, userId)
        }
    }

    @Operation(summary = "Get active games for the authenticated user")
    @GetMapping("/me")
    fun getMyActiveGames(@RequestAttribute("userId") userId: String): List<GameState> {
        return gameService.findActiveGamesByPlayer(userId).map { state ->
            GameStateFilter.forPlayer(state, userId)
        }
    }

    @Operation(summary = "Get completed game history for the authenticated user")
    @GetMapping("/me/history")
    fun getMyGameHistory(@RequestAttribute("userId") userId: String): List<GameState> {
        return gameService.findCompletedGamesByPlayer(userId).map { state ->
            GameStateFilter.forPlayer(state, userId)
        }
    }
}

data class CreateAIGameRequest(
    val playerName: String? = null,
    val difficulty: String? = null
)
