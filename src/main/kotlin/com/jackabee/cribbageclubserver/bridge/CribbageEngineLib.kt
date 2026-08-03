package com.jackabee.cribbageclubserver.bridge

import com.sun.jna.Library
import com.sun.jna.Native
import com.sun.jna.Pointer

/**
 * JNA interface mapping the C API exported by the cribbage-engine Rust crate.
 *
 * All `String` return types are heap-allocated C strings that MUST be freed
 * with [cribbage_string_free]. Engine pointers MUST be freed with
 * [cribbage_engine_free].
 *
 * On error, functions return null (for pointers/strings) or -1 (for int).
 * Call [cribbage_last_error] to retrieve the error message.
 */
interface CribbageEngineLib : Library {

    // ── Memory management ───────────────────────────────────────────
    fun cribbage_string_free(ptr: Pointer?)
    fun cribbage_engine_free(ptr: Pointer?)
    fun cribbage_last_error(): Pointer?

    // ── Engine lifecycle ────────────────────────────────────────────
    fun cribbage_engine_new(
        gameId: String,
        p1Id: String, p1Name: String,
        p2Id: String, p2Name: String,
    ): Pointer?

    fun cribbage_engine_new_seeded(
        gameId: String,
        p1Id: String, p1Name: String,
        p2Id: String, p2Name: String,
        seed: Long,
    ): Pointer?

    fun cribbage_engine_restore(stateJson: String): Pointer?
    fun cribbage_engine_state_json(engine: Pointer): Pointer?
    fun cribbage_engine_apply_action(engine: Pointer, actionJson: String): Pointer?

    fun cribbage_engine_process_ai(
        engine: Pointer,
        aiPlayerId: String,
        difficulty: String,
        maxIterations: Int,
    ): Pointer?

    // ── Dev helpers ─────────────────────────────────────────────────
    fun cribbage_engine_dev_set_score(engine: Pointer, playerId: String, score: Int): Int
    fun cribbage_engine_dev_set_next_hands(engine: Pointer, handsJson: String): Int

    // ── Standalone scoring / analysis ───────────────────────────────
    fun cribbage_analyze_discards(handJson: String, isDealer: Boolean): Pointer?
    fun cribbage_glicko2_calculate(
        playerRating: Double, playerDeviation: Double, playerVolatility: Double,
        opponentRating: Double, opponentDeviation: Double, opponentVolatility: Double,
        score: Double,
    ): Pointer?

    companion object {
        /**
         * Load the native library. JNA resolves the library name to
         * `libcribbage_engine.dylib` / `.so` / `.dll` depending on platform.
         * The `jna.library.path` system property must include the directory
         * containing the built library (set by Gradle for tests, and by
         * application config for production).
         */
        fun load(): CribbageEngineLib =
            Native.load("cribbage_engine", CribbageEngineLib::class.java)
    }
}
