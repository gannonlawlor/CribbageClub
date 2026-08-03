package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.GameEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface GameRepository : JpaRepository<GameEntity, String> {
    fun findByWinnerIdIsNull(): List<GameEntity>

    @Query("SELECT g FROM GameEntity g WHERE (g.player1Id = :playerId OR g.player2Id = :playerId) AND g.winnerId IS NULL")
    fun findActiveGamesByPlayer(playerId: String): List<GameEntity>

    @Query("SELECT g FROM GameEntity g WHERE (g.player1Id = :playerId OR g.player2Id = :playerId) AND g.winnerId IS NOT NULL ORDER BY g.updatedAt DESC")
    fun findCompletedGamesByPlayer(playerId: String): List<GameEntity>

    @Query("""
        SELECT g FROM GameEntity g
        WHERE ((g.player1Id = :playerA AND g.player2Id = :playerB)
            OR (g.player1Id = :playerB AND g.player2Id = :playerA))
        AND g.winnerId IS NOT NULL
        ORDER BY g.updatedAt DESC
    """)
    fun findCompletedGamesBetween(playerA: String, playerB: String): List<GameEntity>

    fun findByOriginalLocalGameId(originalLocalGameId: String): GameEntity?

    @Query("""
        SELECT g FROM GameEntity g
        WHERE g.winnerId IS NULL
        AND g.isAIGame = false
        AND g.turnStartedAt IS NOT NULL
        AND g.timeControl <> 'UNLIMITED'
    """)
    fun findActiveTimedGames(): List<GameEntity>
}
