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
    }
}
