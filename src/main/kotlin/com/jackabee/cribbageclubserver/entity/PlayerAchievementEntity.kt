package com.jackabee.cribbageclubserver.entity

import jakarta.persistence.*
import java.time.Instant

@Entity
@Table(
    name = "player_achievements",
    uniqueConstraints = [UniqueConstraint(columnNames = ["user_id", "achievement_key"])]
)
class PlayerAchievementEntity(
    @Id
    val id: String,

    @Column(name = "user_id", nullable = false)
    val userId: String,

    @Column(name = "achievement_key", nullable = false)
    val achievementKey: String,

    @Column(name = "unlocked_at", nullable = false)
    val unlockedAt: Instant = Instant.now(),

    @Column(name = "game_id")
    val gameId: String? = null
)
