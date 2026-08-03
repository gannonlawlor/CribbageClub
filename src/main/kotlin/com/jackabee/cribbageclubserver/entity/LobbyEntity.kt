package com.jackabee.cribbageclubserver.entity

import jakarta.persistence.*
import java.time.Instant

/**
 * JPA entity for persisting lobby state to the database.
 * Replaces the in-memory ConcurrentHashMap in LobbyService.
 */
@Entity
@Table(name = "lobbies")
@Suppress("LongParameterList") // Constructor mirrors the table's columns.
class LobbyEntity(
    @Id
    val id: String,

    @Column(nullable = false)
    val name: String,

    @Column(nullable = false)
    val maxPlayers: Int = 2,

    @Column(nullable = false)
    var status: String = "WAITING",

    @Column(nullable = true)
    var gameId: String? = null,

    @Column(nullable = false)
    val isPrivate: Boolean = false,

    @Column(nullable = true, unique = true)
    val inviteCode: String? = null,

    @Column(nullable = false)
    val createdAt: Instant = Instant.now(),

    @Column(nullable = false)
    var updatedAt: Instant = Instant.now(),

    /**
     * Players stored as JSON array: [{"id":"...","name":"...","joinedAt":"..."}]
     */
    @Column(columnDefinition = "TEXT")
    var playersJson: String = "[]",

    @Column(nullable = true)
    val challengedUserId: String? = null,

    /** Time control games started from this lobby will be played under. */
    @Column(name = "time_control", nullable = false)
    val timeControl: String = "RAPID",

    /** True only for lobbies created by quick-match — the only lobbies bots may fill. */
    @Column(name = "is_quick_match", nullable = false)
    val isQuickMatch: Boolean = false,

    @Version
    var version: Long = 0
)
