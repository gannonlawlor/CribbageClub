package com.jackabee.cribbageclubserver.repository

import com.jackabee.cribbageclubserver.entity.PlayerStatsEntity
import com.jackabee.cribbageclubserver.entity.UserEntity
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Bots must look human in a game but stay invisible everywhere players are
 * enumerated: these tests run the real JPQL against H2 with a seeded bot.
 */
@DataJpaTest
class BotExclusionQueriesTest {

    @Autowired
    private lateinit var userRepository: UserRepository

    @Autowired
    private lateinit var playerStatsRepository: PlayerStatsRepository

    @BeforeEach
    fun seed() {
        userRepository.save(UserEntity(id = "human-1", username = "gannon"))
        userRepository.save(
            UserEntity(id = "bot-1", username = "mollyq", isBot = true, botDifficulty = "basic")
        )
        playerStatsRepository.save(PlayerStatsEntity(playerId = "human-1", rating = 1400.0))
        playerStatsRepository.save(PlayerStatsEntity(playerId = "bot-1", rating = 1900.0))
    }

    @Test
    fun `leaderboard excludes bots even when top rated`() {
        val top = playerStatsRepository.findTop10ExcludingPrefixesAndBots("ai_%", "guest_%")

        assertEquals(listOf("human-1"), top.map { it.playerId })
    }

    @Test
    fun `username search never surfaces bots`() {
        // "o" matches both gannon and mollyq.
        val results = userRepository.searchByUsername("o", "someone-else")

        assertEquals(listOf("gannon"), results.map { it.username })
    }

    @Test
    fun `findByIsBotTrue returns exactly the bot pool`() {
        val bots = userRepository.findByIsBotTrue()

        assertEquals(1, bots.size)
        assertTrue(bots.single().isBot)
        assertEquals("mollyq", bots.single().username)
    }
}
