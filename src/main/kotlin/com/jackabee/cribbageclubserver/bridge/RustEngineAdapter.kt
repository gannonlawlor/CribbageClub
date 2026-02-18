package com.jackabee.cribbageclubserver.bridge

import com.fasterxml.jackson.databind.ObjectMapper
import com.jackabee.cribbageclubserver.model.action.GameAction
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.utils.DiscardAnalyzer
import com.jackabee.cribbageclubserver.utils.Glicko2Calculator

/**
 * Adapter between the Rust native engine (via JNA) and the existing
 * Jackson-annotated Kotlin domain types.
 *
 * All engine state is held in the native Rust library; this adapter
 * simply converts JSON strings to/from the Kotlin types that the rest
 * of the Spring Boot application already uses (controllers, WebSocket,
 * persistence).
 */
class RustEngineAdapter(
    private val lib: CribbageEngineLib,
    private val objectMapper: ObjectMapper,
) {
    // ── Engine lifecycle ────────────────────────────────────────────

    /** Create a new game engine and return its initial state. */
    fun createEngine(
        gameId: String,
        p1Id: String, p1Name: String,
        p2Id: String, p2Name: String,
    ): Pair<RustEngine, GameState> {
        val engine = RustEngine.create(lib, gameId, p1Id, p1Name, p2Id, p2Name)
        val state = parseState(engine.stateJson())
        return engine to state
    }

    /** Create a seeded engine (for testing). */
    fun createSeededEngine(
        gameId: String,
        p1Id: String, p1Name: String,
        p2Id: String, p2Name: String,
        seed: Long,
    ): Pair<RustEngine, GameState> {
        val engine = RustEngine.createSeeded(lib, gameId, p1Id, p1Name, p2Id, p2Name, seed)
        val state = parseState(engine.stateJson())
        return engine to state
    }

    /** Restore an engine from a persisted GameState. */
    fun restoreEngine(state: GameState): RustEngine {
        val json = objectMapper.writeValueAsString(state)
        return RustEngine.restore(lib, json)
    }

    // ── Game actions ────────────────────────────────────────────────

    /** Apply a game action and return the updated state. */
    fun applyAction(engine: RustEngine, action: GameAction): GameState {
        val actionJson = objectMapper.writeValueAsString(action)
        val resultJson = engine.applyAction(actionJson)
        return parseState(resultJson)
    }

    /** Get the current game state. */
    fun getState(engine: RustEngine): GameState = parseState(engine.stateJson())

    /** Process AI actions and return the resulting state. */
    fun processAI(
        engine: RustEngine,
        aiPlayerId: String,
        difficulty: String,
        maxIterations: Int = 10,
    ): GameState {
        val resultJson = engine.processAI(aiPlayerId, difficulty, maxIterations)
        return parseState(resultJson)
    }

    // ── Standalone analysis ─────────────────────────────────────────

    /** Calculate hand score using the Rust engine. */
    fun calculateHandScore(hand: List<Card>, cutCard: Card, isCrib: Boolean): Int {
        val handJson = objectMapper.writeValueAsString(hand)
        val cutJson = objectMapper.writeValueAsString(cutCard)
        val result = lib.cribbage_calculate_hand_score(handJson, cutJson, isCrib)
        if (result < 0) {
            val errPtr = lib.cribbage_last_error()
            val msg = if (errPtr != null) {
                try { errPtr.getString(0) } finally { lib.cribbage_string_free(errPtr) }
            } else "Unknown scoring error"
            throw RustEngineException(msg)
        }
        return result
    }

    /** Analyze all discard options using the Rust engine. */
    fun analyzeDiscards(hand: List<Card>, isDealer: Boolean): List<DiscardAnalyzer.DiscardOption> {
        val handJson = objectMapper.writeValueAsString(hand)
        val resultPtr = lib.cribbage_analyze_discards(handJson, isDealer)
            ?: throw RustEngineException(readLastError() ?: "Unknown analysis error")

        val json = try { resultPtr.getString(0) } finally { lib.cribbage_string_free(resultPtr) }

        val tree = objectMapper.readTree(json)
        return tree.map { node ->
            DiscardAnalyzer.DiscardOption(
                keep = objectMapper.convertValue(
                    node["keep"],
                    objectMapper.typeFactory.constructCollectionType(List::class.java, Card::class.java)
                ),
                discard = objectMapper.convertValue(
                    node["discard"],
                    objectMapper.typeFactory.constructCollectionType(List::class.java, Card::class.java)
                ),
                expectedHandValue = node["expectedHandValue"].asDouble(),
                expectedCribValue = node["expectedCribValue"].asDouble(),
                expectedCombinedValue = node["expectedCombinedValue"].asDouble(),
            )
        }
    }

    /** Calculate Glicko-2 rating using the Rust engine. */
    fun calculateGlicko2(
        player: Glicko2Calculator.Rating,
        opponent: Glicko2Calculator.Rating,
        score: Double,
    ): Glicko2Calculator.Result {
        val resultPtr = lib.cribbage_glicko2_calculate(
            player.rating, player.deviation, player.volatility,
            opponent.rating, opponent.deviation, opponent.volatility,
            score,
        ) ?: throw RustEngineException(readLastError() ?: "Unknown Glicko-2 error")

        val json = try { resultPtr.getString(0) } finally { lib.cribbage_string_free(resultPtr) }
        val node = objectMapper.readTree(json)

        return Glicko2Calculator.Result(
            newRating = node["newRating"].asDouble(),
            newDeviation = node["newDeviation"].asDouble(),
            newVolatility = node["newVolatility"].asDouble(),
        )
    }

    // ── Internal ────────────────────────────────────────────────────

    private fun parseState(json: String): GameState =
        objectMapper.readValue(json, GameState::class.java)

    private fun readLastError(): String? {
        val ptr = lib.cribbage_last_error() ?: return null
        return try { ptr.getString(0) } finally { lib.cribbage_string_free(ptr) }
    }
}
