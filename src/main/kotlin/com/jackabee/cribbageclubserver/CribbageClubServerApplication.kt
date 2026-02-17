package com.jackabee.cribbageclubserver

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.scheduling.annotation.EnableScheduling

@SpringBootApplication
@EnableScheduling
class CribbageClubServerApplication

fun main(args: Array<String>) {
    runApplication<CribbageClubServerApplication>(*args)
}
