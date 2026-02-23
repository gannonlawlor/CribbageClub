package com.jackabee.cribbageclubserver.entity

import jakarta.persistence.*
import org.springframework.data.domain.Persistable
import java.time.Instant

@Entity
@Table(name = "device_tokens")
class DeviceTokenEntity(
    @Id
    @JvmField
    var id: String? = null,

    @Column(name = "user_id", nullable = false)
    var userId: String,

    @Column(nullable = false, unique = true)
    var token: String,

    @Column(nullable = false)
    var platform: String,

    @Column(name = "created_at", nullable = false)
    val createdAt: Instant = Instant.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: Instant = Instant.now()
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
