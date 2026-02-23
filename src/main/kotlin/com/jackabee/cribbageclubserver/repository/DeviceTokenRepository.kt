package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.DeviceTokenEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface DeviceTokenRepository : JpaRepository<DeviceTokenEntity, String> {
    fun findByUserId(userId: String): List<DeviceTokenEntity>
    fun findByToken(token: String): DeviceTokenEntity?
    fun deleteByUserIdAndToken(userId: String, token: String)
    fun deleteByToken(token: String)
}
