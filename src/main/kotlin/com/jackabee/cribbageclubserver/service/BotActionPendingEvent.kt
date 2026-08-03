package com.jackabee.cribbageclubserver.service

/**
 * Published when a bot game reaches a state where the bot may owe an action —
 * after game creation (opening discards) and after every human action.
 * [BotMoveService] listens and schedules a delayed, human-feeling move; its
 * periodic sweep covers any event this mechanism misses (e.g. server restart).
 */
data class BotActionPendingEvent(val gameId: String)
