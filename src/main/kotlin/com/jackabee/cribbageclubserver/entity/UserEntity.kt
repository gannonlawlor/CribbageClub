package com.jackabee.cribbageclubserver.entity

import jakarta.persistence.*
import java.time.Instant

@Entity
@Table(name = "users")
class UserEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
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
)
