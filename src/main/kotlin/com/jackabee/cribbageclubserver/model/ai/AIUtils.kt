package com.jackabee.cribbageclubserver.model.ai

import com.jackabee.cribbageclubserver.model.card.Card

object AIUtils {

    fun <T> List<T>.combinations(size: Int): List<List<T>> {
        if (size == 0) return listOf(emptyList())
        if (isEmpty()) return emptyList()
        val head = first()
        val tail = drop(1)
        return tail.combinations(size - 1).map { listOf(head) + it } + tail.combinations(size)
    }

    fun findRunContinuation(playableCards: List<Card>, playedCards: List<Card>): Card? {
        val recentCards = playedCards.takeLast(3)
        if (recentCards.size < 2) return null

        val recentRanks = recentCards.map { it.rank.ordinal }.sorted()
        val isConsecutive = recentRanks.zipWithNext().all { (a, b) -> b - a == 1 }

        if (isConsecutive) {
            val minRank = recentRanks.min()
            val maxRank = recentRanks.max()
            return playableCards.find { card ->
                val rank = card.rank.ordinal
                rank == minRank - 1 || rank == maxRank + 1
            }
        }
        return null
    }
}
