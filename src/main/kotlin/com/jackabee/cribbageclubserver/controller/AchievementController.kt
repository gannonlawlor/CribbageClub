package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.model.achievement.Achievement
import com.jackabee.cribbageclubserver.service.AchievementService
import com.jackabee.cribbageclubserver.service.AchievementStatus
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.web.bind.annotation.*
import java.time.Instant

data class AchievementDto(
    val key: String,
    val name: String,
    val description: String,
    val tier: String,
    val target: Int?,
    val progress: Int? = null,
    val unlocked: Boolean = false,
    val unlockedAt: Instant? = null,
    val sortOrder: Int
) {
    companion object {
        fun from(achievement: Achievement): AchievementDto = AchievementDto(
            key = achievement.name,
            name = achievement.displayName,
            description = achievement.description,
            tier = achievement.tier.name,
            target = achievement.target,
            unlocked = true,
            sortOrder = achievement.ordinal
        )

        fun from(status: AchievementStatus): AchievementDto = AchievementDto(
            key = status.achievement.name,
            name = status.achievement.displayName,
            description = status.achievement.description,
            tier = status.achievement.tier.name,
            target = status.achievement.target,
            progress = status.progress,
            unlocked = status.unlocked,
            unlockedAt = status.unlockedAt,
            sortOrder = status.achievement.ordinal
        )
    }
}

data class PlayerAchievementsResponse(
    val achievements: List<AchievementDto>,
    val unlockedCount: Int,
    val totalCount: Int
)

@RestController
@Tag(name = "Achievements", description = "Achievement catalog and player unlocks")
class AchievementController(
    private val achievementService: AchievementService
) {
    @Operation(summary = "Get the achievement catalog")
    @GetMapping("/api/achievements")
    fun getCatalog(): List<AchievementDto> = Achievement.entries.map {
        AchievementDto(
            key = it.name,
            name = it.displayName,
            description = it.description,
            tier = it.tier.name,
            target = it.target,
            sortOrder = it.ordinal
        )
    }

    @Operation(summary = "Get a player's achievements with progress")
    @GetMapping("/api/profiles/{userId}/achievements")
    fun getPlayerAchievements(@PathVariable userId: String): PlayerAchievementsResponse {
        val statuses = achievementService.getAchievementsFor(userId)
        return PlayerAchievementsResponse(
            achievements = statuses.map { AchievementDto.from(it) },
            unlockedCount = statuses.count { it.unlocked },
            totalCount = statuses.size
        )
    }
}
