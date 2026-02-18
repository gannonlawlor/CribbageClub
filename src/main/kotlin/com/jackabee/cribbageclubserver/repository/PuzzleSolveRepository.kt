package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.PuzzleSolveEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface PuzzleSolveRepository : JpaRepository<PuzzleSolveEntity, String> {
    fun findByPuzzleIdAndUserId(puzzleId: String, userId: String): PuzzleSolveEntity?
    fun countByUserIdAndIsOptimalTrue(userId: String): Long
}
