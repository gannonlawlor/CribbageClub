package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.model.action.ForfeitReason
import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.analysis.GameAnalysis
import com.jackabee.cribbageclubserver.model.game.GameResponse
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.game.GameStateFilter
import com.jackabee.cribbageclubserver.service.AnalysisService
import com.jackabee.cribbageclubserver.service.ForfeitService
import com.jackabee.cribbageclubserver.service.GameService
import com.jackabee.cribbageclubserver.service.TurnTimerService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/games")
@Tag(name = "Games", description = "Game CRUD and gameplay actions")
class GameController(
    private val gameService: GameService,
    private val analysisService: AnalysisService,
    private val forfeitService: ForfeitService,
    private val turnTimerService: TurnTimerService
) {

    @Operation(summary = "Get current game state with timing info")
    @GetMapping("/{gameId}")
    fun getGameState(
        @PathVariable gameId: String,
        @RequestAttribute("userId") userId: String
    ): GameResponse {
        val state = gameService.getGameState(gameId)
        val entity = gameService.getGameEntity(gameId)
        return if (entity != null) {
            turnTimerService.buildGameResponse(gameId, entity, state, userId)
        } else {
            GameResponse(gameState = GameStateFilter.forPlayer(state, userId))
        }
    }

    @Operation(summary = "Get post-game discard analysis", description = "Returns EV analysis of every discard decision. Only available for completed games.")
    @GetMapping("/{gameId}/analysis")
    fun getGameAnalysis(
        @PathVariable gameId: String,
        @RequestAttribute("userId") userId: String
    ): GameAnalysis {
        val state = gameService.getGameState(gameId)
        require(state.players.any { it.id == userId }) { "You are not a participant in this game" }
        return analysisService.analyzeGame(gameId)
    }

    @Operation(summary = "Upload client-computed analysis", description = "Saves analysis computed on-device to the server cache.")
    @PostMapping("/{gameId}/analysis")
    fun saveGameAnalysis(
        @PathVariable gameId: String,
        @RequestBody analysis: GameAnalysis,
        @RequestAttribute("userId") userId: String
    ): ResponseEntity<Void> {
        val state = gameService.getGameState(gameId)
        require(state.players.any { it.id == userId }) { "You are not a participant in this game" }
        analysisService.saveAnalysis(gameId, analysis)
        return ResponseEntity.ok().build()
    }

    @Operation(summary = "Apply a game action (discard, play card, cut, count, go, forfeit)")
    @PostMapping("/{gameId}/actions")
    fun applyAction(
        @PathVariable gameId: String,
        @RequestBody action: GameAction,
        @RequestAttribute("userId") userId: String
    ): GameResponse {
        val state = gameService.applyHumanAction(gameId, action)
        val entity = gameService.getGameEntity(gameId)
        return if (entity != null) {
            turnTimerService.buildGameResponse(gameId, entity, state, userId)
        } else {
            GameResponse(gameState = GameStateFilter.forPlayer(state, userId))
        }
    }

    @Operation(summary = "Resign from a game")
    @PostMapping("/{gameId}/resign")
    fun resignGame(
        @PathVariable gameId: String,
        @RequestAttribute("userId") userId: String
    ): GameResponse {
        val state = forfeitService.forfeitGame(gameId, userId, ForfeitReason.RESIGN)
        val entity = gameService.getGameEntity(gameId)
        return if (entity != null) {
            turnTimerService.buildGameResponse(gameId, entity, state, userId)
        } else {
            GameResponse(gameState = GameStateFilter.forPlayer(state, userId))
        }
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

    @Operation(summary = "Import completed local games to the server")
    @PostMapping("/import")
    fun importLocalGames(
        @RequestBody request: ImportGamesRequest,
        @RequestAttribute("userId") userId: String,
        @RequestAttribute("username") username: String
    ): ImportGamesResponse {
        return gameService.importLocalGames(request.games, userId, username)
    }
}

data class CreateAIGameRequest(
    val playerName: String? = null,
    val difficulty: String? = null
)

data class ImportGameRequest(
    val localGameId: String,
    val stateJson: String,
    val completedAt: String? = null
)

data class ImportGamesRequest(
    val games: List<ImportGameRequest>
)

data class ImportedGameMapping(
    val localGameId: String,
    val serverGameId: String
)

data class ImportGamesResponse(
    val imported: List<ImportedGameMapping>,
    val duplicates: List<String>,
    val errors: List<String>
)
