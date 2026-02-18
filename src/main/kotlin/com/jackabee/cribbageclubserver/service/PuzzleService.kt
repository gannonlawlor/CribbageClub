package com.jackabee.cribbageclubserver.service

import com.fasterxml.jackson.databind.ObjectMapper
import com.jackabee.cribbageclubserver.bridge.RustEngineAdapter
import com.jackabee.cribbageclubserver.entity.PuzzleEntity
import com.jackabee.cribbageclubserver.entity.PuzzleSolveEntity
import com.jackabee.cribbageclubserver.model.analysis.DiscardOption
import com.jackabee.cribbageclubserver.model.card.Card
import com.jackabee.cribbageclubserver.model.card.Rank
import com.jackabee.cribbageclubserver.model.card.Suit
import com.jackabee.cribbageclubserver.repository.PuzzleRepository
import com.jackabee.cribbageclubserver.repository.PuzzleSolveRepository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.time.LocalDate
import java.util.*

@Service
class PuzzleService(
    private val puzzleRepository: PuzzleRepository,
    private val puzzleSolveRepository: PuzzleSolveRepository,
    private val objectMapper: ObjectMapper,
    private val rustEngineAdapter: RustEngineAdapter
) {
    private val logger = LoggerFactory.getLogger(PuzzleService::class.java)

    fun getDailyPuzzle(userId: String): PuzzleResponse {
        val today = LocalDate.now()
        val puzzle = puzzleRepository.findByPuzzleDate(today) ?: generatePuzzle(today)
        val alreadySolved = puzzleSolveRepository.findByPuzzleIdAndUserId(puzzle.id, userId) != null
        val hand: List<Card> = objectMapper.readValue(
            puzzle.handJson,
            objectMapper.typeFactory.constructCollectionType(List::class.java, Card::class.java)
        )

        return PuzzleResponse(
            id = puzzle.id,
            hand = hand,
            isDealer = puzzle.isDealer,
            puzzleDate = puzzle.puzzleDate.toString(),
            alreadySolved = alreadySolved
        )
    }

    @Transactional
    fun solvePuzzle(puzzleId: String, userId: String, chosenDiscard: List<Card>): PuzzleSolveResponse {
        val puzzle = puzzleRepository.findById(puzzleId)
            .orElseThrow { IllegalArgumentException("Puzzle not found") }

        // Check if already solved
        val existing = puzzleSolveRepository.findByPuzzleIdAndUserId(puzzleId, userId)
        if (existing != null) {
            throw IllegalStateException("Puzzle already solved")
        }

        val hand: List<Card> = objectMapper.readValue(
            puzzle.handJson,
            objectMapper.typeFactory.constructCollectionType(List::class.java, Card::class.java)
        )

        require(chosenDiscard.size == 2) { "Must discard exactly 2 cards" }
        require(chosenDiscard.all { it in hand }) { "Discarded cards must be from the dealt hand" }

        val allOptions = rustEngineAdapter.analyzeDiscards(hand, puzzle.isDealer)
        val optimalOption = allOptions.first()
        val discardedSet = chosenDiscard.toSet()
        val playerOption = allOptions.find { it.discard.toSet() == discardedSet }
            ?: throw IllegalArgumentException("Invalid discard combination")

        val evDifference = optimalOption.expectedCombinedValue - playerOption.expectedCombinedValue
        val isOptimal = evDifference < 0.01

        val solve = PuzzleSolveEntity(
            id = UUID.randomUUID().toString(),
            puzzleId = puzzleId,
            userId = userId,
            chosenDiscardJson = objectMapper.writeValueAsString(chosenDiscard),
            isOptimal = isOptimal,
            evDiff = evDifference,
            solvedAt = Instant.now()
        )
        puzzleSolveRepository.save(solve)

        return PuzzleSolveResponse(
            isOptimal = isOptimal,
            evDifference = evDifference,
            yourOption = playerOption,
            optimalOption = optimalOption,
            allOptions = allOptions
        )
    }

    private fun generatePuzzle(date: LocalDate): PuzzleEntity {
        val random = Random(date.toEpochDay())
        val isDealer = random.nextBoolean()
        val allCards = Rank.entries.flatMap { rank -> Suit.entries.map { suit -> Card(rank, suit) } }

        repeat(100) {
            val shuffled = allCards.toMutableList().apply { shuffle(random) }
            val hand = shuffled.take(6)

            val options = rustEngineAdapter.analyzeDiscards(hand, isDealer)
            if (options.size < 2) return@repeat

            val evGap = options[0].expectedCombinedValue - options[1].expectedCombinedValue
            if (evGap in 0.5..3.0) {
                val puzzle = PuzzleEntity(
                    id = UUID.randomUUID().toString(),
                    handJson = objectMapper.writeValueAsString(hand),
                    isDealer = isDealer,
                    optimalDiscardJson = objectMapper.writeValueAsString(options[0].discard),
                    optimalEv = options[0].expectedCombinedValue,
                    createdAt = Instant.now(),
                    puzzleDate = date
                )
                puzzleRepository.save(puzzle)
                logger.info("Generated puzzle for {} (EV gap: {})", date, String.format("%.2f", evGap))
                return puzzle
            }
        }

        // Fallback: use any hand if no "interesting" one found
        val shuffled = allCards.toMutableList().apply { shuffle(random) }
        val hand = shuffled.take(6)
        val options = rustEngineAdapter.analyzeDiscards(hand, isDealer)

        val puzzle = PuzzleEntity(
            id = UUID.randomUUID().toString(),
            handJson = objectMapper.writeValueAsString(hand),
            isDealer = isDealer,
            optimalDiscardJson = objectMapper.writeValueAsString(options[0].discard),
            optimalEv = options[0].expectedCombinedValue,
            createdAt = Instant.now(),
            puzzleDate = date
        )
        puzzleRepository.save(puzzle)
        logger.info("Generated fallback puzzle for {}", date)
        return puzzle
    }
}

data class PuzzleResponse(
    val id: String,
    val hand: List<Card>,
    val isDealer: Boolean,
    val puzzleDate: String,
    val alreadySolved: Boolean
)

data class PuzzleSolveResponse(
    val isOptimal: Boolean,
    val evDifference: Double,
    val yourOption: DiscardOption,
    val optimalOption: DiscardOption,
    val allOptions: List<DiscardOption>
)
