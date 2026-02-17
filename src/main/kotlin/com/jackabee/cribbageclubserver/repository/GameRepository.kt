package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.GameEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface GameRepository : JpaRepository<GameEntity, String> {
    fun findByStageNot(stage: String): List<GameEntity>
    fun findByPlayer1IdOrPlayer2Id(player1Id: String, player2Id: String): List<GameEntity>
    fun findByWinnerIdIsNull(): List<GameEntity>
}
