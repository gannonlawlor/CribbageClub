package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.PlayerStatsEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface PlayerStatsRepository : JpaRepository<PlayerStatsEntity, String> {
    fun findTop10ByOrderByGamesWonDesc(): List<PlayerStatsEntity>
    fun findTop10ByOrderByLongestWinStreakDesc(): List<PlayerStatsEntity>

    @Query("SELECT p FROM PlayerStatsEntity p WHERE p.playerId NOT LIKE :prefix ORDER BY p.gamesWon DESC LIMIT 10")
    fun findTop10ExcludingPrefix(prefix: String): List<PlayerStatsEntity>

    @Query("SELECT p FROM PlayerStatsEntity p WHERE p.playerId NOT LIKE :prefix1 AND p.playerId NOT LIKE :prefix2 ORDER BY p.rating DESC LIMIT 10")
    fun findTop10ExcludingPrefixes(prefix1: String, prefix2: String): List<PlayerStatsEntity>
}
