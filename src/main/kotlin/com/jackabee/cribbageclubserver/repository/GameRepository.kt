package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.GameEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository

@Repository
interface GameRepository : JpaRepository<GameEntity, String> {
    fun findByStageNot(stage: String): List<GameEntity>
    fun findByPlayer1IdOrPlayer2Id(player1Id: String, player2Id: String): List<GameEntity>
    fun findByWinnerIdIsNull(): List<GameEntity>

    @Query("SELECT g FROM GameEntity g WHERE (g.player1Id = :playerId OR g.player2Id = :playerId) AND g.winnerId IS NULL")
    fun findActiveGamesByPlayer(playerId: String): List<GameEntity>

    @Query("SELECT g FROM GameEntity g WHERE (g.player1Id = :playerId OR g.player2Id = :playerId) AND g.winnerId IS NOT NULL ORDER BY g.updatedAt DESC")
    fun findCompletedGamesByPlayer(playerId: String): List<GameEntity>
}
