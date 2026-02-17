package com.jackabee.cribbageclubserver.entity

import jakarta.persistence.*
import java.time.Instant

/**
 * JPA entity that persists game snapshots to the database.
 * Active games still live in memory (the Game object holds mutable deck/round state),
 * but this entity stores the latest GameState snapshot after each action for
 * recovery and game history.
 */
@Entity
@Table(name = "games")
class GameEntity(
    @Id
    val id: String,

    @Column(nullable = false)
    val player1Id: String,

    @Column(nullable = false)
    val player1Name: String,

    @Column(nullable = false)
    val player2Id: String,

    @Column(nullable = false)
    val player2Name: String,

    @Column(nullable = false)
    var player1Score: Int = 0,

    @Column(nullable = false)
    var player2Score: Int = 0,

    @Column(nullable = false)
    var stage: String = "DEALING",

    @Column(nullable = true)
    var currentPlayerId: String? = null,

    @Column(nullable = false)
    var isAIGame: Boolean = false,

    @Column(nullable = true)
    var aiPlayerId: String? = null,

    @Column(nullable = true)
    var aiDifficulty: String? = null,

    @Column(nullable = true)
    var winnerId: String? = null,

    @Column(nullable = false)
    val createdAt: Instant = Instant.now(),

    @Column(nullable = false)
    var updatedAt: Instant = Instant.now(),

    @Lob
    @Column(columnDefinition = "CLOB")
    var stateJson: String? = null
)
