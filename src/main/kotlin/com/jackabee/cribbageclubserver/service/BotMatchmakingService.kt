package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.config.BotProperties
import com.jackabee.cribbageclubserver.entity.LobbyEntity
import com.jackabee.cribbageclubserver.entity.UserEntity
import com.jackabee.cribbageclubserver.model.lobby.LobbyPlayer
import com.jackabee.cribbageclubserver.model.lobby.LobbyStatus
import com.jackabee.cribbageclubserver.repository.GameRepository
import com.jackabee.cribbageclubserver.repository.LobbyRepository
import com.jackabee.cribbageclubserver.repository.PlayerStatsRepository
import com.jackabee.cribbageclubserver.repository.UserRepository
import com.jackabee.cribbageclubserver.websocket.WebSocketSessionRegistry
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue
import org.slf4j.LoggerFactory
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Service
import java.time.Instant
import kotlin.math.abs
import kotlin.random.Random

/**
 * Fallback matchmaking: when a quick-match lobby has waited [BotProperties.waitSeconds]
 * with no human match, a pool bot joins and plays the waiter.
 *
 * Bots only ever fill lobbies flagged `isQuickMatch` — never user-created public
 * lobbies. The join reuses [LobbyService.joinLobbyById] verbatim, so game
 * auto-start, lobby persistence, and the "Game Found" notification (carrying the
 * bot's human name) all behave exactly as they do for a human joiner.
 *
 * Single-node assumption (inherited from the in-memory engine cache and session
 * registry): the sweep runs on one instance, so no cross-node coordination.
 */
@Service
@Suppress("LongParameterList") // Read-mostly collaborators; the join itself goes through LobbyService.
class BotMatchmakingService(
    private val lobbyService: LobbyService,
    private val lobbyRepository: LobbyRepository,
    private val userRepository: UserRepository,
    private val playerStatsRepository: PlayerStatsRepository,
    private val gameRepository: GameRepository,
    private val sessionRegistry: WebSocketSessionRegistry,
    private val botProperties: BotProperties,
    private val objectMapper: ObjectMapper,
) {
    private val logger = LoggerFactory.getLogger(BotMatchmakingService::class.java)

    companion object {
        /** Pick randomly among this many closest-rated bots so the same persona doesn't always appear. */
        private const val SELECTION_POOL_SIZE = 3
        private const val DEFAULT_RATING = 1500.0
    }

    @Suppress("TooGenericExceptionCaught") // Per-lobby isolation: one bad lobby must not stop the sweep.
    @Scheduled(fixedDelayString = "\${cribbage.bots.match-sweep-interval-ms:10000}")
    fun sweep() {
        if (!botProperties.enabled) return

        val cutoff = Instant.now().minusSeconds(botProperties.waitSeconds)
        val staleLobbies = lobbyRepository
            .findByStatusAndIsPrivateFalseAndChallengedUserIdIsNull(LobbyStatus.WAITING.name)
            .filter { it.isQuickMatch && !it.createdAt.isAfter(cutoff) }

        for (entity in staleLobbies) {
            // Per-lobby isolation: a human joining between query and join makes the
            // bot's join throw (lobby full / no longer WAITING / @Version bump) —
            // that's the race resolving correctly, not an error.
            try {
                fillLobby(entity)
            } catch (e: Exception) {
                logger.debug("Skipped bot fill for lobby {}: {}", entity.id, e.message)
            }
        }
    }

    private fun fillLobby(entity: LobbyEntity) {
        val players: List<LobbyPlayer> = objectMapper.readValue(entity.playersJson)
        val waiter = players.singleOrNull() ?: return

        // Matching an absent player would start their clock and hand them a rated
        // loss; leave the lobby for the cleanup sweep instead.
        if (!sessionRegistry.isUserOnline(waiter.id)) return

        val bot = selectBot(waiter.id)
        if (bot != null) {
            val result = lobbyService.joinLobbyById(entity.id, bot.id!!, bot.displayName ?: bot.username)
            logger.info(
                "Bot {} filled quick-match lobby {} for waiting player {} (game {})",
                bot.username, entity.id, waiter.name, result.gameState?.gameId
            )
        }
    }

    /**
     * The bot rated closest to the waiter, chosen randomly among the closest few.
     * Bots already in an active game with this waiter are excluded so the same
     * persona can't be playing them twice at once.
     */
    private fun selectBot(waiterId: String): UserEntity? {
        val waiterRating = playerStatsRepository.findById(waiterId)
            .map { it.rating }.orElse(DEFAULT_RATING)

        val currentOpponents = gameRepository.findActiveGamesByPlayer(waiterId)
            .flatMap { listOf(it.player1Id, it.player2Id) }
            .toSet()

        val candidates = userRepository.findByIsBotTrue()
            .filter { it.id !in currentOpponents }
            .map { bot ->
                val rating = playerStatsRepository.findById(bot.id!!)
                    .map { it.rating }.orElse(DEFAULT_RATING)
                bot to abs(rating - waiterRating)
            }
            .sortedBy { it.second }

        if (candidates.isEmpty()) return null
        val pool = candidates.take(SELECTION_POOL_SIZE)
        return pool[Random.nextInt(pool.size)].first
    }
}
