package com.jackabee.cribbageclubserver.service

import com.fasterxml.jackson.databind.ObjectMapper
import com.jackabee.cribbageclubserver.config.FcmConfig
import com.jackabee.cribbageclubserver.websocket.WebSocketSessionRegistry
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse

@Service
class PushNotificationService(
    private val fcmConfig: FcmConfig,
    private val deviceTokenService: DeviceTokenService,
    private val sessionRegistry: WebSocketSessionRegistry,
    private val objectMapper: ObjectMapper
) {
    private val logger = LoggerFactory.getLogger(PushNotificationService::class.java)
    private val httpClient = HttpClient.newHttpClient()

    fun sendIfOffline(userId: String, title: String, body: String, data: Map<String, String> = emptyMap()) {
        if (fcmConfig.credentials == null) {
            logger.debug("FCM not configured — skipping push for user {}", userId)
            return
        }

        if (sessionRegistry.isUserOnline(userId)) {
            logger.debug("User {} is online — skipping push", userId)
            return
        }

        val tokens = deviceTokenService.getTokensForUser(userId)
        if (tokens.isEmpty()) {
            logger.debug("No device tokens for user {} — skipping push", userId)
            return
        }

        for (tokenEntity in tokens) {
            try {
                sendToToken(tokenEntity.token, title, body, data)
            } catch (e: Exception) {
                logger.error("Failed to send push to token for user {}: {}", userId, e.message)
            }
        }
    }

    private fun sendToToken(token: String, title: String, body: String, data: Map<String, String>) {
        val credentials = fcmConfig.credentials!!
        credentials.refreshIfExpired()
        val accessToken = credentials.accessToken.tokenValue

        val message = mapOf(
            "message" to buildMap {
                put("token", token)
                put("notification", mapOf("title" to title, "body" to body))
                if (data.isNotEmpty()) {
                    put("data", data)
                }
            }
        )

        val jsonBody = objectMapper.writeValueAsString(message)
        val url = "https://fcm.googleapis.com/v1/projects/${fcmConfig.projectId}/messages:send"

        val request = HttpRequest.newBuilder()
            .uri(URI.create(url))
            .header("Authorization", "Bearer $accessToken")
            .header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(jsonBody))
            .build()

        val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())

        when {
            response.statusCode() == 200 -> {
                logger.debug("Push notification sent successfully")
            }
            response.statusCode() == 404 || response.body().contains("UNREGISTERED") -> {
                logger.info("Device token is stale — removing")
                deviceTokenService.removeToken(token)
            }
            else -> {
                logger.warn("FCM returned status {}: {}", response.statusCode(), response.body())
            }
        }
    }
}
