package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.entity.AchievementProgressEntity
import com.jackabee.cribbageclubserver.entity.GameEntity
import com.jackabee.cribbageclubserver.entity.PlayerAchievementEntity
import com.jackabee.cribbageclubserver.entity.PlayerStatsEntity
import com.jackabee.cribbageclubserver.model.achievement.Achievement
import com.jackabee.cribbageclubserver.model.game.GameHistoryEvent
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.player.Player
import com.jackabee.cribbageclubserver.repository.AchievementProgressRepository
import com.jackabee.cribbageclubserver.repository.PlayerAchievementRepository
import com.jackabee.cribbageclubserver.websocket.AchievementUnlockedNotification
import com.jackabee.cribbageclubserver.websocket.NotificationWebSocketService
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.ExtendWith
import org.mockito.Mock
import org.mockito.junit.jupiter.MockitoExtension
import org.mockito.junit.jupiter.MockitoSettings
import org.mockito.quality.Strictness
import org.mockito.kotlin.*
import org.springframework.dao.DataIntegrityViolationException
import java.time.Instant
import java.util.Optional
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

@ExtendWith(MockitoExtension::class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AchievementServiceTest {

    @Mock
    private lateinit var playerAchievementRepository: PlayerAchievementRepository

    @Mock
    private lateinit var achievementProgressRepository: AchievementProgressRepository

    @Mock
    private lateinit var playerStatsService: PlayerStatsService

    @Mock
    private lateinit var notificationService: NotificationWebSocketService

    @Mock
    private lateinit var pushNotificationService: PushNotificationService

    private lateinit var service: AchievementService

    private val me = "user1"
    private val them = "user2"

    @BeforeEach
    fun setUp() {
        service = AchievementService(
            playerAchievementRepository,
            achievementProgressRepository,
            playerStatsService,
            AchievementHistoryEvaluator(),
            notificationService,
            pushNotificationService
        )
        // saveAndFlush/save/getStats return non-null (Spring @NonNullApi), so
        // the whenever(mock.call()) form NPEs on Kotlin's intrinsic check —
        // stub them with the do*().whenever() form instead.
        whenever(playerAchievementRepository.findByUserIdAndAchievementKeyIn(any(), any()))
            .thenReturn(emptyList())
        doAnswer { it.arguments[0] }
            .whenever(playerAchievementRepository).saveAndFlush(any<PlayerAchievementEntity>())
        whenever(achievementProgressRepository.findById(any())).thenReturn(Optional.empty())
        doAnswer { it.arguments[0] }
            .whenever(achievementProgressRepository).save(any<AchievementProgressEntity>())
        doReturn(PlayerStatsEntity(playerId = me)).whenever(playerStatsService).getStats(any())
    }

    private fun gameState(
        winnerScore: Int = 121,
        loserScore: Int = 90,
        history: List<GameHistoryEvent> = emptyList(),
        opponentId: String = them
    ) = GameState(
        gameId = "g1",
        players = listOf(Player(me, "Me", score = winnerScore), Player(opponentId, "Them", score = loserScore)),
        stage = GameStage.GAME_OVER,
        history = history
    )

    private fun entity(
        winnerId: String = me,
        isAIGame: Boolean = false,
        aiDifficulty: String? = null,
        opponentId: String = them
    ) = GameEntity(
        id = "g1",
        player1Id = me,
        player1Name = "Me",
        player2Id = opponentId,
        player2Name = "Them",
        isAIGame = isAIGame,
        aiDifficulty = aiDifficulty,
        winnerId = winnerId
    )

    @Test
    fun `award skips already-earned achievements`() {
        whenever(playerAchievementRepository.findByUserIdAndAchievementKeyIn(eq(me), any()))
            .thenReturn(
                listOf(
                    PlayerAchievementEntity("row1", me, Achievement.FIRST_WIN.name, Instant.now())
                )
            )

        val awarded = service.award(me, setOf(Achievement.FIRST_WIN, Achievement.SKUNK))

        assertEquals(listOf(Achievement.SKUNK), awarded)
        verify(playerAchievementRepository, times(1)).saveAndFlush(any())
    }

    @Test
    fun `award never gives achievements to AI players`() {
        val awarded = service.award("ai_hard", setOf(Achievement.FIRST_WIN))
        assertTrue(awarded.isEmpty())
        verify(playerAchievementRepository, never()).saveAndFlush(any())
    }

    @Test
    fun `guests earn achievements normally`() {
        val awarded = service.award("guest_abc", setOf(Achievement.FIRST_WIN))
        assertEquals(listOf(Achievement.FIRST_WIN), awarded)
    }

    @Test
    fun `unique constraint race is swallowed and the row is not double-reported`() {
        doThrow(DataIntegrityViolationException("duplicate"))
            .whenever(playerAchievementRepository).saveAndFlush(any<PlayerAchievementEntity>())

        val awarded = service.award(me, setOf(Achievement.FIRST_WIN))

        assertTrue(awarded.isEmpty())
        verify(notificationService, never()).sendAchievementUnlockedNotification(any(), any())
    }

    @Test
    fun `award notifies over websocket and push with the new unlocks`() {
        service.award(me, setOf(Achievement.FIRST_WIN))

        val captor = argumentCaptor<AchievementUnlockedNotification>()
        verify(notificationService).sendAchievementUnlockedNotification(eq(me), captor.capture())
        assertEquals("ACHIEVEMENT_UNLOCKED", captor.firstValue.type)
        assertEquals(Achievement.FIRST_WIN.name, captor.firstValue.achievements.single().key)
        verify(pushNotificationService).sendIfOffline(eq(me), any(), any(), any())
    }

    @Test
    fun `winning a human game awards the basics and counts progress`() {
        val awarded = service.evaluateGameEnd(entity(), gameState())

        assertTrue(Achievement.FIRST_GAME in awarded)
        assertTrue(Achievement.FIRST_WIN in awarded)
        assertTrue(Achievement.FIRST_ONLINE_WIN in awarded)
        // Opponent finished on 90 — under the 91 skunk line.
        assertTrue(Achievement.SKUNK in awarded)

        val captor = argumentCaptor<AchievementProgressEntity>()
        verify(achievementProgressRepository, atLeastOnce()).save(captor.capture())
        val mine = captor.allValues.first { it.userId == me }
        assertEquals(1, mine.wins)
        assertEquals(1, mine.currentWinStreak)
    }

    @Test
    fun `losing resets the win streak and still awards FIRST_GAME`() {
        whenever(achievementProgressRepository.findById(them)).thenReturn(
            Optional.of(AchievementProgressEntity(userId = them, wins = 4, currentWinStreak = 4))
        )

        val awarded = service.evaluateGameEnd(entity(winnerId = me), gameState(loserScore = 95))

        assertTrue(Achievement.FIRST_GAME in awarded)

        val captor = argumentCaptor<AchievementProgressEntity>()
        verify(achievementProgressRepository, atLeastOnce()).save(captor.capture())
        val theirs = captor.allValues.first { it.userId == them }
        assertEquals(4, theirs.wins)
        assertEquals(0, theirs.currentWinStreak)
    }

    @Test
    fun `win counters cross their thresholds from the progress row`() {
        whenever(achievementProgressRepository.findById(me)).thenReturn(
            Optional.of(AchievementProgressEntity(userId = me, wins = 9, currentWinStreak = 4))
        )

        val awarded = service.evaluateGameEnd(entity(), gameState(loserScore = 95))

        assertTrue(Achievement.WINS_10 in awarded)
        assertTrue(Achievement.STREAK_5 in awarded)
        assertFalse(Achievement.WINS_50 in awarded)
        assertFalse(Achievement.STREAK_10 in awarded)
    }

    @Test
    fun `beating the hard AI awards BEAT_AI_HARD and a skunk awards SKUNK_AI_HARD`() {
        val awarded = service.evaluateGameEnd(
            entity(isAIGame = true, aiDifficulty = "hard", opponentId = "ai_hard"),
            gameState(loserScore = 60, opponentId = "ai_hard")
        )

        assertTrue(Achievement.BEAT_AI_HARD in awarded)
        assertTrue(Achievement.SKUNK in awarded)
        assertTrue(Achievement.DOUBLE_SKUNK in awarded)
        assertTrue(Achievement.SKUNK_AI_HARD in awarded)
        assertFalse(Achievement.FIRST_ONLINE_WIN in awarded)
        // The AI itself earned nothing.
        verify(playerAchievementRepository, never())
            .findByUserIdAndAchievementKeyIn(eq("ai_hard"), any())
    }

    @Test
    fun `forfeit wins count for streaks but never for skunks`() {
        val history = listOf(
            GameHistoryEvent.GameForfeited(forfeitingPlayerId = them, reason = "RESIGNED"),
            GameHistoryEvent.GameEnded(winnerPlayerId = me, finalScore = 121)
        )
        val awarded = service.evaluateGameEnd(entity(), gameState(loserScore = 20, history = history))

        assertTrue(Achievement.FIRST_WIN in awarded)
        assertFalse(Achievement.SKUNK in awarded)
        assertFalse(Achievement.DOUBLE_SKUNK in awarded)

        val captor = argumentCaptor<AchievementProgressEntity>()
        verify(achievementProgressRepository, atLeastOnce()).save(captor.capture())
        assertEquals(1, captor.allValues.first { it.userId == me }.wins)
    }

    @Test
    fun `rating achievement requires a rated game`() {
        doReturn(PlayerStatsEntity(playerId = me, rating = 1650.0))
            .whenever(playerStatsService).getStats(me)

        val rated = service.evaluateGameEnd(entity(), gameState(loserScore = 95))
        assertTrue(Achievement.RATING_1600 in rated)

        clearInvocations(playerAchievementRepository)
        val aiGame = service.evaluateGameEnd(
            entity(isAIGame = true, aiDifficulty = "hard", opponentId = "ai_hard"),
            gameState(loserScore = 95, opponentId = "ai_hard")
        )
        assertFalse(Achievement.RATING_1600 in aiGame)
    }

    @Test
    fun `optimal puzzle solves count and cross the threshold`() {
        whenever(achievementProgressRepository.findById(me)).thenReturn(
            Optional.of(AchievementProgressEntity(userId = me, optimalPuzzleSolves = 9))
        )

        val awarded = service.evaluatePuzzleSolve(me, isOptimal = true)

        assertTrue(Achievement.PUZZLE_FIRST in awarded)
        assertTrue(Achievement.PUZZLE_OPTIMAL_10 in awarded)
    }

    @Test
    fun `non-optimal puzzle solve awards PUZZLE_FIRST without counting`() {
        val awarded = service.evaluatePuzzleSolve(me, isOptimal = false)

        assertTrue(Achievement.PUZZLE_FIRST in awarded)
        assertFalse(Achievement.PUZZLE_OPTIMAL_10 in awarded)
        verify(achievementProgressRepository, never()).save(any())
    }

    @Test
    fun `friend accepted awards both parties`() {
        service.evaluateFriendAccepted(me, them)

        verify(playerAchievementRepository).findByUserIdAndAchievementKeyIn(eq(me), any())
        verify(playerAchievementRepository).findByUserIdAndAchievementKeyIn(eq(them), any())
    }

    @Test
    fun `getAchievementsFor merges catalog, unlocks and progress`() {
        whenever(playerAchievementRepository.findByUserId(me)).thenReturn(
            listOf(PlayerAchievementEntity("row1", me, Achievement.FIRST_WIN.name, Instant.now()))
        )
        whenever(achievementProgressRepository.findById(me)).thenReturn(
            Optional.of(AchievementProgressEntity(userId = me, wins = 23, currentWinStreak = 2))
        )

        val statuses = service.getAchievementsFor(me)

        assertEquals(Achievement.entries.size, statuses.size)
        val firstWin = statuses.first { it.achievement == Achievement.FIRST_WIN }
        assertTrue(firstWin.unlocked)
        val wins50 = statuses.first { it.achievement == Achievement.WINS_50 }
        assertFalse(wins50.unlocked)
        assertEquals(23, wins50.progress)
        val skunk = statuses.first { it.achievement == Achievement.SKUNK }
        assertNull(skunk.progress)
    }

    @Test
    fun `users with no progress row show zero progress`() {
        val statuses = service.getAchievementsFor(me)
        assertEquals(0, statuses.first { it.achievement == Achievement.WINS_10 }.progress)
    }
}
