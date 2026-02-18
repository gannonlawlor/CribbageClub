# CLAUDE.md — Cribbage Club

## Project Overview

Cribbage Club is a cross-platform multiplayer Cribbage card game inspired by Chess.com and LiChess. The project is a monorepo containing a Spring Boot backend and a Flutter frontend.

- **Backend** (`src/`): Spring Boot server handling game logic, persistence, and real-time communication. The database is the source of truth for game state; in-memory `Game` objects serve as a cache for active play and are reconstructed from the DB on cache miss (e.g., after server restart).
- **Frontend** (`frontend/`): Flutter app targeting iOS, Android, and Web from a single codebase. See [FRONTEND.md](FRONTEND.md) for the full frontend plan, architecture, and phased development roadmap.

## Tech Stack

### Backend
- **Language:** Kotlin 1.9.25
- **Framework:** Spring Boot 3.3.3
- **JDK:** 21 (Amazon Corretto in CI)
- **Build:** Gradle 8.10 with Kotlin DSL
- **Database:** PostgreSQL (source of truth for game/lobby state; in-memory Game objects serve as cache)
- **Real-time:** STOMP over WebSocket with SockJS fallback
- **Testing:** JUnit 5, Mockito, Spring Boot Test

### Frontend
- **Framework:** Flutter (iOS, Android, Web)
- **Language:** Dart
- **State Management:** Riverpod
- **Routing:** GoRouter
- **HTTP/WebSocket:** Dio + stomp_dart_client
- **Code Generation:** freezed + json_serializable for models

## Build & Test

### Backend
```bash
./gradlew build    # compile + test
./gradlew test     # tests only
```

### Frontend
```bash
cd frontend
flutter pub get           # install dependencies
flutter run               # run on connected device / browser
flutter build web         # production web build
flutter build apk         # Android APK
flutter build ios         # iOS (requires macOS + Xcode)
flutter test              # run tests
dart run build_runner build  # regenerate freezed/json_serializable code
```

CI runs backend on ubuntu-latest with JDK 21 (see `.github/workflows/copilot-setup-steps.yml`).

## Project Structure

### Monorepo Layout
```
CribbageClubServer/
├── src/                          # Spring Boot backend
├── frontend/                     # Flutter app (iOS, Android, Web)
├── CLAUDE.md                     # This file
├── TODO.md                       # Backend task list
├── FRONTEND.md                   # Frontend plan and architecture
└── docker-compose.yml
```

### Backend
```
src/main/kotlin/com/jackabee/cribbageclubserver/
├── CribbageClubServerApplication.kt   # Entry point
├── config/
│   ├── GlobalExceptionHandler.kt      # @ControllerAdvice with structured ErrorResponse
│   ├── SecurityConfig.kt              # Spring Security (permits all, CSRF off)
│   └── WebSocketConfig.kt             # STOMP broker at /ws
├── controller/
│   ├── GameController.kt              # REST: /api/games (CRUD + AI game creation)
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

### Frontend
See [FRONTEND.md](FRONTEND.md) for the full directory structure. Key areas:
- `frontend/lib/core/api/` — REST + STOMP WebSocket clients
- `frontend/lib/core/models/` — Dart models mirroring backend Kotlin types (freezed)
- `frontend/lib/features/game/` — Game screen, card widgets, cribbage board (CustomPainter)
- `frontend/lib/features/lobby/` — Lobby browser and matchmaking
- `frontend/lib/features/profile/` — Stats, rating, game history

## Key API Endpoints

### REST
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/games` | List all active games |
| GET | `/api/games/{gameId}` | Get game state |
| POST | `/api/games/ai` | Create a game against AI |
| POST | `/api/games/{gameId}/actions` | Apply a game action |
| DELETE | `/api/games/{gameId}` | Delete a game |
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
5. **COUNTING** — Non-dealer counts first, then dealer, then crib scored
6. **GAME_OVER** — First player to 121 wins

Dealer rotates each round via `GameState.dealerIndex`.

## Architecture Notes

- `Game.kt` is the core engine. It enforces rules, validates actions, and tracks history. `Game.restore(state)` reconstructs a `Game` from a persisted `GameState` (including deck state via `remainingDeck`).
- `GameState.dealerIndex` tracks dealer rotation; non-dealer cuts and counts first. `GameState.remainingDeck` captures deck state for persistence/restoration.
- `GameService` uses the database as source of truth with an in-memory `ConcurrentHashMap` cache. On cache miss (e.g., after restart), it calls `loadGame()` to restore from DB. Handles AI turn loops (max 10 iterations) and broadcasts state via WebSocket.
- `LobbyService` uses the database directly (no in-memory fallback).
- `BasicAIPlayer` uses heuristic strategies for discard and pegging decisions.
- `GameHistoryTracker` records all visible events as a sealed-class hierarchy included in `GameState`.
- `GlobalExceptionHandler` provides structured `ErrorResponse` JSON for all REST errors.
- Security is currently wide open (`permitAll`); suitable for development only.

## Coding Conventions

- Kotlin data classes for models, sealed classes for actions and history events
- Spring `@Service` / `@RestController` / `@Configuration` annotations
- Error handling: `require()` in game logic, `GlobalExceptionHandler` catches exceptions for REST, error messages sent to `/queue/errors` via WebSocket
- SLF4J logging in server code (examples use println for demo output)
- Tests use JUnit 5 assertions and Mockito for mocking services

## Remaining Work

- **Backend:** See [TODO.md](TODO.md) for the prioritized task list. Key frontend-blocking items: CORS config (#7c), PlayerGameView DTO (#1), WebSocket auth (#2).
- **Frontend:** See [FRONTEND.md](FRONTEND.md) for the phased development plan (Phase 1–5).
