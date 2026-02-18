# TODO — CribbageClub

## ~~1. Security — Player-Visible Game State~~ ✅

~~Full game state (opponent's hand, remaining deck) is sent to all clients. A player can inspect network traffic to see the opponent's cards.~~

- [x] Create a `PlayerGameView` DTO that filters state per-player (own hand only, no `remainingDeck`)
- [x] Update `GameWebSocketService` to send player-specific views instead of full state
- [x] Update `GameController.getGame()` to accept a player ID and return filtered state
- [x] Add tests verifying opponents cannot see each other's hands

## ~~2. Security — WebSocket Authentication~~ ✅

~~WebSocket endpoints have no authentication. The STOMP action handler trusts the client-supplied `playerId`, meaning anyone can impersonate any player.~~

- [x] Add JWT validation to the WebSocket handshake (`HandshakeInterceptor` or `ChannelInterceptor`)
- [x] Extract player identity from the JWT token instead of trusting client-supplied `playerId`
- [x] Update `GameWebSocketController` to use authenticated principal
- [x] Add tests for WebSocket auth rejection

## ~~3. Security — Hardcoded Secrets & Rate Limiting~~ ✅

~~Default JWT secret and DB credentials are hardcoded in `application.properties`. Auth endpoints have no rate limiting.~~

- [x] Move JWT secret and DB credentials to environment variables with safe defaults for dev only
- [x] Add profile-specific config (`application-prod.properties`) that requires env vars
- [x] Add rate limiting to `/api/auth/login` and `/api/auth/register` (e.g., Bucket4j or Spring `RateLimiter`)

## ~~4. Game Logic Bugs~~ ✅

### ~~4a. "Go" doesn't end pegging when hands are empty~~
~~When both players announce "Go" and have no cards left, the game should transition to COUNTING. Currently it stays in PEGGING.~~

- [x] After a double-Go point award, check if all hands are empty and transition to `COUNTING`
- [x] Add test: both players Go with empty hands -> transitions to COUNTING

### ~~4b. `Deck.cut()` doesn't remove the cut card~~
~~`cut()` returns the middle card but leaves it in the deck. This means the cut card is still in `remainingDeck` when persisted, and could theoretically be drawn again.~~

- [x] Change `Deck.cut()` to remove the card from the internal list (use `removeAt`)
- [x] Add test verifying cut card is no longer in `remainingCards()`

## ~~5. Data Integrity~~ ✅

### ~~5a. Add `@Transactional` to service methods~~ ✅
~~Multi-step operations (e.g., `PlayerStatsService.recordGameResult()` updates two records) are not atomic.~~

- [x] Add `@Transactional` to `PlayerStatsService.recordGameResult()`
- [x] Add `@Transactional` to `LobbyService.startGame()`
- [x] Add `@Transactional` to `UserService.register()` and `UserService.login()`
- [x] Audit other service methods for transaction boundaries

### ~~5b. Add database migrations (Flyway)~~ ✅
~~Schema is managed by `ddl-auto=update` which is unsafe for production. No migration history.~~

- [x] Add Flyway dependency to `build.gradle.kts`
- [x] Create initial migration (`V1__initial_schema.sql`) from current entity definitions
- [x] Set `ddl-auto=validate` and rely on Flyway for schema management
- [x] Add migration for any future schema changes

### ~~5c. Optimistic locking for concurrent access~~ ✅
~~No `@Version` columns on entities — concurrent requests could overwrite each other's changes.~~

- [x] Add `@Version` column to `GameEntity`, `LobbyEntity`, `PlayerStatsEntity`
- [x] Handle `OptimisticLockException` in services with appropriate retry or error response

## ~~6. Testing~~ ✅

### ~~6a. Controller tests~~ ✅
~~No tests for `GameController`, `LobbyController`, or `StatsController`.~~

- [x] Add `GameControllerTest` (create game, apply action, get state, delete)
- [x] Add `LobbyControllerTest` (create, join, leave, start, list)
- [x] Add `StatsControllerTest` (get stats, leaderboard)
- [x] Test auth-required endpoints return 401 without token

### ~~6b. Full game round-trip test~~ ✅
~~No test plays a complete game from deal to GAME_OVER.~~

- [x] Add integration test that plays a full game (deal -> discard -> cut -> peg -> count -> new round -> eventual win)
- [x] Verify scoring is correct at each stage
- [x] Verify history events are complete and in order

### ~~6c. Game restore test~~ ✅
~~No test verifies that `Game.restore()` produces a game that behaves identically to the original.~~

- [x] Add test: create game, play some actions, persist state, restore, verify state matches
- [x] Add test: restore game and continue playing through to completion

## ~~7. Deployment & Infrastructure~~ ✅

### ~~7a. CI/CD pipeline~~ ✅
~~Only a Copilot setup workflow exists — no actual CI pipeline that runs on push/PR.~~

- [x] Create `.github/workflows/ci.yml` (build + test on push/PR to master)
- [x] Add linting / static analysis step (Detekt for Kotlin, `flutter analyze` for frontend)

### ~~7b. Docker Compose improvements~~ ✅
~~`docker-compose.yml` has PostgreSQL but no app service, and no prod profile activation.~~

- [x] Add `app` service to `docker-compose.yml` that builds and runs the Spring Boot app
- [x] Pass `SPRING_PROFILES_ACTIVE=prod` and DB credentials as environment variables
- [x] Add health check wait for PostgreSQL before app starts

### ~~7c. CORS configuration~~ ✅
~~CORS was implemented in `SecurityConfig` but origins were hardcoded.~~

- [x] Add CORS configuration in `SecurityConfig`
- [x] Make allowed origins configurable via `cors.allowed-origin-patterns` property

## ~~8. Code Quality~~ ✅

- [x] Extract shared AI utility methods (`combinations()`, `findRunContinuation()`) into `AIUtils` object
- [x] Fix `ScoreBreakdown` inconsistency: removed `totalScore` constructor param, made it a computed `val`
- [x] Filter AI players from leaderboard results in `PlayerStatsService`
