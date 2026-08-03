package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.PlayerStatsEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface PlayerStatsRepository : JpaRepository<PlayerStatsEntity, String> {

    @Query("SELECT p FROM PlayerStatsEntity p WHERE p.playerId NOT LIKE :prefix1 AND p.playerId NOT LIKE :prefix2 ORDER BY p.rating DESC LIMIT 10")
    fun findTop10ExcludingPrefixes(prefix1: String, prefix2: String): List<PlayerStatsEntity>

    /** Leaderboard: excludes id-prefixed engines/guests and pool bots (UUID ids, is_bot flag). */
    @Query("""
        SELECT p FROM PlayerStatsEntity p
        WHERE p.playerId NOT LIKE :prefix1 AND p.playerId NOT LIKE :prefix2
        AND NOT EXISTS (SELECT 1 FROM UserEntity u WHERE u.id = p.playerId AND u.isBot = true)
        ORDER BY p.rating DESC LIMIT 10
    """)
    fun findTop10ExcludingPrefixesAndBots(prefix1: String, prefix2: String): List<PlayerStatsEntity>
}
