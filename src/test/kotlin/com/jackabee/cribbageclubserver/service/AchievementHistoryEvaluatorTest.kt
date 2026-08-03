package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.model.achievement.Achievement
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit
import com.jackabee.cribbageclubserver.model.game.GameHistoryEvent
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.player.Player
import org.junit.jupiter.api.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class AchievementHistoryEvaluatorTest {

    private val evaluator = AchievementHistoryEvaluator()

    private val me = "user1"
    private val them = "user2"
    private val card = Card(Rank.FIVE, Suit.HEARTS)
    private val breakdown = GameHistoryEvent.ScoreBreakdown()

    private fun state(history: List<GameHistoryEvent>) = GameState(
        gameId = "g1",
        players = listOf(Player(me, "Me"), Player(them, "Them")),
        stage = GameStage.GAME_OVER,
        history = history
    )

    private fun handCounted(playerId: String, points: Int) =
        GameHistoryEvent.HandCounted(playerId = playerId, totalPoints = points, scoreBreakdown = breakdown)

    @Test
    fun `hand thresholds award at 20, 24 and 29`() {
        val at29 = evaluator.evaluate(me, state(listOf(handCounted(me, 29))))
        assertTrue(Achievement.HAND_20 in at29)
        assertTrue(Achievement.HAND_24 in at29)
        assertTrue(Achievement.HAND_29 in at29)

        val at20 = evaluator.evaluate(me, state(listOf(handCounted(me, 20))))
        assertTrue(Achievement.HAND_20 in at20)
        assertFalse(Achievement.HAND_24 in at20)

        val at19 = evaluator.evaluate(me, state(listOf(handCounted(me, 19))))
        assertFalse(Achievement.HAND_20 in at19)
    }

    @Test
    fun `opponent hands never award to me`() {
        val awarded = evaluator.evaluate(me, state(listOf(handCounted(them, 29))))
        assertTrue(awarded.isEmpty())
    }

    @Test
    fun `crib of 12 awards only the dealer`() {
        val history = listOf(
            GameHistoryEvent.CribCounted(dealerPlayerId = me, totalPoints = 12, scoreBreakdown = breakdown)
        )
        assertTrue(Achievement.CRIB_12 in evaluator.evaluate(me, state(history)))
        assertFalse(Achievement.CRIB_12 in evaluator.evaluate(them, state(history)))

        val small = listOf(
            GameHistoryEvent.CribCounted(dealerPlayerId = me, totalPoints = 11, scoreBreakdown = breakdown)
        )
        assertFalse(Achievement.CRIB_12 in evaluator.evaluate(me, state(small)))
    }

    @Test
    fun `his heels goes to the dealer, who did not cut`() {
        val history = listOf(
            GameHistoryEvent.DeckCut(cutCard = card, cuttingPlayerId = them, dealerScoredNobs = true)
        )
        assertTrue(Achievement.HIS_HEELS in evaluator.evaluate(me, state(history)))
        assertFalse(Achievement.HIS_HEELS in evaluator.evaluate(them, state(history)))

        val noNobs = listOf(
            GameHistoryEvent.DeckCut(cutCard = card, cuttingPlayerId = them, dealerScoredNobs = false)
        )
        assertFalse(Achievement.HIS_HEELS in evaluator.evaluate(me, state(noNobs)))
    }

    @Test
    fun `reaching exactly 31 awards PEG_31`() {
        val history = listOf(
            GameHistoryEvent.CardPlayed(playerId = me, card = card, newCount = 31, pointsScored = 2)
        )
        assertTrue(Achievement.PEG_31 in evaluator.evaluate(me, state(history)))
        assertFalse(Achievement.PEG_31 in evaluator.evaluate(them, state(history)))
    }

    @Test
    fun `pegging 12 in one round awards, 11 does not`() {
        fun play(points: Int) =
            GameHistoryEvent.CardPlayed(playerId = me, card = card, newCount = 15, pointsScored = points)

        val twelve = listOf(
            GameHistoryEvent.RoundStarted(roundNumber = 1),
            play(6), play(4),
            GameHistoryEvent.GoAnnounced(playerId = me, pointsScored = 2)
        )
        assertTrue(Achievement.PEG_12_ROUND in evaluator.evaluate(me, state(twelve)))

        val eleven = listOf(
            GameHistoryEvent.RoundStarted(roundNumber = 1),
            play(6), play(4),
            GameHistoryEvent.GoAnnounced(playerId = me, pointsScored = 1)
        )
        assertFalse(Achievement.PEG_12_ROUND in evaluator.evaluate(me, state(eleven)))
    }

    @Test
    fun `pegging points do not accumulate across rounds`() {
        fun play(points: Int) =
            GameHistoryEvent.CardPlayed(playerId = me, card = card, newCount = 15, pointsScored = points)

        val split = listOf(
            GameHistoryEvent.RoundStarted(roundNumber = 1),
            play(6), play(5),
            GameHistoryEvent.RoundStarted(roundNumber = 2),
            play(6), play(5)
        )
        assertFalse(Achievement.PEG_12_ROUND in evaluator.evaluate(me, state(split)))
    }

    @Test
    fun `comeback awards at a 30 deficit but not 29`() {
        fun trailingBy(deficit: Int) = listOf(
            handCounted(them, deficit),
            handCounted(me, 60),
            GameHistoryEvent.GameEnded(winnerPlayerId = me, finalScore = 121)
        )
        assertTrue(evaluator.wonFromBehind(me, state(trailingBy(30))))
        assertFalse(evaluator.wonFromBehind(me, state(trailingBy(29))))
    }

    @Test
    fun `comeback counts nobs points for the dealer during the replay`() {
        // Opponent leads by 29 through hands; their nobs as dealer makes it 31.
        val history = listOf(
            handCounted(them, 29),
            GameHistoryEvent.DeckCut(cutCard = card, cuttingPlayerId = me, dealerScoredNobs = true),
            handCounted(me, 80)
        )
        assertTrue(evaluator.wonFromBehind(me, state(history)))
    }

    @Test
    fun `forfeited games never count as comebacks`() {
        val history = listOf(
            handCounted(them, 50),
            GameHistoryEvent.GameForfeited(forfeitingPlayerId = them, reason = "RESIGNED"),
            GameHistoryEvent.GameEnded(winnerPlayerId = me, finalScore = 121)
        )
        assertFalse(evaluator.wonFromBehind(me, state(history)))
    }
}
