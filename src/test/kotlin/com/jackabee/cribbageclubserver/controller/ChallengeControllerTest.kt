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
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

@SpringBootTest
@AutoConfigureMockMvc
class ChallengeControllerTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    data class AuthInfo(val token: String, val userId: String)

    private fun registerAndGetAuth(username: String): AuthInfo {
        val request = mapOf("username" to username, "password" to "password123")
        val result = mockMvc.perform(
            post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        ).andExpect(status().isOk).andReturn()

        val json = objectMapper.readTree(result.response.contentAsString)
        return AuthInfo(
            token = json.get("token").asText(),
            userId = json.get("userId").asText()
        )
    }

    private fun registerAndGetToken(username: String): String {
        return registerAndGetAuth(username).token
    }

    private fun getGuestToken(): String {
        val result = mockMvc.perform(post("/api/auth/guest"))
            .andExpect(status().isOk).andReturn()
        return objectMapper.readTree(result.response.contentAsString).get("token").asText()
    }

    /**
     * Helper: makes two users friends by sending and accepting a friend request.
     */
    private fun makeFriends(tokenA: String, usernameB: String, tokenB: String) {
        // User A sends friend request to user B
        val reqBody = mapOf("username" to usernameB)
        val sendResult = mockMvc.perform(
            post("/api/friends/requests")
                .header("Authorization", "Bearer $tokenA")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(reqBody))
        ).andExpect(status().isOk).andReturn()

        val friendshipId = objectMapper.readTree(sendResult.response.contentAsString).get("friendshipId").asText()

        // User B accepts
        mockMvc.perform(
            post("/api/friends/requests/$friendshipId/accept")
                .header("Authorization", "Bearer $tokenB")
        ).andExpect(status().isOk)
    }

    @Test
    fun `full challenge flow - challenge accepted creates game`() {
        val tokenA = registerAndGetToken("challflow1a")
        val authB = registerAndGetAuth("challflow1b")
        val tokenB = authB.token
        val userBId = authB.userId

        // Make them friends first
        makeFriends(tokenA, "challflow1b", tokenB)

        // User A challenges user B
        val challengeReq = mapOf("friendUserId" to userBId)
        val challengeResult = mockMvc.perform(
            post("/api/challenges")
                .header("Authorization", "Bearer $tokenA")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(challengeReq))
        ).andExpect(status().isOk).andReturn()

        val challengeJson = objectMapper.readTree(challengeResult.response.contentAsString)
        val lobbyId = challengeJson.get("id").asText()
        assertNotNull(lobbyId)
        assertTrue(challengeJson.get("isPrivate").asBoolean())
        assertTrue(challengeJson.get("challengedUserId").asText() == userBId)

        // User B accepts the challenge
        val acceptResult = mockMvc.perform(
            post("/api/challenges/$lobbyId/accept")
                .header("Authorization", "Bearer $tokenB")
        ).andExpect(status().isOk).andReturn()

        val acceptJson = objectMapper.readTree(acceptResult.response.contentAsString)
        val lobby = acceptJson.get("lobby")
        assertNotNull(lobby.get("gameId").asText())
        assertTrue(lobby.get("players").size() == 2)
        assertNotNull(acceptJson.get("gameState"))
    }

    @Test
    fun `decline challenge removes lobby`() {
        val tokenA = registerAndGetToken("challdecl1a")
        val authB = registerAndGetAuth("challdecl1b")
        val tokenB = authB.token
        val userBId = authB.userId

        makeFriends(tokenA, "challdecl1b", tokenB)

        // Create challenge
        val challengeReq = mapOf("friendUserId" to userBId)
        val challengeResult = mockMvc.perform(
            post("/api/challenges")
                .header("Authorization", "Bearer $tokenA")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(challengeReq))
        ).andExpect(status().isOk).andReturn()

        val lobbyId = objectMapper.readTree(challengeResult.response.contentAsString).get("id").asText()

        // User B declines the challenge
        mockMvc.perform(
            post("/api/challenges/$lobbyId/decline")
                .header("Authorization", "Bearer $tokenB")
        ).andExpect(status().isNoContent)
    }

    @Test
    fun `cancel challenge removes lobby`() {
        val tokenA = registerAndGetToken("challcanc1a")
        val authB = registerAndGetAuth("challcanc1b")
        val tokenB = authB.token
        val userBId = authB.userId

        makeFriends(tokenA, "challcanc1b", tokenB)

        // Create challenge
        val challengeReq = mapOf("friendUserId" to userBId)
        val challengeResult = mockMvc.perform(
            post("/api/challenges")
                .header("Authorization", "Bearer $tokenA")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(challengeReq))
        ).andExpect(status().isOk).andReturn()

        val lobbyId = objectMapper.readTree(challengeResult.response.contentAsString).get("id").asText()

        // User A cancels the challenge
        mockMvc.perform(
            post("/api/challenges/$lobbyId/cancel")
                .header("Authorization", "Bearer $tokenA")
        ).andExpect(status().isNoContent)
    }

    @Test
    fun `cannot challenge non-friend`() {
        val tokenA = registerAndGetToken("challnonfr1a")
        val authB = registerAndGetAuth("challnonfr1b")
        val userBId = authB.userId

        // Do NOT make them friends

        val challengeReq = mapOf("friendUserId" to userBId)
        mockMvc.perform(
            post("/api/challenges")
                .header("Authorization", "Bearer $tokenA")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(challengeReq))
        ).andExpect(status().isBadRequest)
    }

    @Test
    fun `should list incoming challenges`() {
        val tokenA = registerAndGetToken("challinc1a")
        val authB = registerAndGetAuth("challinc1b")
        val tokenB = authB.token
        val userBId = authB.userId

        makeFriends(tokenA, "challinc1b", tokenB)

        // Create challenge
        val challengeReq = mapOf("friendUserId" to userBId)
        mockMvc.perform(
            post("/api/challenges")
                .header("Authorization", "Bearer $tokenA")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(challengeReq))
        ).andExpect(status().isOk)

        // User B lists incoming challenges
        mockMvc.perform(
            get("/api/challenges/incoming")
                .header("Authorization", "Bearer $tokenB")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$").isArray)
            .andExpect(jsonPath("$[0].challengedUserId").value(userBId))
    }

    @Test
    fun `guest cannot create challenges`() {
        val guestToken = getGuestToken()
        val auth = registerAndGetAuth("challguest1")
        val userId = auth.userId

        val challengeReq = mapOf("friendUserId" to userId)
        mockMvc.perform(
            post("/api/challenges")
                .header("Authorization", "Bearer $guestToken")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(challengeReq))
        ).andExpect(status().isBadRequest)
    }

    @Test
    fun `should return 403 when creating challenge without auth`() {
        val challengeReq = mapOf("friendUserId" to "someuser")
        mockMvc.perform(
            post("/api/challenges")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(challengeReq))
        ).andExpect(status().isForbidden)
    }
}
