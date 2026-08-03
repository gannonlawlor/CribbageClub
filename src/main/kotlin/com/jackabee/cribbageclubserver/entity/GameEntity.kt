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
@Suppress("LongParameterList") // Constructor mirrors the table's columns.
class GameEntity(
    @Id
    val id: String,

    @Column(name = "player1_id", nullable = false)
    val player1Id: String,

    @Column(name = "player1_name", nullable = false)
    val player1Name: String,

    @Column(name = "player2_id", nullable = false)
    val player2Id: String,

    @Column(name = "player2_name", nullable = false)
    val player2Name: String,

    @Column(name = "player1_score", nullable = false)
    var player1Score: Int = 0,

    @Column(name = "player2_score", nullable = false)
    var player2Score: Int = 0,

    @Column(nullable = false)
    var stage: String = "DEALING",

    @Column(nullable = true)
    var currentPlayerId: String? = null,

    @Column(name = "is_ai_game", nullable = false)
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

    @Column(columnDefinition = "TEXT")
    var stateJson: String? = null,

    @Column(nullable = true)
    var originalLocalGameId: String? = null,

    @Column(nullable = true)
    var turnStartedAt: Instant? = null,

    /** Name of the [com.jackabee.cribbageclubserver.model.game.TimeControl] preset this game is played under. */
    @Column(name = "time_control", nullable = false)
    var timeControl: String = "RAPID",

    /** Per-turn limit frozen at creation, so config changes don't alter a live game. */
    @Column(name = "turn_time_limit_ms", nullable = false)
    var turnTimeLimitMs: Long = 30000,

    @Column(name = "player1_time_bank_ms", nullable = false)
    var player1TimeBankMs: Long = 120000,

    @Column(name = "player2_time_bank_ms", nullable = false)
    var player2TimeBankMs: Long = 120000,

    @Column(nullable = true)
    var forfeitReason: String? = null,

    /**
     * Bot fallback matchmaking: which player is a pool bot, and its engine
     * difficulty. Kept separate from aiPlayerId/aiDifficulty — those trigger the
     * synchronous instant-move AI path, while bot games move on a delayed driver
     * and are treated as human games everywhere else (isAIGame stays false).
     */
    @Column(name = "bot_player_id", nullable = true)
    var botPlayerId: String? = null,

    @Column(name = "bot_difficulty", nullable = true)
    var botDifficulty: String? = null,

    @Version
    var version: Long = 0
)
