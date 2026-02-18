package com.jackabee.cribbageclubserver.service

import com.jackabee.cribbageclubserver.entity.GameEntity
import com.jackabee.cribbageclubserver.model.action.ForfeitReason
import com.jackabee.cribbageclubserver.model.game.GameHistoryEvent
import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.player.Player
import com.jackabee.cribbageclubserver.repository.GameRepository
import com.jackabee.cribbageclubserver.websocket.GameWebSocketService
import com.fasterxml.jackson.databind.ObjectMapper
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant

@Service
class ForfeitService(
    private val gameRepository: GameRepository,
    private val objectMapper: ObjectMapper,
    private val playerStatsService: PlayerStatsService,
    private val webSocketService: GameWebSocketService,
    private val turnTimerService: TurnTimerService
) {
    private val logger = LoggerFactory.getLogger(ForfeitService::class.java)

    @Transactional
    fun forfeitGame(gameId: String, forfeitingPlayerId: String, reason: ForfeitReason): GameState {
        val entity = gameRepository.findById(gameId).orElseThrow {
            IllegalArgumentException("Game not found: $gameId")
        }

        require(entity.winnerId == null) { "Game is already over" }
        require(
            forfeitingPlayerId == entity.player1Id || forfeitingPlayerId == entity.player2Id
        ) { "Player is not in this game" }

        // Load current state
        val currentState = objectMapper.readValue(entity.stateJson, GameState::class.java)

        // Determine winner (opponent of forfeiting player)
        val winnerId = if (forfeitingPlayerId == entity.player1Id) entity.player2Id else entity.player1Id

        // Build terminal game state
        val updatedPlayers = currentState.players.map { player ->
            if (player.id == winnerId) {
                Player(player.id, player.name, player.hand, 121)
            } else {
                player
            }
        }

        val updatedHistory = currentState.history + listOf(
            GameHistoryEvent.GameForfeited(
                forfeitingPlayerId = forfeitingPlayerId,
                reason = reason.name
            ),
            GameHistoryEvent.GameEnded(
                winnerPlayerId = winnerId,
                finalScore = 121
            )
        )

        val terminalState = currentState.copy(
            players = updatedPlayers,
            stage = GameStage.GAME_OVER,
            history = updatedHistory
        )

        // Update entity
        val winnerPlayer = updatedPlayers.first { it.id == winnerId }
        val loserPlayer = updatedPlayers.first { it.id != winnerId }
        entity.winnerId = winnerId
        entity.stage = GameStage.GAME_OVER.name
        entity.player1Score = updatedPlayers.first { it.id == entity.player1Id }.score
        entity.player2Score = updatedPlayers.first { it.id == entity.player2Id }.score
        entity.forfeitReason = reason.name
        entity.turnStartedAt = null
        entity.updatedAt = Instant.now()
        entity.stateJson = objectMapper.writeValueAsString(terminalState)
        gameRepository.save(entity)

        // Record stats
        playerStatsService.recordGameResult(
            winnerId = winnerPlayer.id,
            loserId = loserPlayer.id,
            winnerScore = winnerPlayer.score,
            loserScore = loserPlayer.score,
            isAIGame = entity.isAIGame
        )

        // Broadcast final state with timing info
        val timing = turnTimerService.getTimingFields(gameId, entity)
        webSocketService.broadcastGameStateUpdate(gameId, terminalState, timing)

        // Clean up timer
        turnTimerService.clearGame(gameId)

        logger.info(
            "Game {} forfeited by player {} (reason: {}). Winner: {}",
            gameId, forfeitingPlayerId, reason, winnerId
        )

        return terminalState
    }
}
