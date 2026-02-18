package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.entity.UserEntity
import com.jackabee.cribbageclubserver.repository.UserRepository
import org.slf4j.LoggerFactory
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant

@Service
class UserService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder,
    private val jwtService: JwtService
) {
    private val logger = LoggerFactory.getLogger(UserService::class.java)

    data class AuthResponse(val token: String, val userId: String, val username: String, val displayName: String?)

    @Transactional
    fun register(username: String, password: String, displayName: String?): AuthResponse {
        require(username.length >= 3) { "Username must be at least 3 characters" }
        require(password.length >= 6) { "Password must be at least 6 characters" }
        require(!userRepository.existsByUsername(username)) { "Username already taken" }

        val user = UserEntity(
            username = username,
            passwordHash = passwordEncoder.encode(password),
            displayName = displayName ?: username
        )
        val saved = userRepository.save(user)
        logger.info("Registered user: {}", username)

        val token = jwtService.generateToken(saved.id!!, saved.username)
        return AuthResponse(token, saved.id, saved.username, saved.displayName)
    }

    @Transactional
    fun login(username: String, password: String): AuthResponse {
        val user = userRepository.findByUsername(username)
            ?: throw IllegalArgumentException("Invalid username or password")

        if (!passwordEncoder.matches(password, user.passwordHash)) {
            throw IllegalArgumentException("Invalid username or password")
        }

        user.lastLoginAt = Instant.now()
        userRepository.save(user)
        logger.info("User logged in: {}", username)

        val token = jwtService.generateToken(user.id!!, user.username)
        return AuthResponse(token, user.id, user.username, user.displayName)
    }

    fun getUserById(userId: String): UserEntity? {
        return userRepository.findById(userId).orElse(null)
    }

    fun getUserByUsername(username: String): UserEntity? {
        return userRepository.findByUsername(username)
    }
}
