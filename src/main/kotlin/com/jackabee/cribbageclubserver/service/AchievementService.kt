package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.entity.AchievementProgressEntity
import com.jackabee.cribbageclubserver.entity.GameEntity
import com.jackabee.cribbageclubserver.entity.PlayerAchievementEntity
import com.jackabee.cribbageclubserver.model.achievement.Achievement
import com.jackabee.cribbageclubserver.model.game.GameHistoryEvent
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.repository.AchievementProgressRepository
import com.jackabee.cribbageclubserver.repository.PlayerAchievementRepository
import com.jackabee.cribbageclubserver.websocket.AchievementSummary
import com.jackabee.cribbageclubserver.websocket.AchievementUnlockedNotification
import com.jackabee.cribbageclubserver.websocket.NotificationWebSocketService
import org.slf4j.LoggerFactory
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.transaction.support.TransactionSynchronization
import org.springframework.transaction.support.TransactionSynchronizationManager
import java.time.Instant
import java.util.UUID

/** One achievement's merged catalog + earned + progress view. */
data class AchievementStatus(
    val achievement: Achievement,
    val unlocked: Boolean,
    val unlockedAt: Instant?,
    val progress: Int?
)

@Service
class AchievementService(
    private val playerAchievementRepository: PlayerAchievementRepository,
    private val achievementProgressRepository: AchievementProgressRepository,
    private val playerStatsService: PlayerStatsService,
    private val historyEvaluator: AchievementHistoryEvaluator,
    private val notificationService: NotificationWebSocketService,
    private val pushNotificationService: PushNotificationService
) {
    private val logger = LoggerFactory.getLogger(AchievementService::class.java)

    /**
     * Awards [keys] to [userId], skipping any already earned. Returns only the
     * newly awarded achievements. AI players never earn; guests earn normally
     * (guest upgrade keeps the user id, so their unlocks survive).
     *
     * Notification goes out after commit so a client reacting to it always
     * finds the rows it was told about.
     */
    @Transactional
    fun award(userId: String, keys: Set<Achievement>, gameId: String? = null): List<Achievement> {
        if (keys.isEmpty() || userId.startsWith("ai_")) return emptyList()

        val existing = playerAchievementRepository
            .findByUserIdAndAchievementKeyIn(userId, keys.map { it.name })
            .map { it.achievementKey }
            .toSet()

        val newlyAwarded = mutableListOf<Achievement>()
        for (achievement in keys) {
            if (achievement.name in existing) continue
            try {
                playerAchievementRepository.saveAndFlush(
                    PlayerAchievementEntity(
                        id = UUID.randomUUID().toString(),
                        userId = userId,
                        achievementKey = achievement.name,
                        unlockedAt = Instant.now(),
                        gameId = gameId
                    )
                )
                newlyAwarded += achievement
            } catch (e: DataIntegrityViolationException) {
                // Concurrency backstop: another transaction awarded it first.
                logger.debug("Achievement {} already awarded to {} concurrently", achievement, userId)
            }
        }

        if (newlyAwarded.isNotEmpty()) {
            logger.info("Awarded {} to {}", newlyAwarded.map { it.name }, userId)
            notifyAfterCommit(userId, newlyAwarded)
        }
        return newlyAwarded
    }

    /**
     * Evaluates a finished game for every human player. Callers must have set
     * [GameEntity.winnerId] already. Returns everything newly awarded — the
     * import path surfaces this in its response.
     */
    @Transactional
    fun evaluateGameEnd(entity: GameEntity, finalState: GameState): List<Achievement> {
        val forfeited = finalState.history.any { it is GameHistoryEvent.GameForfeited }
        val newlyAwarded = mutableListOf<Achievement>()

        for (player in finalState.players) {
            if (player.id.startsWith("ai_")) continue
            val won = entity.winnerId == player.id
            val opponent = finalState.players.firstOrNull { it.id != player.id } ?: continue

            val keys = mutableSetOf(Achievement.FIRST_GAME)

            // Post-launch counters: wins and streak. Forfeit wins count, the
            // same way recordGameResult counts them.
            val progress = progressFor(player.id)
            if (won) {
                progress.wins++
                progress.currentWinStreak++
            } else {
                progress.currentWinStreak = 0
            }
            progress.updatedAt = Instant.now()
            achievementProgressRepository.save(progress)

            if (progress.wins >= 10) keys += Achievement.WINS_10
            if (progress.wins >= 50) keys += Achievement.WINS_50
            if (progress.wins >= 100) keys += Achievement.WINS_100
            if (progress.currentWinStreak >= 5) keys += Achievement.STREAK_5
            if (progress.currentWinStreak >= 10) keys += Achievement.STREAK_10

            if (won) {
                keys += Achievement.FIRST_WIN
                if (entity.isAIGame) {
                    when (entity.aiDifficulty) {
                        "medium" -> keys += Achievement.BEAT_AI_MEDIUM
                        "hard" -> keys += Achievement.BEAT_AI_HARD
                    }
                } else {
                    keys += Achievement.FIRST_ONLINE_WIN
                    // Ratings only move in rated (human) games.
                    if (playerStatsService.getStats(player.id).rating >= 1600.0) {
                        keys += Achievement.RATING_1600
                    }
                }

                // A forfeit forces the winner to 121, which would make skunks
                // and comebacks farmable — real feats only.
                if (!forfeited) {
                    if (opponent.score < 91) keys += Achievement.SKUNK
                    if (opponent.score < 61) keys += Achievement.DOUBLE_SKUNK
                    if (opponent.score < 91 && entity.isAIGame && entity.aiDifficulty == "hard") {
                        keys += Achievement.SKUNK_AI_HARD
                    }
                }

                if (historyEvaluator.wonFromBehind(player.id, finalState)) {
                    keys += Achievement.COMEBACK
                }
            }

            keys += historyEvaluator.evaluate(player.id, finalState)

            newlyAwarded += award(player.id, keys, gameId = entity.id)
        }

        return newlyAwarded
    }

    @Transactional
    fun evaluatePuzzleSolve(userId: String, isOptimal: Boolean): List<Achievement> {
        if (userId.startsWith("ai_")) return emptyList()
        val keys = mutableSetOf(Achievement.PUZZLE_FIRST)

        if (isOptimal) {
            val progress = progressFor(userId)
            progress.optimalPuzzleSolves++
            progress.updatedAt = Instant.now()
            achievementProgressRepository.save(progress)
            if (progress.optimalPuzzleSolves >= 10) keys += Achievement.PUZZLE_OPTIMAL_10
        }

        return award(userId, keys)
    }

    @Transactional
    fun evaluateFriendAccepted(userIdA: String, userIdB: String) {
        award(userIdA, setOf(Achievement.FRIEND_ADDED))
        award(userIdB, setOf(Achievement.FRIEND_ADDED))
    }

    /** Full catalog merged with what [userId] has earned and their counters. */
    fun getAchievementsFor(userId: String): List<AchievementStatus> {
        val earned = playerAchievementRepository.findByUserId(userId)
            .associateBy { it.achievementKey }
        val progress = achievementProgressRepository.findById(userId).orElse(null)

        return Achievement.entries.map { achievement ->
            val row = earned[achievement.name]
            AchievementStatus(
                achievement = achievement,
                unlocked = row != null,
                unlockedAt = row?.unlockedAt,
                progress = achievement.target?.let { target ->
                    if (row != null) target else counterValue(achievement, progress)
                }
            )
        }
    }

    private fun counterValue(achievement: Achievement, progress: AchievementProgressEntity?): Int {
        if (progress == null) return 0
        return when (achievement) {
            Achievement.WINS_10, Achievement.WINS_50, Achievement.WINS_100 -> progress.wins
            Achievement.STREAK_5, Achievement.STREAK_10 -> progress.currentWinStreak
            Achievement.PUZZLE_OPTIMAL_10 -> progress.optimalPuzzleSolves
            else -> 0
        }
    }

    private fun progressFor(userId: String): AchievementProgressEntity =
        achievementProgressRepository.findById(userId)
            .orElse(AchievementProgressEntity(userId = userId))

    /**
     * WS + push after the surrounding transaction commits, so a client that
     * fetches on the notification sees the new rows. Falls back to immediate
     * delivery when no transaction is active.
     */
    private fun notifyAfterCommit(userId: String, achievements: List<Achievement>) {
        val send = {
            try {
                val summaries = achievements.map {
                    AchievementSummary(
                        key = it.name,
                        name = it.displayName,
                        description = it.description,
                        tier = it.tier.name
                    )
                }
                notificationService.sendAchievementUnlockedNotification(
                    userId,
                    AchievementUnlockedNotification(achievements = summaries)
                )
                pushNotificationService.sendIfOffline(
                    userId,
                    title = "Achievement unlocked!",
                    body = achievements.joinToString(", ") { it.displayName },
                    data = mapOf(
                        "type" to "ACHIEVEMENT_UNLOCKED",
                        "keys" to achievements.joinToString(",") { it.name }
                    )
                )
            } catch (e: Exception) {
                logger.warn("Failed to send achievement notification to {}: {}", userId, e.message)
            }
        }

        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(
                object : TransactionSynchronization {
                    override fun afterCommit() = send()
                }
            )
        } else {
            send()
        }
    }
}
