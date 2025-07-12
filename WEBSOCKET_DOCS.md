# WebSocket Game Communication

This document describes the WebSocket implementation for real-time game communication in the Cribbage Club Server.

## Overview

The WebSocket implementation allows players to:
- Join games and receive real-time game state updates
- Send game actions (discard, play card, etc.) 
- Receive notifications about other players joining/leaving
- Get immediate error feedback

## WebSocket Endpoints

### Connection
- **Endpoint**: `/ws`
- **Protocol**: STOMP over WebSocket with SockJS fallback
- **Supported**: SockJS for browser compatibility

### Message Destinations

#### Client to Server (Send)
- `/app/game/action` - Send game actions
- `/app/game/join` - Join a game session
- `/app/game/leave` - Leave a game session
- `/app/game/state` - Request current game state

#### Server to Client (Subscribe)
- `/topic/game/{gameId}` - Game state updates for specific game
- `/topic/game/{gameId}/players` - Player join/leave notifications
- `/queue/game-state` - Personal game state updates
- `/queue/errors` - Personal error messages

## Message Types

### Game Actions
```json
{
  "gameId": "game_123",
  "action": {
    "playerId": "player1",
    "card": {
      "rank": "KING",
      "suit": "HEARTS"
    }
  }
}
```

### Join Game
```json
{
  "gameId": "game_123",
  "playerId": "player1",
  "playerName": "John Doe"
}
```

### Game State Updates
```json
{
  "gameId": "game_123",
  "gameState": {
    "gameId": "game_123",
    "players": [...],
    "stage": "DISCARDING_TO_CRIB",
    "currentPlayerId": "player1",
    // ... complete game state
  },
  "timestamp": 1640995200000
}
```

## Integration with REST API

The WebSocket implementation works alongside the existing REST API:
- REST endpoints remain functional for traditional HTTP requests
- WebSocket provides real-time updates and can be used for game actions
- Both approaches update the same game state and broadcast via WebSocket

## Error Handling

Errors are sent to the client's personal error queue (`/queue/errors`) and include:
- Game not found
- Invalid player actions
- Connection issues
- Validation errors

## Client Usage Example

```javascript
// Connect to WebSocket
const socket = new SockJS('/ws');
const stompClient = Stomp.over(socket);

stompClient.connect({}, function(frame) {
    console.log('Connected: ' + frame);
    
    // Subscribe to game updates
    stompClient.subscribe('/topic/game/game_123', function(message) {
        const gameUpdate = JSON.parse(message.body);
        updateGameUI(gameUpdate.gameState);
    });
    
    // Subscribe to personal errors
    stompClient.subscribe('/queue/errors', function(message) {
        const error = JSON.parse(message.body);
        displayError(error.error);
    });
    
    // Join the game
    stompClient.send('/app/game/join', {}, JSON.stringify({
        gameId: 'game_123',
        playerId: 'player1',
        playerName: 'John Doe'
    }));
});

// Send game action
function playCard(card) {
    stompClient.send('/app/game/action', {}, JSON.stringify({
        gameId: 'game_123',
        action: {
            playerId: 'player1',
            card: card
        }
    }));
}
```

## Security Considerations

- WebSocket connections use the same security context as HTTP requests
- Game actions are validated server-side
- Player identity is verified for each action
- No sensitive data is exposed in WebSocket messages

## Configuration

WebSocket configuration is defined in `WebSocketConfig.kt`:
- Simple broker enabled for pub/sub messaging
- SockJS fallback for browser compatibility
- CORS configured for cross-origin requests