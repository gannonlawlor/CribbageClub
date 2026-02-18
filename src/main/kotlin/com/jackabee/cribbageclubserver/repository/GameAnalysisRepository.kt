package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.GameAnalysisEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface GameAnalysisRepository : JpaRepository<GameAnalysisEntity, String>
