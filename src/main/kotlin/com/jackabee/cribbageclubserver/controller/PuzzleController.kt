package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.service.AchievementService
import com.jackabee.cribbageclubserver.service.PuzzleResponse
import com.jackabee.cribbageclubserver.service.PuzzleService
import com.jackabee.cribbageclubserver.service.PuzzleSolveResponse
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/puzzles")
@Tag(name = "Daily Puzzles", description = "Daily discard puzzle endpoints")
class PuzzleController(
    private val puzzleService: PuzzleService,
    private val achievementService: AchievementService
) {
    @Operation(summary = "Get today's daily puzzle")
    @GetMapping("/daily")
    fun getDailyPuzzle(@RequestAttribute("userId") userId: String): PuzzleResponse {
        return puzzleService.getDailyPuzzle(userId)
    }

    @Operation(summary = "Submit a puzzle solve")
    @PostMapping("/{puzzleId}/solve")
    fun solvePuzzle(
        @PathVariable puzzleId: String,
        @RequestAttribute("userId") userId: String,
        @RequestBody request: SolvePuzzleRequest
    ): PuzzleSolveResponse {
        return puzzleService.solvePuzzle(puzzleId, userId, request.chosenDiscard)
    }

    /**
     * The mobile daily puzzle runs entirely on-device (deterministic seed +
     * local engine), so its solves never pass through [solvePuzzle]. The
     * client reports each finished puzzle here for achievement credit.
     * Client-trusted by design — the stakes are an achievement, not a rating.
     */
    @Operation(summary = "Report an on-device daily puzzle solve")
    @PostMapping("/daily/report")
    fun reportLocalSolve(
        @RequestAttribute("userId") userId: String,
        @RequestBody request: ReportPuzzleSolveRequest
    ): ReportPuzzleSolveResponse {
        val unlocked = achievementService.evaluatePuzzleSolve(userId, request.optimal)
        return ReportPuzzleSolveResponse(unlocked.map { AchievementDto.from(it) })
    }
}

data class SolvePuzzleRequest(
    val chosenDiscard: List<Card>
)

data class ReportPuzzleSolveRequest(
    val optimal: Boolean
)

data class ReportPuzzleSolveResponse(
    val unlockedAchievements: List<AchievementDto>
)
