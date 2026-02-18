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

    private fun getGuestToken(): String {
        val result = mockMvc.perform(post("/api/auth/guest"))
            .andExpect(status().isOk).andReturn()
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

        // Join with second player (auto-starts since lobby is now full)
        mockMvc.perform(
            post("/api/lobbies/$lobbyId/join")
                .header("Authorization", "Bearer $token2")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.lobby.players.length()").value(2))
            .andExpect(jsonPath("$.gameState").isNotEmpty) // auto-started
    }

    @Test
    fun `should leave a lobby`() {
        val token1 = registerAndGetToken("lobbytest7a")
        val token2 = registerAndGetToken("lobbytest7b")
        val token3 = registerAndGetToken("lobbytest7c")

        // Create a lobby with 3 max players would be complex, instead:
        // Create lobby, have token2 join (which auto-starts), then test leave on a fresh lobby
        val request = mapOf("name" to "Leave Lobby")
        val createResult = mockMvc.perform(
            post("/api/lobbies")
                .header("Authorization", "Bearer $token1")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        ).andExpect(status().isOk).andReturn()

        val lobbyId = objectMapper.readTree(createResult.response.contentAsString).get("id").asText()

        // Creator leaves their own lobby
        mockMvc.perform(
            post("/api/lobbies/$lobbyId/leave")
                .header("Authorization", "Bearer $token1")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.players.length()").value(0))
    }

    @Test
    fun `should start game from full lobby via join`() {
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

        // Join second player — auto-starts the game
        mockMvc.perform(
            post("/api/lobbies/$lobbyId/join")
                .header("Authorization", "Bearer $token2")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.gameState").isNotEmpty)
            .andExpect(jsonPath("$.gameState.gameId").isNotEmpty)
            .andExpect(jsonPath("$.gameState.players.length()").value(2))
    }

    @Test
    fun `should create private lobby with invite code`() {
        val token = registerAndGetToken("lobbytest9")

        val request = mapOf("name" to "Private Lobby", "isPrivate" to true)
        mockMvc.perform(
            post("/api/lobbies")
                .header("Authorization", "Bearer $token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.isPrivate").value(true))
            .andExpect(jsonPath("$.inviteCode").isNotEmpty)
    }

    @Test
    fun `should join private lobby by invite code`() {
        val token1 = registerAndGetToken("lobbytest10a")
        val token2 = registerAndGetToken("lobbytest10b")

        // Create private lobby
        val createReq = mapOf("name" to "Code Join Lobby", "isPrivate" to true)
        val createResult = mockMvc.perform(
            post("/api/lobbies")
                .header("Authorization", "Bearer $token1")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(createReq))
        ).andExpect(status().isOk).andReturn()

        val inviteCode = objectMapper.readTree(createResult.response.contentAsString).get("inviteCode").asText()

        // Join by code
        val joinReq = mapOf("inviteCode" to inviteCode)
        mockMvc.perform(
            post("/api/lobbies/join-by-code")
                .header("Authorization", "Bearer $token2")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(joinReq))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.lobby.players.length()").value(2))
            .andExpect(jsonPath("$.gameState").isNotEmpty) // auto-started
    }

    @Test
    fun `should reject join by invalid invite code`() {
        val token = registerAndGetToken("lobbytest11")

        val joinReq = mapOf("inviteCode" to "CRIB-ZZZZ")
        mockMvc.perform(
            post("/api/lobbies/join-by-code")
                .header("Authorization", "Bearer $token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(joinReq))
        ).andExpect(status().isBadRequest)
    }

    @Test
    fun `guest should not be able to browse public lobbies`() {
        val guestToken = getGuestToken()

        mockMvc.perform(
            get("/api/lobbies/waiting")
                .header("Authorization", "Bearer $guestToken")
        ).andExpect(status().isBadRequest)
    }

    @Test
    fun `guest should not join public lobby by id`() {
        val token = registerAndGetToken("lobbytest12")
        val guestToken = getGuestToken()

        // Create public lobby
        val request = mapOf("name" to "Public Lobby")
        val createResult = mockMvc.perform(
            post("/api/lobbies")
                .header("Authorization", "Bearer $token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        ).andExpect(status().isOk).andReturn()

        val lobbyId = objectMapper.readTree(createResult.response.contentAsString).get("id").asText()

        // Guest tries to join public lobby
        mockMvc.perform(
            post("/api/lobbies/$lobbyId/join")
                .header("Authorization", "Bearer $guestToken")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}")
        ).andExpect(status().isBadRequest)
    }

    @Test
    fun `guest should join private lobby by invite code`() {
        val token = registerAndGetToken("lobbytest13")
        val guestToken = getGuestToken()

        // Create private lobby
        val createReq = mapOf("name" to "Guest Invite Lobby", "isPrivate" to true)
        val createResult = mockMvc.perform(
            post("/api/lobbies")
                .header("Authorization", "Bearer $token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(createReq))
        ).andExpect(status().isOk).andReturn()

        val inviteCode = objectMapper.readTree(createResult.response.contentAsString).get("inviteCode").asText()

        // Guest joins by code
        val joinReq = mapOf("inviteCode" to inviteCode)
        mockMvc.perform(
            post("/api/lobbies/join-by-code")
                .header("Authorization", "Bearer $guestToken")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(joinReq))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.lobby.players.length()").value(2))
    }
}
