package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.service.DeviceTokenService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/device-tokens")
@Tag(name = "Device Tokens", description = "Push notification token management")
class DeviceTokenController(
    private val deviceTokenService: DeviceTokenService
) {

    @Operation(summary = "Register a device token for push notifications")
    @PostMapping
    fun registerToken(
        @RequestBody request: RegisterTokenRequest,
        @RequestAttribute("userId") userId: String
    ): ResponseEntity<Void> {
        deviceTokenService.registerToken(userId, request.token, request.platform)
        return ResponseEntity.ok().build()
    }

    @Operation(summary = "Unregister a device token")
    @DeleteMapping
    fun unregisterToken(
        @RequestBody request: UnregisterTokenRequest,
        @RequestAttribute("userId") userId: String
    ): ResponseEntity<Void> {
        deviceTokenService.unregisterToken(userId, request.token)
        return ResponseEntity.noContent().build()
    }
}

data class RegisterTokenRequest(val token: String, val platform: String)
data class UnregisterTokenRequest(val token: String)
