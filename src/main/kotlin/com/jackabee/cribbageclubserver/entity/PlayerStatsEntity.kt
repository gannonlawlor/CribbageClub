package com.jackabee.cribbageclubserver.entity

import jakarta.persistence.*
import java.time.Instant

@Entity
@Table(name = "player_stats")
class PlayerStatsEntity(
    @Id
    val playerId: String,

    @Column(nullable = false)
    var gamesPlayed: Int = 0,

    @Column(nullable = false)
    var gamesWon: Int = 0,

    @Column(nullable = false)
    var gamesLost: Int = 0,

    @Column(nullable = false)
    var totalPointsScored: Long = 0,

    @Column(nullable = false)
    var totalPointsAgainst: Long = 0,

    @Column(nullable = false)
    var highestGameScore: Int = 0,

    @Column(nullable = false)
    var currentWinStreak: Int = 0,

    @Column(nullable = false)
    var longestWinStreak: Int = 0,

    @Column(nullable = false)
    var rating: Double = 1500.0,

    @Column(nullable = false)
    var ratingDeviation: Double = 350.0,

    @Column(nullable = false)
    var ratingVolatility: Double = 0.06,

    @Column(nullable = false)
    val createdAt: Instant = Instant.now(),

    @Column(nullable = false)
    var updatedAt: Instant = Instant.now(),

    @Version
    var version: Long = 0
) {
    val winRate: Double
        get() = if (gamesPlayed > 0) gamesWon.toDouble() / gamesPlayed else 0.0

    val averageScore: Double
        get() = if (gamesPlayed > 0) totalPointsScored.toDouble() / gamesPlayed else 0.0
}
