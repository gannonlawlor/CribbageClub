package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.entity.FriendshipEntity
import com.jackabee.cribbageclubserver.repository.FriendshipRepository
import com.jackabee.cribbageclubserver.repository.UserRepository
import com.jackabee.cribbageclubserver.websocket.*
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import java.time.Instant
import java.util.UUID

data class FriendInfo(
    val friendshipId: String,
    val userId: String,
    val username: String,
    val displayName: String?,
    val isOnline: Boolean,
    val since: Instant
)

data class FriendRequestInfo(
    val friendshipId: String,
    val fromUserId: String,
    val fromUsername: String,
    val fromDisplayName: String?,
    val createdAt: Instant
)

data class UserSearchResult(
    val userId: String,
    val username: String,
    val displayName: String?,
    val relationshipStatus: String? = null
)

@Service
class FriendService(
    private val friendshipRepository: FriendshipRepository,
    private val userRepository: UserRepository,
    private val sessionRegistry: WebSocketSessionRegistry,
    private val notificationService: NotificationWebSocketService
) {
    private val logger = LoggerFactory.getLogger(FriendService::class.java)

    fun searchUsers(query: String, requesterId: String): List<UserSearchResult> {
        require(query.length >= 2) { "Search query must be at least 2 characters" }

        val users = userRepository.searchByUsername(query, requesterId)
        return users.map { user ->
            val friendship = friendshipRepository.findBetween(requesterId, user.id!!)
            val status = when {
                friendship == null -> null
                friendship.status == "ACCEPTED" -> "FRIENDS"
                friendship.requesterId == requesterId && friendship.status == "PENDING" -> "PENDING_SENT"
                friendship.addresseeId == requesterId && friendship.status == "PENDING" -> "PENDING_RECEIVED"
                else -> null
            }
            UserSearchResult(
                userId = user.id!!,
                username = user.username,
                displayName = user.displayName,
                relationshipStatus = status
            )
        }
    }

    fun sendFriendRequest(requesterId: String, addresseeUsername: String): FriendRequestInfo {
        val addressee = userRepository.findByUsername(addresseeUsername)
            ?: throw IllegalArgumentException("User not found: $addresseeUsername")
        require(addressee.id != requesterId) { "Cannot send friend request to yourself" }
        require(!addressee.isGuest) { "Cannot send friend request to a guest user" }

        val existing = friendshipRepository.findBetween(requesterId, addressee.id!!)
        require(existing == null) { "A friendship or request already exists with this user" }

        val requester = userRepository.findById(requesterId).orElseThrow {
            IllegalArgumentException("Requester not found")
        }

        val entity = FriendshipEntity(
            id = UUID.randomUUID().toString(),
            requesterId = requesterId,
            addresseeId = addressee.id!!,
            status = "PENDING",
            createdAt = Instant.now(),
            updatedAt = Instant.now()
        )
        friendshipRepository.save(entity)
        logger.info("Friend request sent from {} to {}", requesterId, addressee.id)

        // Send WebSocket notification to addressee
        notificationService.sendFriendRequestNotification(
            addressee.id!!,
            FriendRequestNotification(
                friendshipId = entity.id,
                fromUserId = requesterId,
                fromUsername = requester.username,
                fromDisplayName = requester.displayName
            )
        )

        return FriendRequestInfo(
            friendshipId = entity.id,
            fromUserId = requesterId,
            fromUsername = requester.username,
            fromDisplayName = requester.displayName,
            createdAt = entity.createdAt
        )
    }

    fun acceptFriendRequest(friendshipId: String, userId: String): FriendInfo {
        val entity = friendshipRepository.findById(friendshipId).orElseThrow {
            IllegalArgumentException("Friend request not found")
        }
        require(entity.addresseeId == userId) { "Only the addressee can accept a friend request" }
        require(entity.status == "PENDING") { "Friend request is not pending" }

        entity.status = "ACCEPTED"
        entity.updatedAt = Instant.now()
        friendshipRepository.save(entity)
        logger.info("Friend request {} accepted by {}", friendshipId, userId)

        val accepter = userRepository.findById(userId).orElseThrow {
            IllegalArgumentException("User not found")
        }
        val friend = userRepository.findById(entity.requesterId).orElseThrow {
            IllegalArgumentException("Friend user not found")
        }

        // Send WebSocket notification to the original requester
        notificationService.sendFriendAcceptedNotification(
            entity.requesterId,
            FriendAcceptedNotification(
                friendshipId = friendshipId,
                userId = userId,
                username = accepter.username,
                displayName = accepter.displayName
            )
        )

        return FriendInfo(
            friendshipId = entity.id,
            userId = friend.id!!,
            username = friend.username,
            displayName = friend.displayName,
            isOnline = sessionRegistry.isUserOnline(friend.id!!),
            since = entity.updatedAt
        )
    }

    fun declineFriendRequest(friendshipId: String, userId: String) {
        val entity = friendshipRepository.findById(friendshipId).orElseThrow {
            IllegalArgumentException("Friend request not found")
        }
        require(entity.addresseeId == userId) { "Only the addressee can decline a friend request" }
        require(entity.status == "PENDING") { "Friend request is not pending" }

        friendshipRepository.delete(entity)
        logger.info("Friend request {} declined by {}", friendshipId, userId)
    }

    fun getIncomingRequests(userId: String): List<FriendRequestInfo> {
        return friendshipRepository.findByAddresseeIdAndStatus(userId, "PENDING").map { entity ->
            val requester = userRepository.findById(entity.requesterId).orElse(null)
            FriendRequestInfo(
                friendshipId = entity.id,
                fromUserId = entity.requesterId,
                fromUsername = requester?.username ?: "Unknown",
                fromDisplayName = requester?.displayName,
                createdAt = entity.createdAt
            )
        }
    }

    fun getOutgoingRequests(userId: String): List<FriendRequestInfo> {
        return friendshipRepository.findByRequesterIdAndStatus(userId, "PENDING").map { entity ->
            val addressee = userRepository.findById(entity.addresseeId).orElse(null)
            FriendRequestInfo(
                friendshipId = entity.id,
                fromUserId = entity.addresseeId,
                fromUsername = addressee?.username ?: "Unknown",
                fromDisplayName = addressee?.displayName,
                createdAt = entity.createdAt
            )
        }
    }

    fun getFriends(userId: String): List<FriendInfo> {
        return friendshipRepository.findAcceptedFriendships(userId).map { entity ->
            val friendId = if (entity.requesterId == userId) entity.addresseeId else entity.requesterId
            val friend = userRepository.findById(friendId).orElse(null)
            FriendInfo(
                friendshipId = entity.id,
                userId = friendId,
                username = friend?.username ?: "Unknown",
                displayName = friend?.displayName,
                isOnline = sessionRegistry.isUserOnline(friendId),
                since = entity.updatedAt
            )
        }
    }

    fun removeFriend(friendshipId: String, userId: String) {
        val entity = friendshipRepository.findById(friendshipId).orElseThrow {
            IllegalArgumentException("Friendship not found")
        }
        require(entity.requesterId == userId || entity.addresseeId == userId) {
            "You are not part of this friendship"
        }

        friendshipRepository.delete(entity)
        logger.info("Friendship {} removed by {}", friendshipId, userId)
    }

    fun areFriends(userA: String, userB: String): Boolean {
        val friendship = friendshipRepository.findBetween(userA, userB)
        return friendship?.status == "ACCEPTED"
    }
}
