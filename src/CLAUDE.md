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

## Deploying to Staging

The backend Docker image is **built remotely by GitHub Actions** — never build
it locally for staging. Pushing backend changes to `main` triggers the CI
`image` job, which pushes `ghcr.io/gannonlawlor/cribbage:main` to GHCR. Once
CI is green, updating the staging server is only a pull + restart on titan:

```bash
ssh titan "cd /opt/cribbage-staging \
  && docker compose -f docker-compose.staging.yml pull app \
  && docker compose -f docker-compose.staging.yml up -d app"
```

Flyway applies new migrations on boot. Verify via
`https://cribbage-staging.tail0b042f.ts.net/actuator/health` and
`docker logs cribbage-staging-app`.

## Project Structure

```
src/main/kotlin/com/jackabee/cribbageclubserver/
├── config/           # SecurityConfig, WebSocketConfig, JWT filter, rate limiter, CORS,
│                     # FcmConfig (push credentials, null when unconfigured)
├── controller/       # GameController, LobbyController, AuthController, StatsController,
│                     # FriendController, ChallengeController, PuzzleController,
│                     # ProfileController, DeviceTokenController
├── service/          # GameService, LobbyService, UserService, AnalysisService,
│                     # PlayerStatsService, FriendService, PuzzleService, CleanupService,
│                     # TurnTimerService, TimeoutCheckService, ForfeitService,
│                     # BotMatchmakingService, BotMoveService,
│                     # DeviceTokenService, PushNotificationService, JwtService
├── entity/           # JPA entities: User, Game, Lobby, PlayerStats, Puzzle, GameAnalysis,
│                     # Friendship, PuzzleSolve, DeviceToken
├── repository/       # Spring Data JPA repositories
├── model/            # Domain: GameState, GameAction (sealed), GameHistoryEvent (sealed),
│                     # Card/Rank/Suit, GameAnalysis, Player, Lobby, etc.
├── bridge/           # RustEngineAdapter (JNA FFI to Rust crate), RustEngineConfig
└── websocket/        # STOMP controllers, broadcast service, session registry
```

## Key Architecture Decisions

- **Database = source of truth**: `GameEntity.stateJson` stores full `GameState` as JSON. In-memory `ConcurrentHashMap` is a cache; on miss, `loadGame()` reconstructs from DB. Cleanup only *evicts* cache entries — it never deletes rows (completed games are user history).
- **Per-game locking**: Every engine touch for a game holds that game's monitor (`withGameLock`). Rust engine handles are raw pointers and not thread-safe, and concurrent actions on one game are routine (both players discard at once), so this prevents native data races and use-after-free on `close()`.
- **Action authorization**: `action.playerId` must equal the authenticated caller on both REST (`GameController`) and WebSocket (`GameWebSocketController`) — a participant must not act (or forfeit) as their opponent.
- **Rust via JNA**: `RustEngineAdapter` bridges to native `libcribbage_engine` for game simulation, AI, and analysis. Built by Gradle's `cargoReleaseBuild` task.
- **Auth**: JWT (jjwt 0.13), 90-day expiry, `JwtAuthenticationFilter` on REST, `StompAuthChannelInterceptor` on WebSocket. Guest accounts supported.
- **Rate limiting**: Sliding-window `RateLimitFilter` on `/api/auth/*` (10 req/60s).
- **GameStateFilter**: Hides opponent hands, deck, and crib per player. Applied in all controllers before returning state.
- **Optimistic locking**: `@Version` on all mutable entities.
- **Flyway**: 13 migrations (V1–V13). `ddl-auto=validate` in production.
- **Turn timers & forfeit**: Named time controls (BLITZ/RAPID/CASUAL/UNLIMITED) chosen per lobby and frozen onto the game at creation (V11), so config changes never alter a live game. `TurnTimerService` runs a **per-player** clock — `DISCARDING_TO_CRIB` lets both players act concurrently, so a single shared clock charged the wrong player. `TimeoutCheckService` sweeps every 5s; `ForfeitService` handles timeouts and resignations and publishes `GameEndedEvent` so `GameService` drops its cached engine handle.
- **Push notifications**: FCM HTTP v1 via `PushNotificationService`; `FcmConfig` holds credentials (no-op when unconfigured). Sent only when `WebSocketSessionRegistry.isUserOnline()` is false. Events: friend request, challenge received, game found. Device tokens registered via `/api/device-tokens`.
- **Bot fallback matchmaking**: after `cribbage.bots.wait-seconds` (default 60s) with no human match, `BotMatchmakingService` joins a human-looking pool bot (16 seeded users with `is_bot`, UUID ids, real `player_stats`) into the quick-match lobby via the normal `joinLobbyById` path. `BotMoveService` then plays the bot with jittered per-stage delays (capped at half the turn limit in timed games) by calling `GameService.advanceBotGame` — one engine step per call. Bot games keep `isAIGame = false` so timers, Glicko-2 rating, and the timeout sweep treat the bot like a human; the hard invariant is that a bot id must never land in `CachedGame.aiPlayerId`, which is the legacy synchronous instant-move path. Bots are excluded from the leaderboard, friend search, and friend requests, but their profiles stay public.

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
| V8 | (alters games) | Turn timers (time banks) and forfeit reason |
| V9 | (alters users, player_stats) | Avatar index, AI-vs-human split stats |
| V10 | device_tokens | Push notification device tokens |
| V11 | (alters games, lobbies) | Configurable time controls (preset + frozen turn limit) |
| V12 | player_achievements, achievement_progress | Achievements (unlocks + fresh-start counters) |
| V13 | (alters users, games, lobbies) | Bot fallback matchmaking (is_bot flag, bot game columns, quick-match discriminator, 16 seeded bot personas) |

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

27 test files covering controllers, services, security, WebSocket, models. Uses JUnit 5, Mockito, H2 for integration tests.

`TurnTimerService` takes an injectable `java.time.Clock` so timer tests advance time instead of sleeping (see `testutil/MutableClock`); `GameServiceTest` drives it through an injected `TurnTimerService`.

## Conventions

- `require()` for precondition validation (throws `IllegalArgumentException` → 400)
- `IllegalStateException` for conflicts → 409
- `@Transactional` on multi-step service methods
- SLF4J logging (info for events, warn for rate limits, error for exceptions)
- `@Operation` annotations for Swagger/OpenAPI documentation
