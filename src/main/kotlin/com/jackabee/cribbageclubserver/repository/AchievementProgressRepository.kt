package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.AchievementProgressEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface AchievementProgressRepository : JpaRepository<AchievementProgressEntity, String>
