package com.jackabee.cribbageclubserver.service

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

@SpringBootTest
class UserServiceTest {

    @Autowired
    private lateinit var userService: UserService

    @Test
    fun `should register a new user`() {
        val result = userService.register("testuser1", "password123", "Test User")

        assertNotNull(result.token)
        assertNotNull(result.userId)
        assertEquals("testuser1", result.username)
        assertEquals("Test User", result.displayName)
    }

    @Test
    fun `should login with correct credentials`() {
        userService.register("loginuser", "password123", "Login User")
        val result = userService.login("loginuser", "password123")

        assertNotNull(result.token)
        assertEquals("loginuser", result.username)
    }

    @Test
    fun `should reject login with wrong password`() {
        userService.register("wrongpwuser", "password123", null)

        assertThrows<IllegalArgumentException> {
            userService.login("wrongpwuser", "wrongpassword")
        }
    }

    @Test
    fun `should reject login with nonexistent user`() {
        assertThrows<IllegalArgumentException> {
            userService.login("nonexistent", "password123")
        }
    }

    @Test
    fun `should reject duplicate username registration`() {
        userService.register("dupuser", "password123", null)

        assertThrows<IllegalArgumentException> {
            userService.register("dupuser", "password456", null)
        }
    }

    @Test
    fun `should reject short username`() {
        assertThrows<IllegalArgumentException> {
            userService.register("ab", "password123", null)
        }
    }

    @Test
    fun `should reject short password`() {
        assertThrows<IllegalArgumentException> {
            userService.register("shortpw", "12345", null)
        }
    }

    @Test
    fun `should use username as display name when not provided`() {
        val result = userService.register("nodisplay", "password123", null)
        assertEquals("nodisplay", result.displayName)
    }

    @Test
    fun `should generate valid JWT token on register`() {
        val result = userService.register("jwtuser", "password123", null)
        assertTrue(result.token.split(".").size == 3) // JWT has 3 parts
    }
}
