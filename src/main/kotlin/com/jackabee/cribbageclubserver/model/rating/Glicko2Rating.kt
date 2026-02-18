package com.jackabee.cribbageclubserver.model.rating

/**
 * Glicko-2 rating DTOs used by PlayerStatsService and RustEngineAdapter.
 */
data class Glicko2Rating(
    val rating: Double = 1500.0,
    val deviation: Double = 350.0,
    val volatility: Double = 0.06
)

data class Glicko2Result(
    val newRating: Double,
    val newDeviation: Double,
    val newVolatility: Double
)
