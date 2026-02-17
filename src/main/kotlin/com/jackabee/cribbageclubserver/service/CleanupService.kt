package com.jackabee.cribbageclubserver.service

import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Service
import java.time.Instant
import java.time.temporal.ChronoUnit

@Service
class CleanupService(
    private val gameService: GameService,
    private val lobbyService: LobbyService
) {
    private val logger = LoggerFactory.getLogger(CleanupService::class.java)

    @Value("\${game.timeout.inactive-minutes:30}")
    private var gameTimeoutMinutes: Long = 30

    @Value("\${lobby.timeout.inactive-minutes:15}")
    private var lobbyTimeoutMinutes: Long = 15

    @Scheduled(cron = "\${cleanup.schedule.cron:0 */5 * * * *}")
    fun cleanupInactiveResources() {
        val now = Instant.now()

        val gameThreshold = now.minus(gameTimeoutMinutes, ChronoUnit.MINUTES)
        val removedGames = gameService.removeInactiveGames(gameThreshold)
        if (removedGames.isNotEmpty()) {
            logger.info("Cleaned up {} inactive games: {}", removedGames.size, removedGames)
        }

        val lobbyThreshold = now.minus(lobbyTimeoutMinutes, ChronoUnit.MINUTES)
        val removedLobbies = lobbyService.removeInactiveLobbies(lobbyThreshold)
        if (removedLobbies.isNotEmpty()) {
            logger.info("Cleaned up {} inactive lobbies: {}", removedLobbies.size, removedLobbies)
        }
    }
}
