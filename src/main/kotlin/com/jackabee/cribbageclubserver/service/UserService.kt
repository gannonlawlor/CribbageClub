package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.entity.UserEntity
import com.jackabee.cribbageclubserver.repository.UserRepository
import org.slf4j.LoggerFactory
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.util.UUID

@Service
class UserService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder,
    private val jwtService: JwtService
) {
    private val logger = LoggerFactory.getLogger(UserService::class.java)

    data class AuthResponse(
        val token: String,
        val userId: String,
        val username: String,
        val displayName: String?,
        val isGuest: Boolean = false
    )

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

        val savedId = saved.id!!
        val token = jwtService.generateToken(savedId, saved.username)
        return AuthResponse(token, savedId, saved.username, saved.displayName)
    }

    @Transactional
    fun login(username: String, password: String): AuthResponse {
        val user = userRepository.findByUsername(username)
            ?: throw IllegalArgumentException("Invalid username or password")

        require(!user.isGuest) { "Guest accounts cannot log in. Use upgrade instead." }

        if (!passwordEncoder.matches(password, user.passwordHash)) {
            throw IllegalArgumentException("Invalid username or password")
        }

        user.lastLoginAt = Instant.now()
        userRepository.save(user)
        logger.info("User logged in: {}", username)

        val userId = user.id!!
        val token = jwtService.generateToken(userId, user.username)
        return AuthResponse(token, userId, user.username, user.displayName)
    }

    @Transactional
    fun createGuest(): AuthResponse {
        val guestId = "guest_${UUID.randomUUID().toString().replace("-", "").take(12)}"
        val user = UserEntity(
            username = guestId,
            passwordHash = null,
            displayName = "Guest",
            isGuest = true
        )
        user.id = guestId
        val saved = userRepository.save(user)
        logger.info("Created guest user: {}", guestId)

        val savedId = saved.id!!
        val token = jwtService.generateToken(savedId, saved.username, isGuest = true)
        return AuthResponse(token, savedId, saved.username, saved.displayName, isGuest = true)
    }

    @Transactional
    fun upgradeGuest(userId: String, username: String, password: String, displayName: String?): AuthResponse {
        require(username.length >= 3) { "Username must be at least 3 characters" }
        require(password.length >= 6) { "Password must be at least 6 characters" }
        require(!userRepository.existsByUsername(username)) { "Username already taken" }

        val user = userRepository.findById(userId).orElse(null)
            ?: throw IllegalArgumentException("User not found")
        require(user.isGuest) { "Only guest accounts can be upgraded" }

        user.username = username
        user.passwordHash = passwordEncoder.encode(password)
        user.displayName = displayName ?: username
        user.isGuest = false
        userRepository.save(user)
        logger.info("Upgraded guest {} to user {}", userId, username)

        val upgradedId = user.id!!
        val token = jwtService.generateToken(upgradedId, user.username)
        return AuthResponse(token, upgradedId, user.username, user.displayName)
    }

    fun getUserById(userId: String): UserEntity? {
        return userRepository.findById(userId).orElse(null)
    }

    fun getUserByUsername(username: String): UserEntity? {
        return userRepository.findByUsername(username)
    }
}
