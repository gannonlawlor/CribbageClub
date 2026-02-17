package com.jackabee.cribbageclubserver.examples

import com.jackabee.cribbageclubserver.service.GameService
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest

@SpringBootTest
class AIOpponentExampleTest {

    @Autowired
    private lateinit var gameService: GameService

    @Test
    fun `should run AI opponent example without errors`() {
        val example = AIOpponentExample(gameService)
        example.runExample()
    }
}
