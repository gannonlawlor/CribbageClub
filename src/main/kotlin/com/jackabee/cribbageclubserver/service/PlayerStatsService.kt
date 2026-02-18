package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.entity.PlayerStatsEntity
import com.jackabee.cribbageclubserver.repository.PlayerStatsRepository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant

@Service
class PlayerStatsService(
    private val playerStatsRepository: PlayerStatsRepository
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
        loserScore: Int
    ) {
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

        playerStatsRepository.save(winnerStats)
        playerStatsRepository.save(loserStats)

        logger.info("Recorded game result: {} beat {} ({}-{})", winnerId, loserId, winnerScore, loserScore)
    }

    fun getLeaderboard(): List<PlayerStatsEntity> {
        return playerStatsRepository.findTop10ExcludingPrefixes("ai_%", "guest_%")
    }

    private fun getOrCreate(playerId: String): PlayerStatsEntity {
        return playerStatsRepository.findById(playerId)
            .orElse(PlayerStatsEntity(playerId = playerId))
    }
}
