package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.bridge.RustEngineAdapter
import com.jackabee.cribbageclubserver.entity.GameEntity
import com.jackabee.cribbageclubserver.entity.PlayerStatsEntity
import com.jackabee.cribbageclubserver.model.rating.Glicko2Rating
import com.jackabee.cribbageclubserver.repository.PlayerStatsRepository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant

/**
 * Outcome of a rated game's Glicko-2 update: each side's new rating and how
 * much this game moved it. Returned by [PlayerStatsService.recordGameResult]
 * (null for unrated games) so game rows can freeze the result for history.
 */
data class RatingUpdate(
    val winnerRating: Double,
    val winnerDelta: Double,
    val loserRating: Double,
    val loserDelta: Double,
) {
    /** Stamps the outcome onto the game row, mapping winner/loser to player1/2. */
    fun applyTo(entity: GameEntity, winnerId: String) {
        val winnerIsPlayer1 = winnerId == entity.player1Id
        entity.player1RatingAfter = if (winnerIsPlayer1) winnerRating else loserRating
        entity.player1RatingDelta = if (winnerIsPlayer1) winnerDelta else loserDelta
        entity.player2RatingAfter = if (winnerIsPlayer1) loserRating else winnerRating
        entity.player2RatingDelta = if (winnerIsPlayer1) loserDelta else winnerDelta
    }
}

@Service
class PlayerStatsService(
    private val playerStatsRepository: PlayerStatsRepository,
    private val rustEngineAdapter: RustEngineAdapter
) {
    private val logger = LoggerFactory.getLogger(PlayerStatsService::class.java)

    fun getStats(playerId: String): PlayerStatsEntity {
        return playerStatsRepository.findById(playerId)
            .orElse(PlayerStatsEntity(playerId = playerId))
    }

    @Transactional
    fun recordGameResult(
        winnerId: String,
        loserId: String,
        winnerScore: Int,
        loserScore: Int,
        isAIGame: Boolean = false
    ): RatingUpdate? {
        val winnerStats = getOrCreate(winnerId)
        winnerStats.gamesPlayed++
        winnerStats.gamesWon++
        winnerStats.totalPointsScored += winnerScore
        winnerStats.totalPointsAgainst += loserScore
        if (winnerScore > winnerStats.highestGameScore) {
            winnerStats.highestGameScore = winnerScore
        }
        winnerStats.currentWinStreak++
        if (winnerStats.currentWinStreak > winnerStats.longestWinStreak) {
            winnerStats.longestWinStreak = winnerStats.currentWinStreak
        }
        winnerStats.updatedAt = Instant.now()

        // Split stats
        if (isAIGame) {
            winnerStats.aiGamesPlayed++
            winnerStats.aiGamesWon++
            winnerStats.aiTotalPointsScored += winnerScore
            winnerStats.aiTotalPointsAgainst += loserScore
        } else {
            winnerStats.humanGamesPlayed++
            winnerStats.humanGamesWon++
            winnerStats.humanTotalPointsScored += winnerScore
            winnerStats.humanTotalPointsAgainst += loserScore
        }

        val loserStats = getOrCreate(loserId)
        loserStats.gamesPlayed++
        loserStats.gamesLost++
        loserStats.totalPointsScored += loserScore
        loserStats.totalPointsAgainst += winnerScore
        if (loserScore > loserStats.highestGameScore) {
            loserStats.highestGameScore = loserScore
        }
        loserStats.currentWinStreak = 0
        loserStats.updatedAt = Instant.now()

        // Split stats
        if (isAIGame) {
            loserStats.aiGamesPlayed++
            loserStats.aiGamesLost++
            loserStats.aiTotalPointsScored += loserScore
            loserStats.aiTotalPointsAgainst += winnerScore
        } else {
            loserStats.humanGamesPlayed++
            loserStats.humanGamesLost++
            loserStats.humanTotalPointsScored += loserScore
            loserStats.humanTotalPointsAgainst += winnerScore
        }

        // Update Glicko-2 ratings for non-AI, non-guest games
        val isRated = !winnerId.startsWith("ai_") && !winnerId.startsWith("guest_") &&
                !loserId.startsWith("ai_") && !loserId.startsWith("guest_")
        val ratingUpdate = if (isRated) updateRatings(winnerStats, loserStats) else null

        // The engine has no profile and is excluded from every leaderboard, so
        // its row is never read — and two imports of games against the same
        // engine id race each other to insert it, failing the whole import.
        if (!winnerId.startsWith("ai_")) playerStatsRepository.save(winnerStats)
        if (!loserId.startsWith("ai_")) playerStatsRepository.save(loserStats)

        logger.info("Recorded game result: {} beat {} ({}-{}){}",
            winnerId, loserId, winnerScore, loserScore,
            if (isRated) " [rated]" else " [unrated]")

        return ratingUpdate
    }

    fun getLeaderboard(): List<PlayerStatsEntity> {
        return playerStatsRepository.findTop10ExcludingPrefixesAndBots("ai_%", "guest_%")
    }

    /** Applies the Glicko-2 update to both stat rows and reports the outcome. */
    private fun updateRatings(
        winnerStats: PlayerStatsEntity,
        loserStats: PlayerStatsEntity,
    ): RatingUpdate {
        val winnerBefore = winnerStats.rating
        val loserBefore = loserStats.rating
        val winnerRating = Glicko2Rating(
            winnerStats.rating, winnerStats.ratingDeviation, winnerStats.ratingVolatility
        )
        val loserRating = Glicko2Rating(
            loserStats.rating, loserStats.ratingDeviation, loserStats.ratingVolatility
        )

        val winnerResult = rustEngineAdapter.calculateGlicko2(winnerRating, loserRating, 1.0)
        val loserResult = rustEngineAdapter.calculateGlicko2(loserRating, winnerRating, 0.0)

        winnerStats.rating = winnerResult.newRating
        winnerStats.ratingDeviation = winnerResult.newDeviation
        winnerStats.ratingVolatility = winnerResult.newVolatility

        loserStats.rating = loserResult.newRating
        loserStats.ratingDeviation = loserResult.newDeviation
        loserStats.ratingVolatility = loserResult.newVolatility

        return RatingUpdate(
            winnerRating = winnerStats.rating,
            winnerDelta = winnerStats.rating - winnerBefore,
            loserRating = loserStats.rating,
            loserDelta = loserStats.rating - loserBefore,
        )
    }

    private fun getOrCreate(playerId: String): PlayerStatsEntity {
        return playerStatsRepository.findById(playerId)
            .orElse(PlayerStatsEntity(playerId = playerId))
    }
}
