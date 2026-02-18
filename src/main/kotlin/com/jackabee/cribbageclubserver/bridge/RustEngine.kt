package com.jackabee.cribbageclubserver.bridge

import com.sun.jna.Pointer

/**
 * Thin AutoCloseable wrapper around a native cribbage-engine handle.
 *
 * Manages the lifecycle of the opaque `*mut GameEngine` pointer returned
 * by the Rust C API. All JSON string results are copied and freed before
 * returning to the caller.
 */
class RustEngine private constructor(
    private val lib: CribbageEngineLib,
    private var ptr: Pointer?,
) : AutoCloseable {

    /** Read a C string returned by the library, free the native memory, and return a Kotlin String. */
    private fun readAndFree(resultPtr: Pointer?): String? {
        if (resultPtr == null) return null
        return try {
            resultPtr.getString(0)
        } finally {
            lib.cribbage_string_free(resultPtr)
        }
    }

    /** Get the last error message from the native library (if any). */
    private fun lastError(): String? = readAndFree(lib.cribbage_last_error())

    /** Throw if the native library set an error. */
    private fun checkError() {
        lastError()?.let { throw RustEngineException(it) }
    }

    /** Require a non-null pointer result, otherwise throw with the native error. */
    private fun requirePtr(ptr: Pointer?): Pointer =
        ptr ?: throw RustEngineException(lastError() ?: "Unknown native error")

    /** Require a non-null string result, otherwise throw with the native error. */
    private fun requireJson(resultPtr: Pointer?): String =
        readAndFree(resultPtr) ?: throw RustEngineException(lastError() ?: "Unknown native error")

    private fun ensureOpen(): Pointer =
        ptr ?: throw IllegalStateException("RustEngine has been closed")

    // ── Public API ──────────────────────────────────────────────────

    /** Get the current game state as a JSON string. */
    fun stateJson(): String = requireJson(lib.cribbage_engine_state_json(ensureOpen()))

    /** Apply a game action (JSON) and return the new state as JSON. */
    fun applyAction(actionJson: String): String =
        requireJson(lib.cribbage_engine_apply_action(ensureOpen(), actionJson))

    /** Process AI actions and return the resulting state as JSON. */
    fun processAI(aiPlayerId: String, difficulty: String, maxIterations: Int = 10): String =
        requireJson(lib.cribbage_engine_process_ai(ensureOpen(), aiPlayerId, difficulty, maxIterations))

    /** DEV ONLY: Set a player's score. */
    fun devSetScore(playerId: String, score: Int) {
        val result = lib.cribbage_engine_dev_set_score(ensureOpen(), playerId, score)
        if (result != 0) throw RustEngineException(lastError() ?: "Failed to set score")
    }

    /** DEV ONLY: Set next hands from a JSON map of playerId -> cards. */
    fun devSetNextHands(handsJson: String) {
        val result = lib.cribbage_engine_dev_set_next_hands(ensureOpen(), handsJson)
        if (result != 0) throw RustEngineException(lastError() ?: "Failed to set next hands")
    }

    override fun close() {
        ptr?.let { lib.cribbage_engine_free(it) }
        ptr = null
    }

    companion object {
        /** Create a new game engine. */
        fun create(
            lib: CribbageEngineLib,
            gameId: String,
            p1Id: String, p1Name: String,
            p2Id: String, p2Name: String,
        ): RustEngine {
            val ptr = lib.cribbage_engine_new(gameId, p1Id, p1Name, p2Id, p2Name)
                ?: throw RustEngineException(
                    readLastError(lib) ?: "Failed to create engine"
                )
            return RustEngine(lib, ptr)
        }

        /** Create a new game engine with a seeded deck (for testing). */
        fun createSeeded(
            lib: CribbageEngineLib,
            gameId: String,
            p1Id: String, p1Name: String,
            p2Id: String, p2Name: String,
            seed: Long,
        ): RustEngine {
            val ptr = lib.cribbage_engine_new_seeded(gameId, p1Id, p1Name, p2Id, p2Name, seed)
                ?: throw RustEngineException(
                    readLastError(lib) ?: "Failed to create seeded engine"
                )
            return RustEngine(lib, ptr)
        }

        /** Restore an engine from a GameState JSON string. */
        fun restore(lib: CribbageEngineLib, stateJson: String): RustEngine {
            val ptr = lib.cribbage_engine_restore(stateJson)
                ?: throw RustEngineException(
                    readLastError(lib) ?: "Failed to restore engine"
                )
            return RustEngine(lib, ptr)
        }

        private fun readLastError(lib: CribbageEngineLib): String? {
            val errPtr = lib.cribbage_last_error() ?: return null
            return try {
                errPtr.getString(0)
            } finally {
                lib.cribbage_string_free(errPtr)
            }
        }
    }
}

class RustEngineException(message: String) : RuntimeException(message)
