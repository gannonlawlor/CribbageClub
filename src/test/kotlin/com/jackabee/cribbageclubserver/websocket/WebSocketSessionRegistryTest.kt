package com.jackabee.cribbageclubserver.websocket

import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class WebSocketSessionRegistryTest {

    private val registry = WebSocketSessionRegistry()

    @Test
    fun `register and retrieve session`() {
        registry.register("sess1", "player1", "Alice", "game1")

        val info = registry.getSession("sess1")
        assertNotNull(info)
        assertEquals("player1", info.playerId)
        assertEquals("Alice", info.playerName)
        assertEquals("game1", info.gameId)
    }

    @Test
    fun `unregister returns session info and removes it`() {
        registry.register("sess1", "player1", "Alice", "game1")

        val info = registry.unregister("sess1")
        assertNotNull(info)
        assertEquals("player1", info.playerId)

        assertNull(registry.getSession("sess1"))
    }

    @Test
    fun `unregister unknown session returns null`() {
        assertNull(registry.unregister("unknown"))
    }

    @Test
    fun `getSessionsForGame returns matching sessions`() {
        registry.register("sess1", "player1", "Alice", "game1")
        registry.register("sess2", "player2", "Bob", "game1")
        registry.register("sess3", "player3", "Carol", "game2")

        val game1Sessions = registry.getSessionsForGame("game1")
        assertEquals(2, game1Sessions.size)
        assertTrue(game1Sessions.all { it.gameId == "game1" })

        val game2Sessions = registry.getSessionsForGame("game2")
        assertEquals(1, game2Sessions.size)
    }

    @Test
    fun `register overwrites previous session`() {
        registry.register("sess1", "player1", "Alice", "game1")
        registry.register("sess1", "player1", "Alice", "game2")

        val info = registry.getSession("sess1")
        assertNotNull(info)
        assertEquals("game2", info.gameId)
    }
}
