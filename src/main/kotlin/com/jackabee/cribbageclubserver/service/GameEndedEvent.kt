package com.jackabee.cribbageclubserver.service

/**
 * Published when a game is ended outside the normal action flow — a timeout
 * forfeit or a resignation. [GameService] caches live engine handles in memory
 * and prefers them over the database, so it must drop the handle or REST callers
 * keep being served a game that is actually over.
 */
data class GameEndedEvent(val gameId: String)
