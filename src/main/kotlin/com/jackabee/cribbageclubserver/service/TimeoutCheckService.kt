package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.model.action.ForfeitReason
import com.jackabee.cribbageclubserver.repository.GameRepository
import org.slf4j.LoggerFactory
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Service

@Service
class TimeoutCheckService(
    private val gameRepository: GameRepository,
    private val turnTimerService: TurnTimerService,
    private val forfeitService: ForfeitService
) {
    private val logger = LoggerFactory.getLogger(TimeoutCheckService::class.java)

    @Scheduled(fixedRate = 5000)
    fun checkTimeouts() {
        val activeTimedGames = gameRepository.findActiveTimedGames()

        for (entity in activeTimedGames) {
            try {
                val timedOutPlayerId = turnTimerService.checkTimeout(entity.id, entity)
                if (timedOutPlayerId != null) {
                    logger.info("Player {} timed out in game {}", timedOutPlayerId, entity.id)
                    forfeitService.forfeitGame(entity.id, timedOutPlayerId, ForfeitReason.TIMEOUT)
                }
            } catch (e: Exception) {
                logger.warn("Error checking timeout for game {}: {}", entity.id, e.message)
            }
        }
    }
}
