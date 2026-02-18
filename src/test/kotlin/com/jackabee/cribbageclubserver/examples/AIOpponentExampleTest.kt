package com.jackabee.cribbageclubserver.examples

import com.jackabee.cribbageclubserver.bridge.CribbageEngineLib
import com.jackabee.cribbageclubserver.bridge.RustEngineAdapter
import com.jackabee.cribbageclubserver.service.GameService
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.Test

class AIOpponentExampleTest {

    companion object {
        private lateinit var lib: CribbageEngineLib

        @JvmStatic
        @BeforeAll
        fun loadNativeLib() {
            lib = CribbageEngineLib.load()
        }
    }

    @Test
    fun `should run AI opponent example without errors`() {
        val objectMapper = jacksonObjectMapper()
        val adapter = RustEngineAdapter(lib, objectMapper)
        val gameService = GameService(objectMapper = objectMapper, rustEngineAdapter = adapter)
        val example = AIOpponentExample(gameService)
        example.runExample()
    }
}
