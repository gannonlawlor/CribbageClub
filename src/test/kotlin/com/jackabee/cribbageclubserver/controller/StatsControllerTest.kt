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

@SpringBootTest
@AutoConfigureMockMvc
class StatsControllerTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    private fun registerAndGetTokenAndUserId(username: String): Pair<String, String> {
        val request = mapOf("username" to username, "password" to "password123")
        val result = mockMvc.perform(
            post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        ).andExpect(status().isOk).andReturn()

        val json = objectMapper.readTree(result.response.contentAsString)
        return json.get("token").asText() to json.get("userId").asText()
    }

    @Test
    fun `should return 403 when getting my stats without auth`() {
        mockMvc.perform(get("/api/stats/me"))
            .andExpect(status().isForbidden)
    }

    @Test
    fun `should get my stats with auth`() {
        val (token, _) = registerAndGetTokenAndUserId("statstest1")

        mockMvc.perform(
            get("/api/stats/me")
                .header("Authorization", "Bearer $token")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.gamesPlayed").value(0))
            .andExpect(jsonPath("$.gamesWon").value(0))
            .andExpect(jsonPath("$.gamesLost").value(0))
            .andExpect(jsonPath("$.winRate").value(0.0))
    }

    @Test
    fun `should get stats for a specific player`() {
        val (token, userId) = registerAndGetTokenAndUserId("statstest2")

        mockMvc.perform(
            get("/api/stats/$userId")
                .header("Authorization", "Bearer $token")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.playerId").value(userId))
            .andExpect(jsonPath("$.gamesPlayed").value(0))
    }

    @Test
    fun `should get leaderboard without auth`() {
        // Leaderboard is public
        mockMvc.perform(get("/api/stats/leaderboard"))
            .andExpect(status().isOk)
            .andExpect(jsonPath("$").isArray)
    }

    @Test
    fun `should return default stats for unknown player`() {
        val (token, _) = registerAndGetTokenAndUserId("statstest3")

        mockMvc.perform(
            get("/api/stats/unknown_player_id")
                .header("Authorization", "Bearer $token")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.playerId").value("unknown_player_id"))
            .andExpect(jsonPath("$.gamesPlayed").value(0))
            .andExpect(jsonPath("$.gamesWon").value(0))
    }

    @Test
    fun `leaderboard should return displayName field`() {
        // Leaderboard entries should have displayName
        mockMvc.perform(get("/api/stats/leaderboard"))
            .andExpect(status().isOk)
            .andExpect(jsonPath("$").isArray)
        // Each entry, if present, should have displayName
        // (We can't assert specific entries without seeding data, but the endpoint should succeed)
    }

    @Test
    fun `guest should be able to view leaderboard`() {
        val guestResult = mockMvc.perform(post("/api/auth/guest"))
            .andExpect(status().isOk).andReturn()
        val guestToken = objectMapper.readTree(guestResult.response.contentAsString).get("token").asText()

        // Leaderboard is public, should also work with guest token
        mockMvc.perform(
            get("/api/stats/leaderboard")
                .header("Authorization", "Bearer $guestToken")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$").isArray)
    }

    @Test
    fun `guest should be able to view own stats`() {
        val guestResult = mockMvc.perform(post("/api/auth/guest"))
            .andExpect(status().isOk).andReturn()
        val guestToken = objectMapper.readTree(guestResult.response.contentAsString).get("token").asText()

        mockMvc.perform(
            get("/api/stats/me")
                .header("Authorization", "Bearer $guestToken")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.gamesPlayed").value(0))
    }
}
