package com.jackabee.cribbageclubserver.entity

import jakarta.persistence.*
import org.springframework.data.domain.Persistable
import java.time.Instant

@Entity
@Table(name = "users")
@Suppress("LongParameterList") // Constructor mirrors the table's columns.
class UserEntity(
    @Id
    @JvmField
    var id: String? = null,

    @Column(nullable = false, unique = true)
    var username: String,

    @Column(nullable = true)
    var passwordHash: String? = null,

    @Column(nullable = true)
    var displayName: String? = null,

    @Column(nullable = false)
    var isGuest: Boolean = false,

    @Column(nullable = false)
    val createdAt: Instant = Instant.now(),

    @Column(nullable = false)
    var lastLoginAt: Instant = Instant.now(),

    @Column(nullable = true)
    var avatarIndex: Int? = null,

    /** Server-only: bot pool members for fallback matchmaking. Never exposed in DTOs. */
    @Column(nullable = false)
    var isBot: Boolean = false,

    /** Fixed engine difficulty for bot personas (basic/medium/hard); null for humans. */
    @Column(nullable = true)
    var botDifficulty: String? = null
) : Persistable<String> {

    @Transient
    private var _isNew: Boolean = true

    override fun getId(): String? = id

    override fun isNew(): Boolean = _isNew

    @PostPersist
    @PostLoad
    private fun markNotNew() {
        _isNew = false
    }
}
