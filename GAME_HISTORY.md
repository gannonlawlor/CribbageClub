# Game History Tracking System

This document describes the game history tracking system implemented for the Cribbage Club Server.

## Overview

The game history system tracks all events that occur during a cribbage game that are visible to both players. This includes pegging actions, scoring events, and game progression, but excludes hidden information like discarded cards until they are revealed.

## Key Components

### GameHistoryEvent
A sealed class hierarchy representing different types of game events:

- `RoundStarted` - New round begins
- `CardsDealt` - Cards dealt to players
- `DeckCut` - Deck cut and cut card revealed
- `CardPlayed` - Card played during pegging
- `GoAnnounced` - Player announces "Go"
- `PeggingEnded` - Pegging phase completed
- `HandCounted` - Player's hand counted with score breakdown
- `CribCounted` - Dealer's crib counted with score breakdown
- `GameEnded` - Game completed

### GameHistoryTracker Interface
Provides methods to:
- `addEvent(event)` - Add new events
- `getHistory()` - Get all events chronologically
- `getEventsOfType(Class)` - Get events of specific type
- `getLastEventOfType(Class)` - Get most recent event of type
- `clear()` - Reset history

### Score Breakdown
Detailed scoring breakdown for hands and cribs:
```kotlin
data class ScoreBreakdown(
    val fifteens: Int = 0,
    val pairs: Int = 0,
    val runs: Int = 0,
    val flushes: Int = 0,
    val nobs: Int = 0
)
```

## Usage

### Accessing Game History
```kotlin
val game = Game("game-id", players)
val state = game.getCurrentState()
val history = state.history // List<GameHistoryEvent>
```

### Filtering Events
```kotlin
// Get all pegging events
val peggingEvents = history.filterIsInstance<GameHistoryEvent.CardPlayed>()

// Get all scoring events
val scoringEvents = history.filter { event ->
    when (event) {
        is GameHistoryEvent.CardPlayed -> event.pointsScored > 0
        is GameHistoryEvent.HandCounted -> event.totalPoints > 0
        is GameHistoryEvent.CribCounted -> event.totalPoints > 0
        else -> false
    }
}
```

### Analyzing Performance
```kotlin
// Calculate average hand scores
val handEvents = history.filterIsInstance<GameHistoryEvent.HandCounted>()
val avgScore = handEvents.map { it.totalPoints }.average()

// Analyze score breakdowns
val breakdowns = handEvents.map { it.scoreBreakdown }
val avgFifteens = breakdowns.map { it.fifteens }.average()
```

## Implementation Notes

### Lightweight Design
- Events are small data classes
- Only public information is tracked
- Simple counts rather than complex objects
- Efficient filtering and querying

### Extensibility
- Interface allows different storage backends
- Easy to add new event types
- Score breakdown structure can be extended

### Integration
- History automatically tracked during game play
- No changes needed to existing game actions
- Included in GameState for API responses

## Future Enhancements

The interface design allows for:
- Database storage implementation
- Advanced analytics
- Game replay functionality
- Historical trend analysis
- Performance metrics

## Example Events

```kotlin
// Pegging event
CardPlayed(
    playerId = "alice",
    card = Card(Rank.FIVE, Suit.HEARTS),
    newCount = 15,
    pointsScored = 2,
    scoringReason = "Fifteen"
)

// Hand counting event
HandCounted(
    playerId = "bob",
    totalPoints = 12,
    scoreBreakdown = ScoreBreakdown(
        fifteens = 4,
        pairs = 2,
        runs = 6,
        flushes = 0,
        nobs = 0
    )
)
```

This system provides comprehensive game history tracking while maintaining the performance and simplicity requirements of the cribbage game server.