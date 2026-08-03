package com.jackabee.cribbageclubserver.websocket

import org.slf4j.LoggerFactory
import org.springframework.messaging.simp.SimpMessagingTemplate
import org.springframework.stereotype.Service
import java.time.Instant

// Notification DTOs
data class FriendRequestNotification(
    val type: String = "FRIEND_REQUEST",
    val friendshipId: String,
    val fromUserId: String,
    val fromUsername: String,
    val fromDisplayName: String?,
    val timestamp: Long = System.currentTimeMillis()
)

data class FriendAcceptedNotification(
    val type: String = "FRIEND_ACCEPTED",
    val friendshipId: String,
    val userId: String,
    val username: String,
    val displayName: String?,
    val timestamp: Long = System.currentTimeMillis()
)

data class ChallengeNotification(
    val type: String = "CHALLENGE_RECEIVED",
    val lobbyId: String,
    val fromUserId: String,
    val fromUsername: String,
    val timestamp: Long = System.currentTimeMillis()
)

data class ChallengeCancelledNotification(
    val type: String = "CHALLENGE_CANCELLED",
    val lobbyId: String,
    val timestamp: Long = System.currentTimeMillis()
)

data class ChallengeDeclinedNotification(
    val type: String = "CHALLENGE_DECLINED",
    val lobbyId: String,
    val byUserId: String,
    val byUsername: String,
    val timestamp: Long = System.currentTimeMillis()
)

data class GameFoundNotification(
    val type: String = "GAME_FOUND",
    val gameId: String,
    val opponentName: String,
    val timestamp: Long = System.currentTimeMillis()
)

data class AchievementSummary(
    val key: String,
    val name: String,
    val description: String,
    val tier: String
)

data class AchievementUnlockedNotification(
    val type: String = "ACHIEVEMENT_UNLOCKED",
    val achievements: List<AchievementSummary>,
    val timestamp: Long = System.currentTimeMillis()
)

@Service
class NotificationWebSocketService(
    private val messagingTemplate: SimpMessagingTemplate
) {
    private val logger = LoggerFactory.getLogger(NotificationWebSocketService::class.java)

    fun sendGameFoundNotification(toUserId: String, notification: GameFoundNotification) {
        messagingTemplate.convertAndSendToUser(toUserId, "/queue/notifications", notification)
        logger.debug("Sent game found notification to {}", toUserId)
    }

    fun sendFriendRequestNotification(toUserId: String, notification: FriendRequestNotification) {
        messagingTemplate.convertAndSendToUser(toUserId, "/queue/notifications", notification)
        logger.debug("Sent friend request notification to {}", toUserId)
    }

    fun sendFriendAcceptedNotification(toUserId: String, notification: FriendAcceptedNotification) {
        messagingTemplate.convertAndSendToUser(toUserId, "/queue/notifications", notification)
        logger.debug("Sent friend accepted notification to {}", toUserId)
    }

    fun sendChallengeNotification(toUserId: String, notification: ChallengeNotification) {
        messagingTemplate.convertAndSendToUser(toUserId, "/queue/notifications", notification)
        logger.debug("Sent challenge notification to {}", toUserId)
    }

    fun sendChallengeCancelledNotification(toUserId: String, notification: ChallengeCancelledNotification) {
        messagingTemplate.convertAndSendToUser(toUserId, "/queue/notifications", notification)
        logger.debug("Sent challenge cancelled notification to {}", toUserId)
    }

    fun sendChallengeDeclinedNotification(toUserId: String, notification: ChallengeDeclinedNotification) {
        messagingTemplate.convertAndSendToUser(toUserId, "/queue/notifications", notification)
        logger.debug("Sent challenge declined notification to {}", toUserId)
    }

    fun sendAchievementUnlockedNotification(toUserId: String, notification: AchievementUnlockedNotification) {
        messagingTemplate.convertAndSendToUser(toUserId, "/queue/notifications", notification)
        logger.debug("Sent achievement unlocked notification to {}", toUserId)
    }
}
