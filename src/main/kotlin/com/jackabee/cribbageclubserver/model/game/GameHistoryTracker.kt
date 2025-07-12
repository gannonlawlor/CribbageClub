package com.jackabee.cribbageclubserver.model.game

/**
 * Interface for tracking game history events.
 * This allows for different implementations (in-memory, database, etc.)
 */
interface GameHistoryTracker {
    /**
     * Add a new event to the history
     */
    fun addEvent(event: GameHistoryEvent)

    /**
     * Get all events in chronological order
     */
    fun getHistory(): List<GameHistoryEvent>

    /**
     * Get events of a specific type
     */
    fun <T : GameHistoryEvent> getEventsOfType(eventType: Class<T>): List<T>

    /**
     * Get the most recent event of a specific type
     */
    fun <T : GameHistoryEvent> getLastEventOfType(eventType: Class<T>): T?

    /**
     * Clear all history (useful for testing or new games)
     */
    fun clear()
}

/**
 * Simple in-memory implementation of GameHistoryTracker
 */
class ListGameHistoryTracker : GameHistoryTracker {
    private val events = mutableListOf<GameHistoryEvent>()

    override fun addEvent(event: GameHistoryEvent) {
        events.add(event)
    }

    override fun getHistory(): List<GameHistoryEvent> {
        return events.toList()
    }

    @Suppress("UNCHECKED_CAST")
    override fun <T : GameHistoryEvent> getEventsOfType(eventType: Class<T>): List<T> {
        return events.filter { eventType.isInstance(it) } as List<T>
    }

    @Suppress("UNCHECKED_CAST")
    override fun <T : GameHistoryEvent> getLastEventOfType(eventType: Class<T>): T? {
        return events.reversed().firstOrNull { eventType.isInstance(it) } as T?
    }

    override fun clear() {
        events.clear()
    }
}