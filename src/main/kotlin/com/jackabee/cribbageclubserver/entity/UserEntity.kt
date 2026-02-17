package com.jackabee.cribbageclubserver.entity

import jakarta.persistence.*
import java.time.Instant

@Entity
@Table(name = "users")
class UserEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: String? = null,

    @Column(nullable = false, unique = true)
    val username: String,

    @Column(nullable = false)
    val passwordHash: String,

    @Column(nullable = true)
    var displayName: String? = null,

    @Column(nullable = false)
    val createdAt: Instant = Instant.now(),

    @Column(nullable = false)
    var lastLoginAt: Instant = Instant.now()
)
