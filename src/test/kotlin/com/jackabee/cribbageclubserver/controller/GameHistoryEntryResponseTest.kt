package com.jackabee.cribbageclubserver.controller

import com.jackabee.cribbageclubserver.model.game.GameStage
import com.jackabee.cribbageclubserver.model.game.GameState
import com.jackabee.cribbageclubserver.model.player.Player
import com.fasterxml.jackson.databind.node.ObjectNode
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The history endpoint's shape is a compatibility contract: clients that
 * predate rating history parse each entry as a plain GameState, so the state's
 * fields must stay at the top level with the rating fields alongside them.
 */
class GameHistoryEntryResponseTest {

    @Test
    fun `serializes the game state flattened with rating fields alongside`() {
        val mapper = jacksonObjectMapper().registerModule(JavaTimeModule())
        val state = GameState(
            gameId = "game_1",
            players = listOf(Player("p1", "Alice"), Player("p2", "Bob")),
            stage = GameStage.GAME_OVER,
        )

        val node = mapper.valueToTree<ObjectNode>(
            GameHistoryEntryResponse(state, myRatingDelta = 12.5, opponentRating = 1450.0)
        )

        // GameState fields sit at the top level, not nested under "gameState".
        assertEquals("game_1", node.get("gameId").asText())
        assertTrue(node.get("players").isArray)
        assertEquals(null, node.get("gameState"))
        assertEquals(12.5, node.get("myRatingDelta").asDouble())
        assertEquals(1450.0, node.get("opponentRating").asDouble())
    }
}
