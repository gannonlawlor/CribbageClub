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
class LobbyControllerTest {

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
    fun `should return 403 when creating lobby without auth`() {
        val request = mapOf("name" to "Test Lobby")
        mockMvc.perform(
            post("/api/lobbies")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        ).andExpect(status().isForbidden)
    }

    @Test
    fun `should create a lobby`() {
        val token = registerAndGetToken("lobbytest1")

        val request = mapOf("name" to "My Lobby")
        mockMvc.perform(
            post("/api/lobbies")
                .header("Authorization", "Bearer $token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.name").value("My Lobby"))
            .andExpect(jsonPath("$.status").value("WAITING"))
            .andExpect(jsonPath("$.players.length()").value(1))
    }

    @Test
    fun `should list lobbies`() {
        val token = registerAndGetToken("lobbytest2")

        // Create a lobby
        val request = mapOf("name" to "List Test Lobby")
        mockMvc.perform(
            post("/api/lobbies")
                .header("Authorization", "Bearer $token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        ).andExpect(status().isOk)

        // List lobbies
        mockMvc.perform(
            get("/api/lobbies")
                .header("Authorization", "Bearer $token")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$").isArray)
    }

    @Test
    fun `should list waiting lobbies`() {
        val token = registerAndGetToken("lobbytest3")

        val request = mapOf("name" to "Waiting Lobby")
        mockMvc.perform(
            post("/api/lobbies")
                .header("Authorization", "Bearer $token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        ).andExpect(status().isOk)

        mockMvc.perform(
            get("/api/lobbies/waiting")
                .header("Authorization", "Bearer $token")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$").isArray)
    }

    @Test
    fun `should get lobby by id`() {
        val token = registerAndGetToken("lobbytest4")

        val request = mapOf("name" to "Get By ID Lobby")
        val createResult = mockMvc.perform(
            post("/api/lobbies")
                .header("Authorization", "Bearer $token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        ).andExpect(status().isOk).andReturn()

        val lobbyId = objectMapper.readTree(createResult.response.contentAsString).get("id").asText()

        mockMvc.perform(
            get("/api/lobbies/$lobbyId")
                .header("Authorization", "Bearer $token")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.id").value(lobbyId))
            .andExpect(jsonPath("$.name").value("Get By ID Lobby"))
    }

    @Test
    fun `should return 404 for non-existent lobby`() {
        val token = registerAndGetToken("lobbytest5")

        mockMvc.perform(
            get("/api/lobbies/nonexistent")
                .header("Authorization", "Bearer $token")
        ).andExpect(status().isNotFound)
    }

    @Test
    fun `should join a lobby`() {
        val token1 = registerAndGetToken("lobbytest6a")
        val token2 = registerAndGetToken("lobbytest6b")

        // Create a lobby
        val request = mapOf("name" to "Join Lobby")
        val createResult = mockMvc.perform(
            post("/api/lobbies")
                .header("Authorization", "Bearer $token1")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        ).andExpect(status().isOk).andReturn()

        val lobbyId = objectMapper.readTree(createResult.response.contentAsString).get("id").asText()

        // Join with second player
        mockMvc.perform(
            post("/api/lobbies/$lobbyId/join")
                .header("Authorization", "Bearer $token2")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.players.length()").value(2))
    }

    @Test
    fun `should leave a lobby`() {
        val token1 = registerAndGetToken("lobbytest7a")
        val token2 = registerAndGetToken("lobbytest7b")

        // Create a lobby
        val request = mapOf("name" to "Leave Lobby")
        val createResult = mockMvc.perform(
            post("/api/lobbies")
                .header("Authorization", "Bearer $token1")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        ).andExpect(status().isOk).andReturn()

        val lobbyId = objectMapper.readTree(createResult.response.contentAsString).get("id").asText()

        // Join with second player
        mockMvc.perform(
            post("/api/lobbies/$lobbyId/join")
                .header("Authorization", "Bearer $token2")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}")
        ).andExpect(status().isOk)

        // Second player leaves
        mockMvc.perform(
            post("/api/lobbies/$lobbyId/leave")
                .header("Authorization", "Bearer $token2")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.players.length()").value(1))
    }

    @Test
    fun `should start game from full lobby`() {
        val token1 = registerAndGetToken("lobbytest8a")
        val token2 = registerAndGetToken("lobbytest8b")

        // Create lobby
        val request = mapOf("name" to "Start Game Lobby")
        val createResult = mockMvc.perform(
            post("/api/lobbies")
                .header("Authorization", "Bearer $token1")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        ).andExpect(status().isOk).andReturn()

        val lobbyId = objectMapper.readTree(createResult.response.contentAsString).get("id").asText()

        // Join second player
        mockMvc.perform(
            post("/api/lobbies/$lobbyId/join")
                .header("Authorization", "Bearer $token2")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}")
        ).andExpect(status().isOk)

        // Start game
        mockMvc.perform(
            post("/api/lobbies/$lobbyId/start")
                .header("Authorization", "Bearer $token1")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.gameId").isNotEmpty)
            .andExpect(jsonPath("$.players.length()").value(2))
    }
}
