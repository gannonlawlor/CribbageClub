package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.service.PlayerStatsService
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/stats")
class StatsController(
    private val playerStatsService: PlayerStatsService
) {
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

    @GetMapping("/leaderboard")
    fun getLeaderboard(): List<StatsResponse> {
        return playerStatsService.getLeaderboard().map { stats ->
            StatsResponse(
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
