# CLAUDE.md — Backend (Spring Boot)

## Overview

Spring Boot 3.4.13 server with Kotlin 1.9.25, JDK 21, PostgreSQL, and a Rust game engine via JNA.

## Build & Test

```bash
./gradlew build      # compile Rust engine + Kotlin, run tests
./gradlew test       # tests only
./gradlew bootRun    # run server (needs PostgreSQL on :5432)
```

Requires: JDK 21, Rust toolchain (cargo), PostgreSQL running on localhost:5432.

## Project Structure

```
src/main/kotlin/com/jackabee/cribbageclubserver/
├── config/           # SecurityConfig, WebSocketConfig, JWT filter, rate limiter, CORS
├── controller/       # GameController, LobbyController, AuthController, StatsController,
│                     # FriendController, ChallengeController, PuzzleController
├── service/          # GameService, LobbyService, UserService, AnalysisService,
│                     # PlayerStatsService, FriendService, PuzzleService, CleanupService
├── entity/           # JPA entities: User, Game, Lobby, PlayerStats, Puzzle, GameAnalysis, etc.
├── repository/       # Spring Data JPA repositories
├── model/            # Domain: GameState, GameAction (sealed), GameHistoryEvent (sealed),
│                     # Card/Rank/Suit, GameAnalysis, Player, Lobby, etc.
├── bridge/           # RustEngineAdapter (JNA FFI to Rust crate), RustEngineConfig
├── websocket/        # STOMP controllers, broadcast service, session registry
└── utils/            # HandCounting, ScoreBreakdownCalculator
```

## Key Architecture Decisions

- **Database = source of truth**: `GameEntity.stateJson` stores full `GameState` as JSON. In-memory `ConcurrentHashMap` is a cache; on miss, `loadGame()` reconstructs from DB.
- **Rust via JNA**: `RustEngineAdapter` bridges to native `libcribbage_engine` for game simulation, AI, and analysis. Built by Gradle's `cargoReleaseBuild` task.
- **Auth**: JWT (jjwt 0.13), 90-day expiry, `JwtAuthenticationFilter` on REST, `StompAuthChannelInterceptor` on WebSocket. Guest accounts supported.
- **Rate limiting**: Sliding-window `RateLimitFilter` on `/api/auth/*` (10 req/60s).
- **GameStateFilter**: Hides opponent hands, deck, and crib per player. Applied in all controllers before returning state.
- **Optimistic locking**: `@Version` on all mutable entities.
- **Flyway**: 7 migrations (V1–V7). `ddl-auto=validate` in production.

## Database Schema (Flyway Migrations)

| Version | Table(s) | Purpose |
|---------|----------|---------|
| V1 | users, games, lobbies, player_stats | Initial schema |
| V2 | (alters users, lobbies) | Guest accounts, private lobbies, invite codes |
| V3 | friendships | Friend system |
| V4 | (alters player_stats) | Glicko-2 rating columns |
| V5 | puzzles, puzzle_solves | Daily puzzles |
| V6 | (alters games) | Local game import (original_local_game_id) |
| V7 | game_analyses | Analysis caching |

## Serialization

- Jackson with Kotlin module, `@JsonTypeInfo(property = "type")` on sealed classes
- Action type names: `DiscardToCrib`, `PlayCard`, `CutDeck`, `Go`, `CountHand`
- History event names: `RoundStarted`, `CardsDealt`, `DeckCut`, `CardPlayed`, `GoAnnounced`, `PeggingEnded`, `HandCounted`, `CribCounted`, `GameEnded`
- Enums: UPPER_SNAKE (`ACE`, `TWO`, `CLUBS`, `DEALING`, etc.)
- Dates: ISO 8601 format (not timestamps)

## Configuration

- `application.properties`: DB, JWT secret, CORS origins, rate limits — all from env vars with safe dev defaults
- `application-prod.properties`: Strict — requires env vars, no defaults
- `application-alpha.properties`: Flyway-managed schema, Hibernate ddl-auto=none
- Docker: Multi-stage Dockerfile, non-root user, health check via actuator

## Testing

20 test files covering controllers, services, security, WebSocket, models. Uses JUnit 5, Mockito, H2 for integration tests.

## Conventions

- `require()` for precondition validation (throws `IllegalArgumentException` → 400)
- `IllegalStateException` for conflicts → 409
- `@Transactional` on multi-step service methods
- SLF4J logging (info for events, warn for rate limits, error for exceptions)
- `@Operation` annotations for Swagger/OpenAPI documentation
