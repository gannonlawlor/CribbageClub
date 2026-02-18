package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.service.FriendInfo
import com.jackabee.cribbageclubserver.service.FriendRequestInfo
import com.jackabee.cribbageclubserver.service.FriendService
import com.jackabee.cribbageclubserver.service.LobbyService
import com.jackabee.cribbageclubserver.service.UserSearchResult
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/friends")
@Tag(name = "Friends", description = "Friend system and social features")
class FriendController(
    private val friendService: FriendService,
    private val lobbyService: LobbyService
) {

    @Operation(summary = "Search for users by username")
    @GetMapping("/search")
    fun searchUsers(
        @RequestParam query: String,
        @RequestAttribute("userId") userId: String,
        @RequestAttribute("isGuest") isGuest: Boolean
    ): List<UserSearchResult> {
        require(!isGuest) { "Guests cannot search for users" }
        return friendService.searchUsers(query, userId)
    }

    @Operation(summary = "Send a friend request")
    @PostMapping("/requests")
    fun sendFriendRequest(
        @RequestBody request: SendFriendRequestBody,
        @RequestAttribute("userId") userId: String,
        @RequestAttribute("isGuest") isGuest: Boolean
    ): FriendRequestInfo {
        require(!isGuest) { "Guests cannot send friend requests" }
        return friendService.sendFriendRequest(userId, request.username)
    }

    @Operation(summary = "Get incoming friend requests")
    @GetMapping("/requests/incoming")
    fun getIncomingRequests(
        @RequestAttribute("userId") userId: String
    ): List<FriendRequestInfo> {
        return friendService.getIncomingRequests(userId)
    }

    @Operation(summary = "Get outgoing friend requests")
    @GetMapping("/requests/outgoing")
    fun getOutgoingRequests(
        @RequestAttribute("userId") userId: String
    ): List<FriendRequestInfo> {
        return friendService.getOutgoingRequests(userId)
    }

    @Operation(summary = "Accept a friend request")
    @PostMapping("/requests/{id}/accept")
    fun acceptFriendRequest(
        @PathVariable id: String,
        @RequestAttribute("userId") userId: String
    ): FriendInfo {
        return friendService.acceptFriendRequest(id, userId)
    }

    @Operation(summary = "Decline a friend request")
    @PostMapping("/requests/{id}/decline")
    fun declineFriendRequest(
        @PathVariable id: String,
        @RequestAttribute("userId") userId: String
    ): ResponseEntity<Void> {
        friendService.declineFriendRequest(id, userId)
        return ResponseEntity.noContent().build()
    }

    @Operation(summary = "Get friend list")
    @GetMapping
    fun getFriends(
        @RequestAttribute("userId") userId: String
    ): List<FriendInfo> {
        return friendService.getFriends(userId)
    }

    @Operation(summary = "Remove a friend")
    @DeleteMapping("/{id}")
    fun removeFriend(
        @PathVariable id: String,
        @RequestAttribute("userId") userId: String
    ): ResponseEntity<Void> {
        friendService.removeFriend(id, userId)
        return ResponseEntity.noContent().build()
    }

    @Operation(summary = "Get notification counts")
    @GetMapping("/notifications/count")
    fun getNotificationCount(
        @RequestAttribute("userId") userId: String
    ): NotificationCountResponse {
        val friendRequests = friendService.getIncomingRequests(userId).size
        val challenges = lobbyService.getPendingChallengesForUser(userId).size
        return NotificationCountResponse(
            friendRequests = friendRequests,
            challenges = challenges,
            total = friendRequests + challenges
        )
    }
}

data class SendFriendRequestBody(val username: String)

data class NotificationCountResponse(
    val friendRequests: Int,
    val challenges: Int,
    val total: Int
)
