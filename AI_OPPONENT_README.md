# AI Opponent Feature

This document describes the AI opponent feature for the Cribbage Club Server.

## Overview

The AI opponent feature allows players to play Cribbage against a computer opponent instead of requiring two human players. The AI can make all the necessary decisions during a game:

- Discarding cards to the crib
- Playing cards during the pegging phase
- Announcing "go" when appropriate
- Automatically handling other game actions

## Architecture

### Components

1. **AIPlayer Interface** (`com.jackabee.cribbageclubserver.model.ai.AIPlayer`)
   - Defines the contract for AI players
   - Provides methods for making game decisions

2. **BasicAIPlayer** (`com.jackabee.cribbageclubserver.model.ai.BasicAIPlayer`)
   - Implementation of AIPlayer with basic strategies
   - Uses simple heuristics for decision making

3. **GameService** (`com.jackabee.cribbageclubserver.service.GameService`)
   - Manages games with AI opponents
   - Handles AI action processing automatically

### AI Strategies

The BasicAIPlayer uses these strategies:

#### Discarding Strategy
- **As Dealer**: Tries to keep pairs and 15-combinations, puts potentially useful cards in crib
- **As Non-Dealer**: Avoids giving dealer good crib cards (pairs, 15s)

#### Pegging Strategy
- Prioritizes scoring opportunities: 31 > 15 > pairs > runs
- Avoids giving opponent easy scoring opportunities
- Plays highest safe card when no scoring opportunities exist

## Usage

### Creating a Game with AI

```kotlin
val gameService = GameService()
val gameState = gameService.createGameWithAI("human123", "Alice")
```

### Playing Against AI

```kotlin
// Human player makes a move
val humanAction = GameAction.DiscardToCrib("human123", cardToDiscard)
val newState = gameService.applyHumanAction(gameId, humanAction)

// AI will automatically make its moves and return the updated state
```

### Example

See `AIOpponentExample.kt` for a complete example of how to use the AI opponent.

## Testing

The AI opponent is thoroughly tested with:
- Unit tests for AI decision making (`BasicAIPlayerTest`)
- Integration tests for the GameService (`GameServiceTest`)
- Tests cover all game phases and edge cases

## Future Enhancements

Potential improvements for the AI opponent:

1. **Difficulty Levels**: Implement different AI strategies for easy/medium/hard difficulties
2. **Advanced Strategies**: More sophisticated card evaluation and probabilistic reasoning
3. **Machine Learning**: Train AI using game data to improve decision making
4. **Personality**: Different AI "personalities" with varying play styles

## Configuration

Currently, the AI opponent uses a "basic" difficulty level. This can be specified when creating a game:

```kotlin
val gameState = gameService.createGameWithAI("human123", "Alice", "basic")
```

The difficulty parameter is reserved for future enhancements.