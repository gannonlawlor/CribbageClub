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
class GameControllerTest {

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

    @Test
    fun `should return 403 when listing games without auth`() {
        mockMvc.perform(get("/api/games"))
            .andExpect(status().isForbidden)
    }

    @Test
    fun `should list games with auth`() {
        val token = registerAndGetToken("gametest1")

        mockMvc.perform(
            get("/api/games")
                .header("Authorization", "Bearer $token")
        ).andExpect(status().isOk)
    }

    @Test
    fun `should create AI game`() {
        val token = registerAndGetToken("gametest2")

        val request = mapOf("difficulty" to "basic")
        mockMvc.perform(
            post("/api/games/ai")
                .header("Authorization", "Bearer $token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.gameId").isNotEmpty)
            .andExpect(jsonPath("$.players").isArray)
            .andExpect(jsonPath("$.players.length()").value(2))
    }

    @Test
    fun `should return 403 when creating AI game without auth`() {
        val request = mapOf("difficulty" to "basic")
        mockMvc.perform(
            post("/api/games/ai")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        ).andExpect(status().isForbidden)
    }

    @Test
    fun `should get game state`() {
        val token = registerAndGetToken("gametest3")

        // Create a game first
        val createReq = mapOf("difficulty" to "basic")
        val createResult = mockMvc.perform(
            post("/api/games/ai")
                .header("Authorization", "Bearer $token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(createReq))
        ).andExpect(status().isOk).andReturn()

        val gameId = objectMapper.readTree(createResult.response.contentAsString).get("gameId").asText()

        // Get game state
        mockMvc.perform(
            get("/api/games/$gameId")
                .header("Authorization", "Bearer $token")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.gameId").value(gameId))
            .andExpect(jsonPath("$.remainingDeck").isArray)
            .andExpect(jsonPath("$.remainingDeck.length()").value(0)) // Filtered out
    }

    @Test
    fun `should return 400 for non-existent game`() {
        val token = registerAndGetToken("gametest4")

        mockMvc.perform(
            get("/api/games/nonexistent")
                .header("Authorization", "Bearer $token")
        ).andExpect(status().isBadRequest)
    }

    @Test
    fun `should delete a game`() {
        val token = registerAndGetToken("gametest5")

        // Create a game
        val createReq = mapOf("difficulty" to "basic")
        val createResult = mockMvc.perform(
            post("/api/games/ai")
                .header("Authorization", "Bearer $token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(createReq))
        ).andExpect(status().isOk).andReturn()

        val gameId = objectMapper.readTree(createResult.response.contentAsString).get("gameId").asText()

        // Delete it
        mockMvc.perform(
            delete("/api/games/$gameId")
                .header("Authorization", "Bearer $token")
        ).andExpect(status().isNoContent)

        // Verify it's gone
        mockMvc.perform(
            get("/api/games/$gameId")
                .header("Authorization", "Bearer $token")
        ).andExpect(status().isBadRequest)
    }

    @Test
    fun `should filter opponent hand in game state`() {
        val token = registerAndGetToken("gametest6")

        // Create an AI game - the human player's view should hide the AI's hand
        val createReq = mapOf("difficulty" to "basic")
        val createResult = mockMvc.perform(
            post("/api/games/ai")
                .header("Authorization", "Bearer $token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(createReq))
        ).andExpect(status().isOk).andReturn()

        val response = objectMapper.readTree(createResult.response.contentAsString)
        val players = response.get("players")

        // Find the AI player (second player) - their hand should be empty (filtered)
        val aiPlayer = players.get(1)
        kotlin.test.assertEquals(0, aiPlayer.get("hand").size(), "AI opponent's hand should be filtered out")
    }

    @Test
    fun `should create AI game with custom player name`() {
        val token = registerAndGetToken("gametest7")

        val request = mapOf("playerName" to "Custom Name", "difficulty" to "medium")
        val result = mockMvc.perform(
            post("/api/games/ai")
                .header("Authorization", "Bearer $token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isOk)
            .andReturn()

        val response = objectMapper.readTree(result.response.contentAsString)
        val humanPlayer = response.get("players").get(0)
        kotlin.test.assertEquals("Custom Name", humanPlayer.get("name").asText())
    }

    @Test
    fun `should get my active games`() {
        val token = registerAndGetToken("gametest8")

        // Create a game
        val createReq = mapOf("difficulty" to "basic")
        mockMvc.perform(
            post("/api/games/ai")
                .header("Authorization", "Bearer $token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(createReq))
        ).andExpect(status().isOk)

        // Get my active games
        mockMvc.perform(
            get("/api/games/me")
                .header("Authorization", "Bearer $token")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$").isArray)
            .andExpect(jsonPath("$.length()").value(org.hamcrest.Matchers.greaterThanOrEqualTo(1)))
    }

    @Test
    fun `should get my game history as empty initially`() {
        val token = registerAndGetToken("gametest9")

        mockMvc.perform(
            get("/api/games/me/history")
                .header("Authorization", "Bearer $token")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$").isArray)
    }

    @Test
    fun `should return 403 for me endpoint without auth`() {
        mockMvc.perform(get("/api/games/me"))
            .andExpect(status().isForbidden)
    }

    @Test
    fun `should return 403 for history endpoint without auth`() {
        mockMvc.perform(get("/api/games/me/history"))
            .andExpect(status().isForbidden)
    }

    @Test
    fun `guest should be able to create AI game`() {
        val guestResult = mockMvc.perform(post("/api/auth/guest"))
            .andExpect(status().isOk).andReturn()
        val guestToken = objectMapper.readTree(guestResult.response.contentAsString).get("token").asText()

        val createReq = mapOf("difficulty" to "basic")
        mockMvc.perform(
            post("/api/games/ai")
                .header("Authorization", "Bearer $guestToken")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(createReq))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.gameId").isNotEmpty)
    }

    @Test
    fun `guest should see their active games`() {
        val guestResult = mockMvc.perform(post("/api/auth/guest"))
            .andExpect(status().isOk).andReturn()
        val guestToken = objectMapper.readTree(guestResult.response.contentAsString).get("token").asText()

        // Create a game
        val createReq = mapOf("difficulty" to "basic")
        mockMvc.perform(
            post("/api/games/ai")
                .header("Authorization", "Bearer $guestToken")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(createReq))
        ).andExpect(status().isOk)

        // Get active games
        mockMvc.perform(
            get("/api/games/me")
                .header("Authorization", "Bearer $guestToken")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.length()").value(org.hamcrest.Matchers.greaterThanOrEqualTo(1)))
    }
}
