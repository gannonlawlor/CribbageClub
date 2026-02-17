package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.service.UserService
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/auth")
class AuthController(
    private val userService: UserService
) {

    @PostMapping("/register")
    fun register(@RequestBody request: RegisterRequest): UserService.AuthResponse {
        return userService.register(
            username = request.username,
            password = request.password,
            displayName = request.displayName
        )
    }

    @PostMapping("/login")
    fun login(@RequestBody request: LoginRequest): UserService.AuthResponse {
        return userService.login(
            username = request.username,
            password = request.password
        )
    }

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
