package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.service.UserService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Authentication", description = "User registration, login, and profile")
class AuthController(
    private val userService: UserService
) {

    @Operation(summary = "Register a new user account")
    @PostMapping("/register")
    fun register(@RequestBody request: RegisterRequest): UserService.AuthResponse {
        return userService.register(
            username = request.username,
            password = request.password,
            displayName = request.displayName
        )
    }

    @Operation(summary = "Login and receive a JWT token")
    @PostMapping("/login")
    fun login(@RequestBody request: LoginRequest): UserService.AuthResponse {
        return userService.login(
            username = request.username,
            password = request.password
        )
    }

    @Operation(summary = "Get current authenticated user info")
    @GetMapping("/me")
    fun me(@RequestAttribute("userId") userId: String): UserInfoResponse {
        val user = userService.getUserById(userId)
            ?: throw IllegalArgumentException("User not found")
        return UserInfoResponse(
            userId = user.id!!,
            username = user.username,
            displayName = user.displayName
        )
    }
}

data class RegisterRequest(
    val username: String,
    val password: String,
    val displayName: String? = null
)

data class LoginRequest(
    val username: String,
    val password: String
)

data class UserInfoResponse(
    val userId: String,
    val username: String,
    val displayName: String?
)
