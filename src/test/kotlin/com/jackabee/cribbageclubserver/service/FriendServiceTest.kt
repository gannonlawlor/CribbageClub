package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.entity.FriendshipEntity
import com.jackabee.cribbageclubserver.entity.UserEntity
import com.jackabee.cribbageclubserver.repository.FriendshipRepository
import com.jackabee.cribbageclubserver.repository.UserRepository
import com.jackabee.cribbageclubserver.websocket.NotificationWebSocketService
import com.jackabee.cribbageclubserver.websocket.WebSocketSessionRegistry
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.junit.jupiter.api.extension.ExtendWith
import org.mockito.InjectMocks
import org.mockito.Mock
import org.mockito.junit.jupiter.MockitoExtension
import org.mockito.kotlin.*
import java.time.Instant
import java.util.Optional
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

@ExtendWith(MockitoExtension::class)
class FriendServiceTest {

    @Mock
    private lateinit var friendshipRepository: FriendshipRepository

    @Mock
    private lateinit var userRepository: UserRepository

    @Mock
    private lateinit var sessionRegistry: WebSocketSessionRegistry

    @Mock
    private lateinit var notificationService: NotificationWebSocketService

    @Mock
    private lateinit var pushNotificationService: PushNotificationService

    @Mock
    private lateinit var achievementService: AchievementService

    @InjectMocks
    private lateinit var friendService: FriendService

    private fun makeUser(id: String, username: String, displayName: String? = null, isGuest: Boolean = false): UserEntity {
        return UserEntity(
            id = id,
            username = username,
            displayName = displayName,
            isGuest = isGuest
        )
    }

    private fun makeFriendship(
        id: String = "friendship1",
        requesterId: String = "userA",
        addresseeId: String = "userB",
        status: String = "PENDING"
    ): FriendshipEntity {
        return FriendshipEntity(
            id = id,
            requesterId = requesterId,
            addresseeId = addresseeId,
            status = status,
            createdAt = Instant.now(),
            updatedAt = Instant.now()
        )
    }

    @Test
    fun `searchUsers returns results with relationship status annotation`() {
        val foundUser = makeUser("userB", "bob", "Bob")
        val friendship = makeFriendship(requesterId = "userA", addresseeId = "userB", status = "ACCEPTED")

        whenever(userRepository.searchByUsername("bob", "userA")).thenReturn(listOf(foundUser))
        whenever(friendshipRepository.findBetween("userA", "userB")).thenReturn(friendship)

        val results = friendService.searchUsers("bob", "userA")

        assertEquals(1, results.size)
        assertEquals("userB", results[0].userId)
        assertEquals("bob", results[0].username)
        assertEquals("Bob", results[0].displayName)
        assertEquals("FRIENDS", results[0].relationshipStatus)
    }

    @Test
    fun `searchUsers annotates PENDING_SENT when requester sent request`() {
        val foundUser = makeUser("userB", "bob")
        val friendship = makeFriendship(requesterId = "userA", addresseeId = "userB", status = "PENDING")

        whenever(userRepository.searchByUsername("bob", "userA")).thenReturn(listOf(foundUser))
        whenever(friendshipRepository.findBetween("userA", "userB")).thenReturn(friendship)

        val results = friendService.searchUsers("bob", "userA")

        assertEquals("PENDING_SENT", results[0].relationshipStatus)
    }

    @Test
    fun `searchUsers annotates PENDING_RECEIVED when requester is addressee`() {
        val foundUser = makeUser("userB", "bob")
        val friendship = makeFriendship(requesterId = "userB", addresseeId = "userA", status = "PENDING")

        whenever(userRepository.searchByUsername("bob", "userA")).thenReturn(listOf(foundUser))
        whenever(friendshipRepository.findBetween("userA", "userB")).thenReturn(friendship)

        val results = friendService.searchUsers("bob", "userA")

        assertEquals("PENDING_RECEIVED", results[0].relationshipStatus)
    }

    @Test
    fun `searchUsers returns null status when no relationship exists`() {
        val foundUser = makeUser("userB", "bob")

        whenever(userRepository.searchByUsername("bob", "userA")).thenReturn(listOf(foundUser))
        whenever(friendshipRepository.findBetween("userA", "userB")).thenReturn(null)

        val results = friendService.searchUsers("bob", "userA")

        assertNull(results[0].relationshipStatus)
    }

    @Test
    fun `sendFriendRequest creates PENDING friendship and sends notification`() {
        val requester = makeUser("userA", "alice", "Alice")
        val addressee = makeUser("userB", "bob", "Bob")

        whenever(userRepository.findByUsername("bob")).thenReturn(addressee)
        whenever(friendshipRepository.findBetween("userA", "userB")).thenReturn(null)
        whenever(userRepository.findById("userA")).thenReturn(Optional.of(requester))
        whenever(friendshipRepository.save(any<FriendshipEntity>())).thenAnswer { it.arguments[0] }

        val result = friendService.sendFriendRequest("userA", "bob")

        assertEquals("userA", result.fromUserId)
        assertEquals("alice", result.fromUsername)
        assertEquals("Alice", result.fromDisplayName)
        assertNotNull(result.friendshipId)
        assertNotNull(result.createdAt)

        verify(friendshipRepository).save(argThat<FriendshipEntity> {
            this.requesterId == "userA" && this.addresseeId == "userB" && this.status == "PENDING"
        })
        verify(notificationService).sendFriendRequestNotification(eq("userB"), any())
    }

    @Test
    fun `sendFriendRequest fails for self`() {
        val user = makeUser("userA", "alice")
        whenever(userRepository.findByUsername("alice")).thenReturn(user)

        assertThrows<IllegalArgumentException> {
            friendService.sendFriendRequest("userA", "alice")
        }
    }

    @Test
    fun `sendFriendRequest fails if friendship already exists`() {
        val addressee = makeUser("userB", "bob")
        val existing = makeFriendship(requesterId = "userA", addresseeId = "userB", status = "PENDING")

        whenever(userRepository.findByUsername("bob")).thenReturn(addressee)
        whenever(friendshipRepository.findBetween("userA", "userB")).thenReturn(existing)

        assertThrows<IllegalArgumentException> {
            friendService.sendFriendRequest("userA", "bob")
        }
    }

    @Test
    fun `sendFriendRequest fails for nonexistent user`() {
        whenever(userRepository.findByUsername("nobody")).thenReturn(null)

        assertThrows<IllegalArgumentException> {
            friendService.sendFriendRequest("userA", "nobody")
        }
    }

    @Test
    fun `sendFriendRequest fails for guest user`() {
        val guest = makeUser("guest_1", "guest_1", isGuest = true)
        whenever(userRepository.findByUsername("guest_1")).thenReturn(guest)

        assertThrows<IllegalArgumentException> {
            friendService.sendFriendRequest("userA", "guest_1")
        }
    }

    @Test
    fun `sendFriendRequest fails for bot user`() {
        // Bots are excluded from search, but the exact-username path lands here.
        val bot = makeUser("bot1", "mollyq").apply { isBot = true }
        whenever(userRepository.findByUsername("mollyq")).thenReturn(bot)

        assertThrows<IllegalArgumentException> {
            friendService.sendFriendRequest("userA", "mollyq")
        }
    }

    @Test
    fun `acceptFriendRequest updates to ACCEPTED and sends notification`() {
        val entity = makeFriendship(id = "fr1", requesterId = "userA", addresseeId = "userB", status = "PENDING")
        val accepter = makeUser("userB", "bob", "Bob")
        val requester = makeUser("userA", "alice", "Alice")

        whenever(friendshipRepository.findById("fr1")).thenReturn(Optional.of(entity))
        whenever(friendshipRepository.save(any<FriendshipEntity>())).thenAnswer { it.arguments[0] }
        whenever(userRepository.findById("userB")).thenReturn(Optional.of(accepter))
        whenever(userRepository.findById("userA")).thenReturn(Optional.of(requester))
        whenever(sessionRegistry.isUserOnline("userA")).thenReturn(true)

        val result = friendService.acceptFriendRequest("fr1", "userB")

        assertEquals("fr1", result.friendshipId)
        assertEquals("userA", result.userId)
        assertEquals("alice", result.username)
        assertEquals("Alice", result.displayName)
        assertTrue(result.isOnline)

        assertEquals("ACCEPTED", entity.status)
        verify(notificationService).sendFriendAcceptedNotification(eq("userA"), any())
    }

    @Test
    fun `acceptFriendRequest fails if not addressee`() {
        val entity = makeFriendship(id = "fr1", requesterId = "userA", addresseeId = "userB", status = "PENDING")
        whenever(friendshipRepository.findById("fr1")).thenReturn(Optional.of(entity))

        assertThrows<IllegalArgumentException> {
            friendService.acceptFriendRequest("fr1", "userA")
        }
    }

    @Test
    fun `acceptFriendRequest fails if not pending`() {
        val entity = makeFriendship(id = "fr1", requesterId = "userA", addresseeId = "userB", status = "ACCEPTED")
        whenever(friendshipRepository.findById("fr1")).thenReturn(Optional.of(entity))

        assertThrows<IllegalArgumentException> {
            friendService.acceptFriendRequest("fr1", "userB")
        }
    }

    @Test
    fun `declineFriendRequest deletes entity`() {
        val entity = makeFriendship(id = "fr1", requesterId = "userA", addresseeId = "userB", status = "PENDING")
        whenever(friendshipRepository.findById("fr1")).thenReturn(Optional.of(entity))

        friendService.declineFriendRequest("fr1", "userB")

        verify(friendshipRepository).delete(entity)
    }

    @Test
    fun `declineFriendRequest fails if not addressee`() {
        val entity = makeFriendship(id = "fr1", requesterId = "userA", addresseeId = "userB", status = "PENDING")
        whenever(friendshipRepository.findById("fr1")).thenReturn(Optional.of(entity))

        assertThrows<IllegalArgumentException> {
            friendService.declineFriendRequest("fr1", "userA")
        }
    }

    @Test
    fun `getFriends returns ACCEPTED friendships`() {
        val entity1 = makeFriendship(id = "fr1", requesterId = "userA", addresseeId = "userB", status = "ACCEPTED")
        val entity2 = makeFriendship(id = "fr2", requesterId = "userC", addresseeId = "userA", status = "ACCEPTED")
        val friendB = makeUser("userB", "bob", "Bob")
        val friendC = makeUser("userC", "charlie", "Charlie")

        whenever(friendshipRepository.findAcceptedFriendships("userA")).thenReturn(listOf(entity1, entity2))
        whenever(userRepository.findById("userB")).thenReturn(Optional.of(friendB))
        whenever(userRepository.findById("userC")).thenReturn(Optional.of(friendC))
        whenever(sessionRegistry.isUserOnline("userB")).thenReturn(true)
        whenever(sessionRegistry.isUserOnline("userC")).thenReturn(false)

        val friends = friendService.getFriends("userA")

        assertEquals(2, friends.size)
        assertEquals("userB", friends[0].userId)
        assertEquals("bob", friends[0].username)
        assertTrue(friends[0].isOnline)
        assertEquals("userC", friends[1].userId)
        assertEquals("charlie", friends[1].username)
        assertFalse(friends[1].isOnline)
    }

    @Test
    fun `removeFriend deletes entity`() {
        val entity = makeFriendship(id = "fr1", requesterId = "userA", addresseeId = "userB", status = "ACCEPTED")
        whenever(friendshipRepository.findById("fr1")).thenReturn(Optional.of(entity))

        friendService.removeFriend("fr1", "userA")

        verify(friendshipRepository).delete(entity)
    }

    @Test
    fun `removeFriend works for addressee too`() {
        val entity = makeFriendship(id = "fr1", requesterId = "userA", addresseeId = "userB", status = "ACCEPTED")
        whenever(friendshipRepository.findById("fr1")).thenReturn(Optional.of(entity))

        friendService.removeFriend("fr1", "userB")

        verify(friendshipRepository).delete(entity)
    }

    @Test
    fun `removeFriend fails if user not part of friendship`() {
        val entity = makeFriendship(id = "fr1", requesterId = "userA", addresseeId = "userB", status = "ACCEPTED")
        whenever(friendshipRepository.findById("fr1")).thenReturn(Optional.of(entity))

        assertThrows<IllegalArgumentException> {
            friendService.removeFriend("fr1", "userC")
        }
    }

    @Test
    fun `areFriends returns true when friendship is ACCEPTED`() {
        val entity = makeFriendship(requesterId = "userA", addresseeId = "userB", status = "ACCEPTED")
        whenever(friendshipRepository.findBetween("userA", "userB")).thenReturn(entity)

        assertTrue(friendService.areFriends("userA", "userB"))
    }

    @Test
    fun `areFriends returns false when friendship is PENDING`() {
        val entity = makeFriendship(requesterId = "userA", addresseeId = "userB", status = "PENDING")
        whenever(friendshipRepository.findBetween("userA", "userB")).thenReturn(entity)

        assertFalse(friendService.areFriends("userA", "userB"))
    }

    @Test
    fun `areFriends returns false when no friendship exists`() {
        whenever(friendshipRepository.findBetween("userA", "userB")).thenReturn(null)

        assertFalse(friendService.areFriends("userA", "userB"))
    }
}
