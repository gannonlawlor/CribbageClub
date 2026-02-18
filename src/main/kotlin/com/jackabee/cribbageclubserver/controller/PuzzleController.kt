package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.model.card.Card
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
    private val puzzleService: PuzzleService
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
}

data class SolvePuzzleRequest(
    val chosenDiscard: List<Card>
)
