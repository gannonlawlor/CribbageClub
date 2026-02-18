package com.jackabee.cribbageclubserver.service

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import kotlin.test.assertEquals
import kotlin.test.assertFalse
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

    @Test
    fun `should create guest user`() {
        val result = userService.createGuest()

        assertNotNull(result.token)
        assertTrue(result.userId.startsWith("guest_"))
        assertTrue(result.isGuest)
        assertEquals("Guest", result.displayName)
    }

    @Test
    fun `should reject login for guest user`() {
        val guest = userService.createGuest()

        assertThrows<IllegalArgumentException> {
            userService.login(guest.username, "anything")
        }
    }

    @Test
    fun `should upgrade guest to full account`() {
        val guest = userService.createGuest()
        val upgraded = userService.upgradeGuest(guest.userId, "upgradeduser1", "password123", "Upgraded User")

        assertEquals("upgradeduser1", upgraded.username)
        assertEquals("Upgraded User", upgraded.displayName)
        assertFalse(upgraded.isGuest)
        assertNotNull(upgraded.token)
    }

    @Test
    fun `should login after upgrading guest`() {
        val guest = userService.createGuest()
        userService.upgradeGuest(guest.userId, "upgradedlogin1", "password123", null)

        val loginResult = userService.login("upgradedlogin1", "password123")
        assertNotNull(loginResult.token)
        assertEquals("upgradedlogin1", loginResult.username)
    }

    @Test
    fun `should reject upgrading non-guest user`() {
        val registered = userService.register("notaguest1", "password123", null)

        assertThrows<IllegalArgumentException> {
            userService.upgradeGuest(registered.userId, "newname", "password123", null)
        }
    }

    @Test
    fun `should reject upgrade with short username`() {
        val guest = userService.createGuest()

        assertThrows<IllegalArgumentException> {
            userService.upgradeGuest(guest.userId, "ab", "password123", null)
        }
    }

    @Test
    fun `should reject upgrade with short password`() {
        val guest = userService.createGuest()

        assertThrows<IllegalArgumentException> {
            userService.upgradeGuest(guest.userId, "validname", "12345", null)
        }
    }

    @Test
    fun `should reject upgrade with taken username`() {
        userService.register("takenname1", "password123", null)
        val guest = userService.createGuest()

        assertThrows<IllegalArgumentException> {
            userService.upgradeGuest(guest.userId, "takenname1", "password123", null)
        }
    }

    @Test
    fun `should use username as display name when upgrade display name not provided`() {
        val guest = userService.createGuest()
        val upgraded = userService.upgradeGuest(guest.userId, "defaultdisplay1", "password123", null)
        assertEquals("defaultdisplay1", upgraded.displayName)
    }
}
