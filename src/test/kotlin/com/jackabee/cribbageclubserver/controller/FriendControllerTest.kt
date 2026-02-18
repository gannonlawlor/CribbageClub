package com.jackabee.cribbageclubserver.controller

import com.fasterxml.jackson.databind.ObjectMapper
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.*
import kotlin.test.assertEquals

@SpringBootTest
@AutoConfigureMockMvc
class FriendControllerTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    private fun registerAndGetToken(username: String): String {
        val request = mapOf("username" to username, "password" to "password123")
        val result = mockMvc.perform(
            post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        ).andExpect(status().isOk).andReturn()

        return objectMapper.readTree(result.response.contentAsString).get("token").asText()
    }

    private fun getGuestToken(): String {
        val result = mockMvc.perform(post("/api/auth/guest"))
            .andExpect(status().isOk).andReturn()
        return objectMapper.readTree(result.response.contentAsString).get("token").asText()
    }

    /**
     * Helper: sends a friend request from tokenA's user to the username associated with tokenB.
     * Returns the friendshipId.
     */
    private fun sendFriendRequest(fromToken: String, toUsername: String): String {
        val request = mapOf("username" to toUsername)
        val result = mockMvc.perform(
            post("/api/friends/requests")
                .header("Authorization", "Bearer $fromToken")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        ).andExpect(status().isOk).andReturn()

        return objectMapper.readTree(result.response.contentAsString).get("friendshipId").asText()
    }

    @Test
    fun `should search users by query`() {
        val token1 = registerAndGetToken("friendsearch1")
        registerAndGetToken("friendsearch2")

        mockMvc.perform(
            get("/api/friends/search")
                .header("Authorization", "Bearer $token1")
                .param("query", "friendsearch2")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$").isArray)
            .andExpect(jsonPath("$[0].username").value("friendsearch2"))
    }

    @Test
    fun `should send friend request`() {
        val token1 = registerAndGetToken("friendreq1")
        registerAndGetToken("friendreq2")

        val request = mapOf("username" to "friendreq2")
        mockMvc.perform(
            post("/api/friends/requests")
                .header("Authorization", "Bearer $token1")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.friendshipId").isNotEmpty)
            .andExpect(jsonPath("$.fromUsername").value("friendreq1"))
    }

    @Test
    fun `should list incoming friend requests`() {
        val token1 = registerAndGetToken("friendinc1")
        val token2 = registerAndGetToken("friendinc2")

        // User 1 sends request to user 2
        sendFriendRequest(token1, "friendinc2")

        // User 2 checks incoming requests
        mockMvc.perform(
            get("/api/friends/requests/incoming")
                .header("Authorization", "Bearer $token2")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$").isArray)
            .andExpect(jsonPath("$[0].fromUsername").value("friendinc1"))
    }

    @Test
    fun `should accept friend request`() {
        val token1 = registerAndGetToken("friendacc1")
        val token2 = registerAndGetToken("friendacc2")

        val friendshipId = sendFriendRequest(token1, "friendacc2")

        // User 2 accepts
        mockMvc.perform(
            post("/api/friends/requests/$friendshipId/accept")
                .header("Authorization", "Bearer $token2")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.friendshipId").value(friendshipId))
            .andExpect(jsonPath("$.username").value("friendacc1"))
    }

    @Test
    fun `should decline friend request`() {
        val token1 = registerAndGetToken("frienddec1")
        val token2 = registerAndGetToken("frienddec2")

        val friendshipId = sendFriendRequest(token1, "frienddec2")

        // User 2 declines
        mockMvc.perform(
            post("/api/friends/requests/$friendshipId/decline")
                .header("Authorization", "Bearer $token2")
        ).andExpect(status().isNoContent)
    }

    @Test
    fun `should list friends after accepting`() {
        val token1 = registerAndGetToken("friendlist1")
        val token2 = registerAndGetToken("friendlist2")

        val friendshipId = sendFriendRequest(token1, "friendlist2")

        // Accept the request
        mockMvc.perform(
            post("/api/friends/requests/$friendshipId/accept")
                .header("Authorization", "Bearer $token2")
        ).andExpect(status().isOk)

        // User 1 checks friend list
        mockMvc.perform(
            get("/api/friends")
                .header("Authorization", "Bearer $token1")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$").isArray)
            .andExpect(jsonPath("$[0].username").value("friendlist2"))

        // User 2 checks friend list
        mockMvc.perform(
            get("/api/friends")
                .header("Authorization", "Bearer $token2")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$").isArray)
            .andExpect(jsonPath("$[0].username").value("friendlist1"))
    }

    @Test
    fun `should remove friend`() {
        val token1 = registerAndGetToken("friendrem1")
        val token2 = registerAndGetToken("friendrem2")

        val friendshipId = sendFriendRequest(token1, "friendrem2")

        // Accept the request
        mockMvc.perform(
            post("/api/friends/requests/$friendshipId/accept")
                .header("Authorization", "Bearer $token2")
        ).andExpect(status().isOk)

        // Remove friend
        mockMvc.perform(
            delete("/api/friends/$friendshipId")
                .header("Authorization", "Bearer $token1")
        ).andExpect(status().isNoContent)

        // Verify friend list is now empty
        val result = mockMvc.perform(
            get("/api/friends")
                .header("Authorization", "Bearer $token1")
        ).andExpect(status().isOk).andReturn()

        val friends = objectMapper.readTree(result.response.contentAsString)
        assertEquals(0, friends.size())
    }

    @Test
    fun `should return notification counts`() {
        val token1 = registerAndGetToken("friendnotif1")
        val token2 = registerAndGetToken("friendnotif2")

        // Send a friend request from user 1 to user 2
        sendFriendRequest(token1, "friendnotif2")

        // User 2 checks notification counts
        mockMvc.perform(
            get("/api/friends/notifications/count")
                .header("Authorization", "Bearer $token2")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.friendRequests").value(1))
            .andExpect(jsonPath("$.total").isNumber)
    }

    @Test
    fun `guest cannot search users`() {
        val guestToken = getGuestToken()

        mockMvc.perform(
            get("/api/friends/search")
                .header("Authorization", "Bearer $guestToken")
                .param("query", "someone")
        ).andExpect(status().isBadRequest)
    }

    @Test
    fun `guest cannot send friend requests`() {
        val guestToken = getGuestToken()
        registerAndGetToken("friendguest1")

        val request = mapOf("username" to "friendguest1")
        mockMvc.perform(
            post("/api/friends/requests")
                .header("Authorization", "Bearer $guestToken")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        ).andExpect(status().isBadRequest)
    }

    @Test
    fun `should return 403 when accessing friends without auth`() {
        mockMvc.perform(
            get("/api/friends")
        ).andExpect(status().isForbidden)
    }

    @Test
    fun `should return 403 when sending friend request without auth`() {
        val request = mapOf("username" to "someone")
        mockMvc.perform(
            post("/api/friends/requests")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        ).andExpect(status().isForbidden)
    }
}
