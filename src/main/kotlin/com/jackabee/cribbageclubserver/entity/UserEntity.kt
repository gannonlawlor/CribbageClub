package com.jackabee.cribbageclubserver.entity

import jakarta.persistence.*
import org.springframework.data.domain.Persistable
import java.time.Instant

@Entity
@Table(name = "users")
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
    var lastLoginAt: Instant = Instant.now()
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
