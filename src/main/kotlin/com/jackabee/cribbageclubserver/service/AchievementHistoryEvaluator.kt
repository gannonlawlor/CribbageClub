package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.model.achievement.Achievement
import com.jackabee.cribbageclubserver.model.game.GameHistoryEvent
import com.jackabee.cribbageclubserver.model.game.GameState
import org.springframework.stereotype.Service

/**
 * Pure inspection of a finished game's history for feat achievements —
 * everything here is answerable from [GameState.history] alone, with no
 * repository access, so it works identically for live games and imports.
 */
@Service
class AchievementHistoryEvaluator {

    /** Feats that don't care who won: big hands, big cribs, pegging feats. */
    fun evaluate(userId: String, state: GameState): Set<Achievement> {
        val awarded = mutableSetOf<Achievement>()

        // Per-round pegging accumulator for PEG_12_ROUND.
        var roundPegPoints = 0

        for (event in state.history) {
            when (event) {
                is GameHistoryEvent.RoundStarted -> roundPegPoints = 0

                is GameHistoryEvent.HandCounted -> if (event.playerId == userId) {
                    if (event.totalPoints >= 20) awarded += Achievement.HAND_20
                    if (event.totalPoints >= 24) awarded += Achievement.HAND_24
                    if (event.totalPoints >= 29) awarded += Achievement.HAND_29
                }

                is GameHistoryEvent.CribCounted ->
                    if (event.dealerPlayerId == userId && event.totalPoints >= 12) {
                        awarded += Achievement.CRIB_12
                    }

                // The non-dealer cuts, so a nobs jack scores for the player
                // who didn't cut.
                is GameHistoryEvent.DeckCut ->
                    if (event.dealerScoredNobs && event.cuttingPlayerId != userId) {
                        awarded += Achievement.HIS_HEELS
                    }

                is GameHistoryEvent.CardPlayed -> {
                    if (event.playerId == userId) {
                        if (event.newCount == 31) awarded += Achievement.PEG_31
                        roundPegPoints += event.pointsScored
                        if (roundPegPoints >= 12) awarded += Achievement.PEG_12_ROUND
                    }
                }

                is GameHistoryEvent.GoAnnounced -> {
                    if (event.playerId == userId) {
                        roundPegPoints += event.pointsScored
                        if (roundPegPoints >= 12) awarded += Achievement.PEG_12_ROUND
                    }
                }

                else -> {}
            }
        }

        return awarded
    }

    /**
     * COMEBACK: the winner trailed by 30 or more at some point. Replays the
     * running scores from history. Never awarded for forfeited games — a
     * forfeit jumps the winner to 121 and would make deficits meaningless.
     */
    fun wonFromBehind(userId: String, state: GameState, deficit: Int = 30): Boolean {
        if (state.history.any { it is GameHistoryEvent.GameForfeited }) return false

        val scores = mutableMapOf<String, Int>()
        fun addPoints(playerId: String, points: Int) {
            scores[playerId] = (scores[playerId] ?: 0) + points
        }

        var maxDeficit = 0
        fun observeDeficit() {
            val mine = scores[userId] ?: 0
            val theirs = scores.filterKeys { it != userId }.values.maxOrNull() ?: 0
            if (theirs - mine > maxDeficit) maxDeficit = theirs - mine
        }

        for (event in state.history) {
            when (event) {
                is GameHistoryEvent.CardPlayed -> addPoints(event.playerId, event.pointsScored)
                is GameHistoryEvent.GoAnnounced -> addPoints(event.playerId, event.pointsScored)
                is GameHistoryEvent.HandCounted -> addPoints(event.playerId, event.totalPoints)
                is GameHistoryEvent.CribCounted -> addPoints(event.dealerPlayerId, event.totalPoints)
                is GameHistoryEvent.DeckCut -> if (event.dealerScoredNobs) {
                    // Two for his heels goes to the dealer — the non-cutter.
                    val dealer = state.players.map { it.id }.firstOrNull { it != event.cuttingPlayerId }
                    if (dealer != null) addPoints(dealer, 2)
                }
                else -> {}
            }
            observeDeficit()
        }

        return maxDeficit >= deficit
    }
}
