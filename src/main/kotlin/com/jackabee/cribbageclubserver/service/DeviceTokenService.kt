package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.entity.DeviceTokenEntity
import com.jackabee.cribbageclubserver.repository.DeviceTokenRepository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.util.UUID

@Service
class DeviceTokenService(
    private val deviceTokenRepository: DeviceTokenRepository
) {
    private val logger = LoggerFactory.getLogger(DeviceTokenService::class.java)

    @Transactional
    fun registerToken(userId: String, token: String, platform: String) {
        val existing = deviceTokenRepository.findByToken(token)
        if (existing != null) {
            // Token already exists — update ownership if needed
            existing.userId = userId
            existing.platform = platform
            existing.updatedAt = Instant.now()
            deviceTokenRepository.save(existing)
            logger.info("Updated device token for user {}", userId)
        } else {
            val entity = DeviceTokenEntity(
                id = UUID.randomUUID().toString(),
                userId = userId,
                token = token,
                platform = platform
            )
            deviceTokenRepository.save(entity)
            logger.info("Registered new device token for user {}", userId)
        }
    }

    @Transactional
    fun unregisterToken(userId: String, token: String) {
        deviceTokenRepository.deleteByUserIdAndToken(userId, token)
        logger.info("Unregistered device token for user {}", userId)
    }

    fun getTokensForUser(userId: String): List<DeviceTokenEntity> {
        return deviceTokenRepository.findByUserId(userId)
    }

    @Transactional
    fun removeToken(token: String) {
        deviceTokenRepository.deleteByToken(token)
        logger.debug("Removed stale device token")
    }
}
