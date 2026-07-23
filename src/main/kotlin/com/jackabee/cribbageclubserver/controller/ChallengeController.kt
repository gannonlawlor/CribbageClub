package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.model.game.TimeControl
import com.jackabee.cribbageclubserver.model.lobby.Lobby
import com.jackabee.cribbageclubserver.service.FriendService
import com.jackabee.cribbageclubserver.service.LobbyService
import com.jackabee.cribbageclubserver.service.PushNotificationService
import com.jackabee.cribbageclubserver.websocket.*
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/challenges")
@Tag(name = "Challenges", description = "Direct challenge system")
class ChallengeController(
    private val lobbyService: LobbyService,
    private val friendService: FriendService,
    private val notificationService: NotificationWebSocketService,
    private val pushNotificationService: PushNotificationService
) {

    @Operation(summary = "Create a challenge (invite a friend to play)")
    @PostMapping
    fun createChallenge(
        @RequestBody request: CreateChallengeRequest,
        @RequestAttribute("userId") userId: String,
        @RequestAttribute("username") username: String,
        @RequestAttribute("isGuest") isGuest: Boolean
    ): Lobby {
        require(!isGuest) { "Guests cannot create challenges" }
        require(friendService.areFriends(userId, request.friendUserId)) {
            "You can only challenge friends"
        }

        val lobby = lobbyService.createChallenge(
            userId,
            username,
            request.friendUserId,
            request.timeControl?.let { TimeControl.parse(it) }
        )

        notificationService.sendChallengeNotification(
            request.friendUserId,
            ChallengeNotification(
                lobbyId = lobby.id,
                fromUserId = userId,
                fromUsername = username
            )
        )

        // Send push notification if friend is offline
        pushNotificationService.sendIfOffline(
            request.friendUserId,
            "Game Challenge",
            "$username challenged you to a game!",
            mapOf("type" to "CHALLENGE_RECEIVED", "lobbyId" to lobby.id)
        )

        return lobby
    }

    @Operation(summary = "Get incoming challenges")
    @GetMapping("/incoming")
    fun getIncomingChallenges(
        @RequestAttribute("userId") userId: String
    ): List<Lobby> {
        return lobbyService.getPendingChallengesForUser(userId)
    }

    @Operation(summary = "Accept a challenge")
    @PostMapping("/{lobbyId}/accept")
    fun acceptChallenge(
        @PathVariable lobbyId: String,
        @RequestAttribute("userId") userId: String,
        @RequestAttribute("username") username: String
    ): LobbyService.JoinByCodeResult {
        val lobby = lobbyService.getLobby(lobbyId)
            ?: throw IllegalArgumentException("Challenge not found")
        require(lobby.challengedUserId == userId) { "This challenge is not for you" }

        return lobbyService.joinLobbyById(lobbyId, userId, username)
    }

    @Operation(summary = "Decline a challenge")
    @PostMapping("/{lobbyId}/decline")
    fun declineChallenge(
        @PathVariable lobbyId: String,
        @RequestAttribute("userId") userId: String,
        @RequestAttribute("username") username: String
    ): ResponseEntity<Void> {
        val lobby = lobbyService.getLobby(lobbyId)
            ?: throw IllegalArgumentException("Challenge not found")
        require(lobby.challengedUserId == userId) { "This challenge is not for you" }

        val challengerId = lobby.players.firstOrNull()?.id
        lobbyService.removeLobby(lobbyId)

        if (challengerId != null) {
            notificationService.sendChallengeDeclinedNotification(
                challengerId,
                ChallengeDeclinedNotification(
                    lobbyId = lobbyId,
                    byUserId = userId,
                    byUsername = username
                )
            )
        }

        return ResponseEntity.noContent().build()
    }

    @Operation(summary = "Cancel a challenge")
    @PostMapping("/{lobbyId}/cancel")
    fun cancelChallenge(
        @PathVariable lobbyId: String,
        @RequestAttribute("userId") userId: String
    ): ResponseEntity<Void> {
        val lobby = lobbyService.getLobby(lobbyId)
            ?: throw IllegalArgumentException("Challenge not found")
        require(lobby.players.any { it.id == userId }) { "You are not part of this challenge" }

        val challengedUserId = lobby.challengedUserId
        lobbyService.removeLobby(lobbyId)

        if (challengedUserId != null) {
            notificationService.sendChallengeCancelledNotification(
                challengedUserId,
                ChallengeCancelledNotification(lobbyId = lobbyId)
            )
        }

        return ResponseEntity.noContent().build()
    }
}

data class CreateChallengeRequest(
    val friendUserId: String,
    /** Optional time control preset name; falls back to the server default. */
    val timeControl: String? = null
)
