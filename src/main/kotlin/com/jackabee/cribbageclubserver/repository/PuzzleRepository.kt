package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.PuzzleEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.time.LocalDate

@Repository
interface PuzzleRepository : JpaRepository<PuzzleEntity, String> {
    fun findByPuzzleDate(puzzleDate: LocalDate): PuzzleEntity?
}
