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
class AuthControllerTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Test
    fun `should register a new user`() {
        val request = mapOf("username" to "authtest1", "password" to "password123", "displayName" to "Auth Test")

        mockMvc.perform(
            post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.token").isNotEmpty)
            .andExpect(jsonPath("$.userId").isNotEmpty)
            .andExpect(jsonPath("$.username").value("authtest1"))
    }

    @Test
    fun `should login with valid credentials`() {
        // Register first
        val registerReq = mapOf("username" to "authtest2", "password" to "password123")
        mockMvc.perform(
            post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerReq))
        ).andExpect(status().isOk)

        // Login
        val loginReq = mapOf("username" to "authtest2", "password" to "password123")
        mockMvc.perform(
            post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginReq))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.token").isNotEmpty)
            .andExpect(jsonPath("$.username").value("authtest2"))
    }

    @Test
    fun `should reject login with wrong password`() {
        val registerReq = mapOf("username" to "authtest3", "password" to "password123")
        mockMvc.perform(
            post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerReq))
        ).andExpect(status().isOk)

        val loginReq = mapOf("username" to "authtest3", "password" to "wrong")
        mockMvc.perform(
            post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginReq))
        ).andExpect(status().isBadRequest)
    }

    @Test
    fun `should reject unauthenticated access to protected endpoints`() {
        mockMvc.perform(get("/api/games"))
            .andExpect(status().isForbidden)
    }

    @Test
    fun `should allow authenticated access to protected endpoints`() {
        // Register and get token
        val registerReq = mapOf("username" to "authtest4", "password" to "password123")
        val result = mockMvc.perform(
            post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerReq))
        )
            .andExpect(status().isOk)
            .andReturn()

        val token = objectMapper.readTree(result.response.contentAsString).get("token").asText()

        // Access protected endpoint with token
        mockMvc.perform(
            get("/api/games")
                .header("Authorization", "Bearer $token")
        ).andExpect(status().isOk)
    }

    @Test
    fun `should get current user info with valid token`() {
        val registerReq = mapOf("username" to "authtest5", "password" to "password123", "displayName" to "Test Five")
        val result = mockMvc.perform(
            post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(registerReq))
        )
            .andExpect(status().isOk)
            .andReturn()

        val token = objectMapper.readTree(result.response.contentAsString).get("token").asText()

        mockMvc.perform(
            get("/api/auth/me")
                .header("Authorization", "Bearer $token")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.username").value("authtest5"))
            .andExpect(jsonPath("$.displayName").value("Test Five"))
            .andExpect(jsonPath("$.isGuest").value(false))
    }

    @Test
    fun `should create guest account without request body`() {
        mockMvc.perform(post("/api/auth/guest"))
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.token").isNotEmpty)
            .andExpect(jsonPath("$.userId").value(org.hamcrest.Matchers.startsWith("guest_")))
            .andExpect(jsonPath("$.isGuest").value(true))
            .andExpect(jsonPath("$.displayName").value("Guest"))
    }

    @Test
    fun `should access protected endpoints with guest token`() {
        val result = mockMvc.perform(post("/api/auth/guest"))
            .andExpect(status().isOk)
            .andReturn()

        val token = objectMapper.readTree(result.response.contentAsString).get("token").asText()

        // Guest should be able to create AI game
        val gameReq = mapOf("difficulty" to "basic")
        mockMvc.perform(
            post("/api/games/ai")
                .header("Authorization", "Bearer $token")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(gameReq))
        ).andExpect(status().isOk)
    }

    @Test
    fun `should upgrade guest to full account`() {
        val guestResult = mockMvc.perform(post("/api/auth/guest"))
            .andExpect(status().isOk)
            .andReturn()

        val guestToken = objectMapper.readTree(guestResult.response.contentAsString).get("token").asText()

        val upgradeReq = mapOf("username" to "upgraded_auth1", "password" to "password123", "displayName" to "Real User")
        mockMvc.perform(
            post("/api/auth/upgrade")
                .header("Authorization", "Bearer $guestToken")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(upgradeReq))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.username").value("upgraded_auth1"))
            .andExpect(jsonPath("$.displayName").value("Real User"))
            .andExpect(jsonPath("$.isGuest").value(false))
    }

    @Test
    fun `should reject upgrade without auth`() {
        val upgradeReq = mapOf("username" to "nope", "password" to "password123")
        mockMvc.perform(
            post("/api/auth/upgrade")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(upgradeReq))
        ).andExpect(status().isForbidden)
    }

    @Test
    fun `should get me with isGuest true for guest`() {
        val result = mockMvc.perform(post("/api/auth/guest"))
            .andExpect(status().isOk)
            .andReturn()

        val token = objectMapper.readTree(result.response.contentAsString).get("token").asText()

        mockMvc.perform(
            get("/api/auth/me")
                .header("Authorization", "Bearer $token")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.isGuest").value(true))
            .andExpect(jsonPath("$.displayName").value("Guest"))
    }

    @Test
    fun `should reject login for guest account`() {
        val guestResult = mockMvc.perform(post("/api/auth/guest"))
            .andExpect(status().isOk)
            .andReturn()

        val guestUsername = objectMapper.readTree(guestResult.response.contentAsString).get("username").asText()

        val loginReq = mapOf("username" to guestUsername, "password" to "anything")
        mockMvc.perform(
            post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginReq))
        ).andExpect(status().isBadRequest)
    }
}
