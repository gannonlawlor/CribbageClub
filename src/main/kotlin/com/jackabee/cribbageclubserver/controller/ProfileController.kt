package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.repository.FriendshipRepository
import com.jackabee.cribbageclubserver.repository.UserRepository
import com.jackabee.cribbageclubserver.service.PlayerStatsService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.web.bind.annotation.*
import java.time.Instant

@RestController
@RequestMapping("/api/profiles")
@Tag(name = "Profiles", description = "Public user profiles")
class ProfileController(
    private val userRepository: UserRepository,
    private val playerStatsService: PlayerStatsService,
    private val friendshipRepository: FriendshipRepository
) {
    @Operation(summary = "Get a user's public profile")
    @GetMapping("/{userId}")
    fun getProfile(
        @PathVariable userId: String,
        @RequestAttribute("userId", required = false) viewerId: String?
    ): ProfileResponse {
        val user = userRepository.findById(userId).orElseThrow {
            IllegalArgumentException("User not found")
        }
        val stats = playerStatsService.getStats(userId)

        val relationshipStatus = if (viewerId != null && viewerId != userId) {
            val friendship = friendshipRepository.findBetween(viewerId, userId)
            when {
                friendship == null -> null
                friendship.status == "ACCEPTED" -> "FRIENDS"
                friendship.requesterId == viewerId && friendship.status == "PENDING" -> "PENDING_SENT"
                friendship.addresseeId == viewerId && friendship.status == "PENDING" -> "PENDING_RECEIVED"
                else -> null
            }
        } else null

        return ProfileResponse(
            userId = user.id!!,
            username = user.username,
            displayName = user.displayName,
            avatarIndex = user.avatarIndex,
            createdAt = user.createdAt,
            relationshipStatus = relationshipStatus,
            rating = stats.rating,
            ratingDeviation = stats.ratingDeviation,
            overallStats = CategoryStats(
                gamesPlayed = stats.gamesPlayed,
                gamesWon = stats.gamesWon,
                gamesLost = stats.gamesLost,
                winRate = stats.winRate,
                averageScore = stats.averageScore
            ),
            aiStats = CategoryStats(
                gamesPlayed = stats.aiGamesPlayed,
                gamesWon = stats.aiGamesWon,
                gamesLost = stats.aiGamesLost,
                winRate = stats.aiWinRate,
                averageScore = stats.aiAverageScore
            ),
            humanStats = CategoryStats(
                gamesPlayed = stats.humanGamesPlayed,
                gamesWon = stats.humanGamesWon,
                gamesLost = stats.humanGamesLost,
                winRate = stats.humanWinRate,
                averageScore = stats.humanAverageScore
            )
        )
    }
}

data class ProfileResponse(
    val userId: String,
    val username: String,
    val displayName: String?,
    val avatarIndex: Int?,
    val createdAt: Instant,
    val relationshipStatus: String?,
    val rating: Double,
    val ratingDeviation: Double,
    val overallStats: CategoryStats,
    val aiStats: CategoryStats,
    val humanStats: CategoryStats
)

data class CategoryStats(
    val gamesPlayed: Int,
    val gamesWon: Int,
    val gamesLost: Int,
    val winRate: Double,
    val averageScore: Double
)
