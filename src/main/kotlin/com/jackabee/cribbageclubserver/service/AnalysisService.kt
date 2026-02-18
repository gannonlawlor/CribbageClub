package com.jackabee.cribbageclubserver.service

import com.fasterxml.jackson.databind.ObjectMapper
import com.jackabee.cribbageclubserver.bridge.RustEngineAdapter
import com.jackabee.cribbageclubserver.entity.GameAnalysisEntity
import com.jackabee.cribbageclubserver.model.analysis.GameAnalysis
import com.jackabee.cribbageclubserver.model.analysis.PlayerRoundAnalysis
import com.jackabee.cribbageclubserver.model.analysis.RoundAnalysis
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.game.GameHistoryEvent
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.repository.GameAnalysisRepository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service

@Service
class AnalysisService(
    private val gameService: GameService,
    private val rustEngineAdapter: RustEngineAdapter,
    private val gameAnalysisRepository: GameAnalysisRepository,
    private val objectMapper: ObjectMapper
) {
    private val log = LoggerFactory.getLogger(AnalysisService::class.java)

    fun analyzeGame(gameId: String): GameAnalysis {
        // Check DB cache first
        val cached = gameAnalysisRepository.findById(gameId)
        if (cached.isPresent) {
            return objectMapper.readValue(cached.get().analysisJson, GameAnalysis::class.java)
        }

        // Compute analysis
        val state = gameService.getGameState(gameId)
        require(state.stage == GameStage.GAME_OVER) { "Game must be completed for analysis" }

        val rounds = parseRounds(state.history)
        val analysis = GameAnalysis(gameId, rounds)

        // Cache in DB
        try {
            val entity = GameAnalysisEntity(
                gameId = gameId,
                analysisJson = objectMapper.writeValueAsString(analysis)
            )
            gameAnalysisRepository.save(entity)
        } catch (e: Exception) {
            log.warn("Failed to cache analysis for game {}: {}", gameId, e.message)
        }

        return analysis
    }

    fun saveAnalysis(gameId: String, analysis: GameAnalysis) {
        if (gameAnalysisRepository.existsById(gameId)) return

        val entity = GameAnalysisEntity(
            gameId = gameId,
            analysisJson = objectMapper.writeValueAsString(analysis)
        )
        gameAnalysisRepository.save(entity)
    }

    internal fun parseRounds(history: List<GameHistoryEvent>): List<RoundAnalysis> {
        val roundChunks = splitIntoRounds(history)
        return roundChunks.mapNotNull { events -> analyzeRound(events) }
    }

    private fun splitIntoRounds(history: List<GameHistoryEvent>): List<List<GameHistoryEvent>> {
        val rounds = mutableListOf<MutableList<GameHistoryEvent>>()
        var current: MutableList<GameHistoryEvent>? = null

        for (event in history) {
            if (event is GameHistoryEvent.RoundStarted) {
                current = mutableListOf(event)
                rounds.add(current)
            } else {
                current?.add(event)
            }
        }

        return rounds
    }

    private fun analyzeRound(events: List<GameHistoryEvent>): RoundAnalysis? {
        val roundStarted = events.filterIsInstance<GameHistoryEvent.RoundStarted>().firstOrNull()
            ?: return null
        val cardsDealt = events.filterIsInstance<GameHistoryEvent.CardsDealt>().firstOrNull()
            ?: return null
        val deckCut = events.filterIsInstance<GameHistoryEvent.DeckCut>().firstOrNull()
        val handsCounted = events.filterIsInstance<GameHistoryEvent.HandCounted>()
        val cribCounted = events.filterIsInstance<GameHistoryEvent.CribCounted>().firstOrNull()

        // Skip rounds where dealt hands weren't recorded (pre-enrichment games)
        if (cardsDealt.dealtHands.isEmpty()) return null

        // The cutting player is the non-dealer, so the dealer is the other player
        val playerIds = cardsDealt.dealtHands.keys.toList()
        val dealerPlayerId = if (deckCut != null) {
            playerIds.first { it != deckCut.cuttingPlayerId }
        } else {
            playerIds.first()
        }

        val playerAnalyses = playerIds.mapNotNull { playerId ->
            analyzePlayerRound(
                playerId = playerId,
                isDealer = playerId == dealerPlayerId,
                dealtHands = cardsDealt.dealtHands,
                handsCounted = handsCounted,
                cribCounted = cribCounted
            )
        }

        return RoundAnalysis(
            roundNumber = roundStarted.roundNumber,
            cutCard = deckCut?.cutCard,
            dealerPlayerId = dealerPlayerId,
            playerAnalyses = playerAnalyses
        )
    }

    private fun analyzePlayerRound(
        playerId: String,
        isDealer: Boolean,
        dealtHands: Map<String, List<Card>>,
        handsCounted: List<GameHistoryEvent.HandCounted>,
        cribCounted: GameHistoryEvent.CribCounted?
    ): PlayerRoundAnalysis? {
        val dealtHand = dealtHands[playerId] ?: return null
        if (dealtHand.size != 6) return null

        val handCounted = handsCounted.find { it.playerId == playerId }
        val keptHand = handCounted?.hand ?: return null
        if (keptHand.size != 4) return null

        val discarded = dealtHand.filter { it !in keptHand }
        if (discarded.size != 2) return null

        val allOptions = rustEngineAdapter.analyzeDiscards(dealtHand, isDealer)
        val optimalOption = allOptions.first()
        val playerOption = allOptions.find { it.discard.toSet() == discarded.toSet() }
            ?: return null

        val actualHandScore = handCounted.totalPoints
        val actualCribScore = if (isDealer) cribCounted?.totalPoints else null

        return PlayerRoundAnalysis(
            playerId = playerId,
            isDealer = isDealer,
            dealtHand = dealtHand,
            keptHand = keptHand,
            discarded = discarded,
            actualHandScore = actualHandScore,
            actualCribScore = actualCribScore,
            optimalDiscard = optimalOption,
            playerDiscard = playerOption,
            evDifference = optimalOption.expectedCombinedValue - playerOption.expectedCombinedValue
        )
    }
}
