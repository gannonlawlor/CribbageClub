package com.jackabee.cribbageclubserver.utils

import kotlin.math.*

/**
 * Implementation of the Glicko-2 rating system based on Mark Glickman's paper.
 * Each game is treated as its own rating period.
 */
object Glicko2Calculator {

    data class Rating(
        val rating: Double = 1500.0,
        val deviation: Double = 350.0,
        val volatility: Double = 0.06
    )

    data class Result(
        val newRating: Double,
        val newDeviation: Double,
        val newVolatility: Double
    )

    private const val TAU = 0.5 // system constant constraining volatility change
    private const val CONVERGENCE_TOLERANCE = 0.000001
    private const val GLICKO2_SCALE = 173.7178 // conversion factor between Glicko and Glicko-2

    /**
     * Calculate new rating after a single game.
     *
     * @param player Current player rating
     * @param opponent Opponent rating
     * @param score Game outcome: 1.0 = win, 0.0 = loss, 0.5 = draw
     * @return New rating values for the player
     */
    fun calculateNewRating(
        player: Rating,
        opponent: Rating,
        score: Double
    ): Result {
        // Step 1: Convert to Glicko-2 scale
        val mu = (player.rating - 1500.0) / GLICKO2_SCALE
        val phi = player.deviation / GLICKO2_SCALE
        val sigma = player.volatility

        val muJ = (opponent.rating - 1500.0) / GLICKO2_SCALE
        val phiJ = opponent.deviation / GLICKO2_SCALE

        // Step 2: Compute variance (v)
        val gPhiJ = g(phiJ)
        val eVal = e(mu, muJ, gPhiJ)
        val v = 1.0 / (gPhiJ * gPhiJ * eVal * (1.0 - eVal))

        // Step 3: Compute estimated improvement (delta)
        val delta = v * gPhiJ * (score - eVal)

        // Step 4: Compute new volatility (sigma')
        val newSigma = computeNewVolatility(sigma, phi, v, delta)

        // Step 5: Update rating deviation to new pre-rating period value
        val phiStar = sqrt(phi * phi + newSigma * newSigma)

        // Step 6: Update rating and RD
        val newPhi = 1.0 / sqrt(1.0 / (phiStar * phiStar) + 1.0 / v)
        val newMu = mu + newPhi * newPhi * gPhiJ * (score - eVal)

        // Step 7: Convert back to Glicko scale
        return Result(
            newRating = newMu * GLICKO2_SCALE + 1500.0,
            newDeviation = newPhi * GLICKO2_SCALE,
            newVolatility = newSigma
        )
    }

    /** g(phi) function from Glicko-2 */
    private fun g(phi: Double): Double {
        return 1.0 / sqrt(1.0 + 3.0 * phi * phi / (PI * PI))
    }

    /** E(mu, mu_j, phi_j) function - expected score */
    private fun e(mu: Double, muJ: Double, gPhiJ: Double): Double {
        return 1.0 / (1.0 + exp(-gPhiJ * (mu - muJ)))
    }

    /** Compute new volatility using the Illinois algorithm */
    private fun computeNewVolatility(
        sigma: Double,
        phi: Double,
        v: Double,
        delta: Double
    ): Double {
        val a = ln(sigma * sigma)
        val deltaSq = delta * delta
        val phiSq = phi * phi

        fun f(x: Double): Double {
            val ex = exp(x)
            val num1 = ex * (deltaSq - phiSq - v - ex)
            val den1 = 2.0 * (phiSq + v + ex).pow(2.0)
            return num1 / den1 - (x - a) / (TAU * TAU)
        }

        // Set initial bounds
        var bigA = a
        var bigB: Double

        if (deltaSq > phiSq + v) {
            bigB = ln(deltaSq - phiSq - v)
        } else {
            var k = 1
            while (f(a - k * TAU) < 0) {
                k++
            }
            bigB = a - k * TAU
        }

        // Illinois algorithm
        var fA = f(bigA)
        var fB = f(bigB)

        while (abs(bigB - bigA) > CONVERGENCE_TOLERANCE) {
            val bigC = bigA + (bigA - bigB) * fA / (fB - fA)
            val fC = f(bigC)

            if (fC * fB <= 0) {
                bigA = bigB
                fA = fB
            } else {
                fA /= 2.0
            }

            bigB = bigC
            fB = fC
        }

        return exp(bigA / 2.0)
    }
}
