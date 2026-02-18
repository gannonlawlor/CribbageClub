package com.jackabee.cribbageclubserver.entity

import jakarta.persistence.*
import java.time.Instant

@Entity
@Table(name = "game_analyses")
class GameAnalysisEntity(
    @Id
    @Column(name = "game_id")
    val gameId: String,

    @Column(name = "analysis_json", nullable = false, columnDefinition = "TEXT")
    val analysisJson: String,

    @Column(name = "created_at", nullable = false)
    val createdAt: Instant = Instant.now()
)
