package com.jackabee.cribbageclubserver.entity

import jakarta.persistence.*
import java.time.Instant

@Entity
@Table(name = "friendships")
class FriendshipEntity(
    @Id
    val id: String,

    @Column(nullable = false)
    val requesterId: String,

    @Column(nullable = false)
    val addresseeId: String,

    @Column(nullable = false)
    var status: String = "PENDING",

    @Column(nullable = false)
    val createdAt: Instant = Instant.now(),

    @Column(nullable = false)
    var updatedAt: Instant = Instant.now(),

    @Version
    var version: Long = 0
)
