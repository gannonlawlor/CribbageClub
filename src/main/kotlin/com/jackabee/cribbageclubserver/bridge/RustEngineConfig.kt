package com.jackabee.cribbageclubserver.bridge

import com.fasterxml.jackson.databind.ObjectMapper
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
class RustEngineConfig {

    @Bean
    fun cribbageEngineLib(): CribbageEngineLib = CribbageEngineLib.load()

    @Bean
    fun rustEngineAdapter(
        cribbageEngineLib: CribbageEngineLib,
        objectMapper: ObjectMapper,
    ): RustEngineAdapter = RustEngineAdapter(cribbageEngineLib, objectMapper)
}
