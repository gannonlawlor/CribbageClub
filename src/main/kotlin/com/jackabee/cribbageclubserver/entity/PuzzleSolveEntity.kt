package com.jackabee.cribbageclubserver.entity

import jakarta.persistence.*
import java.time.Instant

@Entity
@Table(
    name = "puzzle_solves",
    uniqueConstraints = [UniqueConstraint(columnNames = ["puzzle_id", "user_id"])]
)
class PuzzleSolveEntity(
    @Id
    val id: String,

    @Column(name = "puzzle_id", nullable = false)
    val puzzleId: String,

    @Column(name = "user_id", nullable = false)
    val userId: String,

    @Column(name = "chosen_discard_json", nullable = false)
    val chosenDiscardJson: String,

    @Column(name = "is_optimal", nullable = false)
    val isOptimal: Boolean,

    @Column(name = "ev_diff", nullable = false)
    val evDiff: Double,

    @Column(name = "solved_at", nullable = false)
    val solvedAt: Instant = Instant.now()
)
