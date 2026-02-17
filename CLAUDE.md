# CLAUDE.md — CribbageClubServer

## Project Overview

CribbageClubServer is a Spring Boot backend for a multiplayer Cribbage card game. It supports human-vs-human and human-vs-AI play over REST and WebSocket (STOMP/SockJS). Game state is held in-memory; there is no persistent database layer yet.

## Tech Stack

- **Language:** Kotlin 1.9.25
- **Framework:** Spring Boot 3.3.3
- **JDK:** 21 (Amazon Corretto in CI)
- **Build:** Gradle 8.10 with Kotlin DSL
- **Database:** H2 (dependency present, not wired up — all state lives in `ConcurrentHashMap`)
- **Real-time:** STOMP over WebSocket with SockJS fallback
- **Testing:** JUnit 5, Mockito, Spring Boot Test

## Build & Test

```bash
./gradlew build    # compile + test
./gradlew test     # tests only
```

CI runs both on ubuntu-latest with JDK 21 (see `.github/workflows/copilot-setup-steps.yml`).

## Project Structure

```
src/main/kotlin/com/jackabee/cribbageclubserver/
├── CribbageClubServerApplication.kt   # Entry point
├── config/
│   ├── SecurityConfig.kt              # Spring Security (permits all, CSRF off)
│   └── WebSocketConfig.kt             # STOMP broker at /ws
├── controller/
│   ├── GameController.kt              # REST: /api/games
│   └── LobbyController.kt            # REST: /api/lobbies
├── model/
│   ├── action/                        # GameAction sealed class, ActionType enum
│   ├── ai/                            # AIPlayer interface, BasicAIPlayer
│   ├── card/                          # Card, Rank, Suit, Deck
│   ├── game/                          # Game engine, GameState, GameStage, history
│   ├── lobby/                         # Lobby, LobbyPlayer, LobbyStatus
│   └── player/                        # Player data class
├── service/
│   ├── GameService.kt                 # Game lifecycle, AI turn processing
│   └── LobbyService.kt               # Lobby CRUD, matchmaking
├── utils/
│   ├── HandCounting.kt                # Cribbage scoring (15s, pairs, runs, flushes, nobs)
│   └── ScoreBreakdownCalculator.kt    # Detailed score breakdown
├── websocket/
│   ├── GameWebSocketController.kt     # STOMP message handlers
│   ├── GameWebSocketService.kt        # Broadcast helpers
│   ├── GameWebSocketMessages.kt       # Message DTOs
│   └── WebSocketEventHandler.kt       # Connect/disconnect events
└── examples/                          # Usage example code
```

## Key API Endpoints

### REST
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/games` | List all active games |
| GET | `/api/games/{gameId}` | Get game state |
| POST | `/api/games/{gameId}/actions` | Apply a game action |
| GET | `/api/lobbies` | List all lobbies |
| GET | `/api/lobbies/waiting` | List lobbies waiting for players |
| POST | `/api/lobbies` | Create a lobby |
| POST | `/api/lobbies/{lobbyId}/join` | Join a lobby |
| POST | `/api/lobbies/{lobbyId}/leave` | Leave a lobby |
| POST | `/api/lobbies/{lobbyId}/start` | Start a game from lobby |

### WebSocket (STOMP)
- **Connect:** `/ws` (SockJS fallback)
- **Send:** `/app/game/action`, `/app/game/join`, `/app/game/leave`, `/app/game/state`
- **Subscribe:** `/topic/game/{gameId}`, `/topic/game/{gameId}/players`, `/queue/game-state`, `/queue/errors`

## Game Flow

1. **DEALING** — 6 cards dealt to each player
2. **DISCARDING_TO_CRIB** — Each player discards 2 cards to the crib
3. **CUTTING** — Non-dealer cuts deck; Jack ("His Nobs") scores 2 for dealer
4. **PEGGING** — Alternating card play to 31; scoring for 15s, 31s, pairs, runs
5. **COUNTING** — Hands and crib scored (15s, pairs, runs, flushes, nobs)
6. **GAME_OVER** — First player to 121 wins

## Architecture Notes

- `Game.kt` is the core engine (~407 lines). It enforces rules, validates actions, and tracks history.
- `GameService` wraps `Game` in a `ConcurrentHashMap`, handles AI turn loops (max 10 iterations), and broadcasts state via WebSocket.
- `BasicAIPlayer` uses heuristic strategies for discard and pegging decisions.
- `GameHistoryTracker` records all visible events as a sealed-class hierarchy included in `GameState`.
- Security is currently wide open (`permitAll`); suitable for development only.

## Coding Conventions

- Kotlin data classes for models, sealed classes for actions and history events
- Spring `@Service` / `@RestController` / `@Configuration` annotations
- Error handling: `require()` in game logic, `try-catch` returning `ResponseEntity` in controllers, error messages sent to `/queue/errors` via WebSocket
- Tests use JUnit 5 assertions and Mockito for mocking services
