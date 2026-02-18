package com.jackabee.cribbageclubserver.entity

import jakarta.persistence.*
import java.time.Instant
import java.time.LocalDate

@Entity
@Table(name = "puzzles")
class PuzzleEntity(
    @Id
    val id: String,

    @Column(name = "hand_json", nullable = false)
    val handJson: String,

    @Column(name = "is_dealer", nullable = false)
    val isDealer: Boolean,

    @Column(name = "optimal_discard_json", nullable = false)
    val optimalDiscardJson: String,

    @Column(name = "optimal_ev", nullable = false)
    val optimalEv: Double,

    @Column(name = "created_at", nullable = false)
    val createdAt: Instant = Instant.now(),

    @Column(name = "puzzle_date", nullable = false, unique = true)
    val puzzleDate: LocalDate
)
