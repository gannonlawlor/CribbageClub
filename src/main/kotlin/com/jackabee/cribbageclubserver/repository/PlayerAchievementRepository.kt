package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.PlayerAchievementEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface PlayerAchievementRepository : JpaRepository<PlayerAchievementEntity, String> {
    fun findByUserId(userId: String): List<PlayerAchievementEntity>
    fun findByUserIdAndAchievementKeyIn(userId: String, keys: Collection<String>): List<PlayerAchievementEntity>
}
