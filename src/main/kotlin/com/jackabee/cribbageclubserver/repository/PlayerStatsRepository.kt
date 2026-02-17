package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.PlayerStatsEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface PlayerStatsRepository : JpaRepository<PlayerStatsEntity, String> {
    fun findTop10ByOrderByGamesWonDesc(): List<PlayerStatsEntity>
    fun findTop10ByOrderByLongestWinStreakDesc(): List<PlayerStatsEntity>
}
