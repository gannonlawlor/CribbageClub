package com.jackabee.cribbageclubserver.entity

import jakarta.persistence.*
import java.time.Instant

/**
 * JPA entity for persisting lobby state to the database.
 * Replaces the in-memory ConcurrentHashMap in LobbyService.
 */
@Entity
@Table(name = "lobbies")
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
    val createdAt: Instant = Instant.now(),

    @Column(nullable = false)
    var updatedAt: Instant = Instant.now(),

    /**
     * Players stored as JSON array: [{"id":"...","name":"...","joinedAt":"..."}]
     */
    @Column(columnDefinition = "TEXT")
    var playersJson: String = "[]"
)
