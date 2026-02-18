package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.repository.UserRepository
import com.jackabee.cribbageclubserver.service.PlayerStatsService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/stats")
@Tag(name = "Player Stats", description = "Player statistics and leaderboard")
class StatsController(
    private val playerStatsService: PlayerStatsService,
    private val userRepository: UserRepository
) {
    @Operation(summary = "Get stats for the authenticated user")
    @GetMapping("/me")
    fun getMyStats(@RequestAttribute("userId") userId: String): StatsResponse {
        val stats = playerStatsService.getStats(userId)
        return StatsResponse(
            playerId = stats.playerId,
            gamesPlayed = stats.gamesPlayed,
            gamesWon = stats.gamesWon,
            gamesLost = stats.gamesLost,
            winRate = stats.winRate,
            averageScore = stats.averageScore,
            highestGameScore = stats.highestGameScore,
            currentWinStreak = stats.currentWinStreak,
            longestWinStreak = stats.longestWinStreak
        )
    }

    @Operation(summary = "Get stats for a specific player")
    @GetMapping("/{playerId}")
    fun getPlayerStats(@PathVariable playerId: String): StatsResponse {
        val stats = playerStatsService.getStats(playerId)
        return StatsResponse(
            playerId = stats.playerId,
            gamesPlayed = stats.gamesPlayed,
            gamesWon = stats.gamesWon,
            gamesLost = stats.gamesLost,
            winRate = stats.winRate,
            averageScore = stats.averageScore,
            highestGameScore = stats.highestGameScore,
            currentWinStreak = stats.currentWinStreak,
            longestWinStreak = stats.longestWinStreak
        )
    }

    @Operation(summary = "Get top 10 leaderboard (public)")
    @GetMapping("/leaderboard")
    fun getLeaderboard(): List<LeaderboardEntry> {
        val statsList = playerStatsService.getLeaderboard()
        val playerIds = statsList.map { it.playerId }
        val users = userRepository.findAllById(playerIds).associateBy { it.id }

        return statsList.map { stats ->
            val user = users[stats.playerId]
            LeaderboardEntry(
                playerId = stats.playerId,
                displayName = user?.displayName ?: stats.playerId,
                gamesPlayed = stats.gamesPlayed,
                gamesWon = stats.gamesWon,
                gamesLost = stats.gamesLost,
                winRate = stats.winRate,
                averageScore = stats.averageScore,
                highestGameScore = stats.highestGameScore,
                currentWinStreak = stats.currentWinStreak,
                longestWinStreak = stats.longestWinStreak
            )
        }
    }
}

data class StatsResponse(
    val playerId: String,
    val gamesPlayed: Int,
    val gamesWon: Int,
    val gamesLost: Int,
    val winRate: Double,
    val averageScore: Double,
    val highestGameScore: Int,
    val currentWinStreak: Int,
    val longestWinStreak: Int
)

data class LeaderboardEntry(
    val playerId: String,
    val displayName: String,
    val gamesPlayed: Int,
    val gamesWon: Int,
    val gamesLost: Int,
    val winRate: Double,
    val averageScore: Double,
    val highestGameScore: Int,
    val currentWinStreak: Int,
    val longestWinStreak: Int
)
