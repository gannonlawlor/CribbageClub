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

    @Column(nullable = false)
    var aiGamesPlayed: Int = 0,

    @Column(nullable = false)
    var aiGamesWon: Int = 0,

    @Column(nullable = false)
    var aiGamesLost: Int = 0,

    @Column(nullable = false)
    var aiTotalPointsScored: Long = 0,

    @Column(nullable = false)
    var aiTotalPointsAgainst: Long = 0,

    @Column(nullable = false)
    var humanGamesPlayed: Int = 0,

    @Column(nullable = false)
    var humanGamesWon: Int = 0,

    @Column(nullable = false)
    var humanGamesLost: Int = 0,

    @Column(nullable = false)
    var humanTotalPointsScored: Long = 0,

    @Column(nullable = false)
    var humanTotalPointsAgainst: Long = 0,

    @Version
    var version: Long = 0
) {
    val winRate: Double
        get() = if (gamesPlayed > 0) gamesWon.toDouble() / gamesPlayed else 0.0

    val averageScore: Double
        get() = if (gamesPlayed > 0) totalPointsScored.toDouble() / gamesPlayed else 0.0

    val aiWinRate: Double
        get() = if (aiGamesPlayed > 0) aiGamesWon.toDouble() / aiGamesPlayed else 0.0

    val aiAverageScore: Double
        get() = if (aiGamesPlayed > 0) aiTotalPointsScored.toDouble() / aiGamesPlayed else 0.0

    val humanWinRate: Double
        get() = if (humanGamesPlayed > 0) humanGamesWon.toDouble() / humanGamesPlayed else 0.0

    val humanAverageScore: Double
        get() = if (humanGamesPlayed > 0) humanTotalPointsScored.toDouble() / humanGamesPlayed else 0.0
}
