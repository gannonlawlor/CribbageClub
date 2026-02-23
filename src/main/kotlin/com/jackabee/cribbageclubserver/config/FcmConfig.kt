package com.jackabee.cribbageclubserver.config

import com.google.auth.oauth2.GoogleCredentials
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Component
import java.io.FileInputStream

/**
 * Holds FCM credentials and project ID. Credentials are null when
 * FCM_SERVICE_ACCOUNT_PATH is not set (dev mode — push disabled).
 */
@Component
class FcmConfig(
    @Value("\${fcm.service-account-path:}") private val serviceAccountPath: String,
    @Value("\${fcm.project-id:}") val projectId: String
) {
    private val logger = LoggerFactory.getLogger(FcmConfig::class.java)

    val credentials: GoogleCredentials? = loadCredentials()

    private fun loadCredentials(): GoogleCredentials? {
        if (serviceAccountPath.isBlank()) {
            logger.warn("FCM service account path not configured — push notifications disabled")
            return null
        }
        return try {
            val creds = GoogleCredentials
                .fromStream(FileInputStream(serviceAccountPath))
                .createScoped(listOf("https://www.googleapis.com/auth/firebase.messaging"))
            logger.info("FCM credentials loaded successfully")
            creds
        } catch (e: Exception) {
            logger.error("Failed to load FCM credentials: {}", e.message)
            null
        }
    }
}
