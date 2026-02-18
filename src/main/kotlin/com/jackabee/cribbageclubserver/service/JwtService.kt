package com.jackabee.cribbageclubserver.service

import io.jsonwebtoken.Claims
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.util.Date
import javax.crypto.SecretKey

@Service
class JwtService(
    @Value("\${jwt.secret:default-dev-secret-key-that-is-at-least-256-bits-long!!}") private val secret: String,
    @Value("\${jwt.expiration-ms:86400000}") private val expirationMs: Long
) {
    private val key: SecretKey by lazy {
        Keys.hmacShaKeyFor(secret.toByteArray())
    }

    fun generateToken(userId: String, username: String, isGuest: Boolean = false): String {
        val now = Date()
        val expiry = Date(now.time + expirationMs)

        return Jwts.builder()
            .subject(userId)
            .claim("username", username)
            .claim("isGuest", isGuest)
            .issuedAt(now)
            .expiration(expiry)
            .signWith(key)
            .compact()
    }

    fun getUserIdFromToken(token: String): String? {
        return try {
            getClaims(token)?.subject
        } catch (e: Exception) {
            null
        }
    }

    fun getUsernameFromToken(token: String): String? {
        return try {
            getClaims(token)?.get("username", String::class.java)
        } catch (e: Exception) {
            null
        }
    }

    fun isGuestFromToken(token: String): Boolean {
        return try {
            getClaims(token)?.get("isGuest", java.lang.Boolean::class.java)?.booleanValue() ?: false
        } catch (e: Exception) {
            false
        }
    }

    fun isTokenValid(token: String): Boolean {
        return try {
            val claims = getClaims(token) ?: return false
            !claims.expiration.before(Date())
        } catch (e: Exception) {
            false
        }
    }

    private fun getClaims(token: String): Claims? {
        return try {
            Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .payload
        } catch (e: Exception) {
            null
        }
    }
}
