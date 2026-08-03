package com.jackabee.cribbageclubserver.entity

import jakarta.persistence.*
import java.time.Instant

/**
 * Post-launch counters for counter achievements. Deliberately separate from
 * lifetime player_stats: these start at zero at feature launch, so veterans
 * earn WINS_100 by playing, not by backfill.
 */
@Entity
@Table(name = "achievement_progress")
class AchievementProgressEntity(
    @Id
    @Column(name = "user_id")
    val userId: String,

    @Column(nullable = false)
    var wins: Int = 0,

    @Column(name = "current_win_streak", nullable = false)
    var currentWinStreak: Int = 0,

    @Column(name = "optimal_puzzle_solves", nullable = false)
    var optimalPuzzleSolves: Int = 0,

    @Column(name = "updated_at", nullable = false)
    var updatedAt: Instant = Instant.now(),

    @Version
    var version: Long = 0
)
