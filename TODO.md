# TODO — CribbageClubServer

## 1. Security — Player-Visible Game State

Full game state (opponent's hand, remaining deck) is sent to all clients. A player can inspect network traffic to see the opponent's cards.

- [ ] Create a `PlayerGameView` DTO that filters state per-player (own hand only, no `remainingDeck`)
- [ ] Update `GameWebSocketService` to send player-specific views instead of full state
- [ ] Update `GameController.getGame()` to accept a player ID and return filtered state
- [ ] Add tests verifying opponents cannot see each other's hands

## 2. Security — WebSocket Authentication

WebSocket endpoints have no authentication. The STOMP action handler trusts the client-supplied `playerId`, meaning anyone can impersonate any player.

- [ ] Add JWT validation to the WebSocket handshake (`HandshakeInterceptor` or `ChannelInterceptor`)
- [ ] Extract player identity from the JWT token instead of trusting client-supplied `playerId`
- [ ] Update `GameWebSocketController` to use authenticated principal
- [ ] Add tests for WebSocket auth rejection

## 3. Security — Hardcoded Secrets & Rate Limiting

Default JWT secret and DB credentials are hardcoded in `application.properties`. Auth endpoints have no rate limiting.

- [ ] Move JWT secret and DB credentials to environment variables with safe defaults for dev only
- [ ] Add profile-specific config (`application-prod.properties`) that requires env vars
- [ ] Add rate limiting to `/api/auth/login` and `/api/auth/register` (e.g., Bucket4j or Spring `RateLimiter`)

## 4. Game Logic Bugs

### 4a. "Go" doesn't end pegging when hands are empty
When both players announce "Go" and have no cards left, the game should transition to COUNTING. Currently it stays in PEGGING.

- [ ] After a double-Go point award, check if all hands are empty and transition to `COUNTING`
- [ ] Add test: both players Go with empty hands -> transitions to COUNTING

### 4b. `Deck.cut()` doesn't remove the cut card
`cut()` returns the middle card but leaves it in the deck. This means the cut card is still in `remainingDeck` when persisted, and could theoretically be drawn again.

- [ ] Change `Deck.cut()` to remove the card from the internal list (use `removeAt`)
- [ ] Add test verifying cut card is no longer in `remainingCards()`

## 5. Data Integrity

### 5a. Add `@Transactional` to service methods
Multi-step operations (e.g., `PlayerStatsService.recordGameResult()` updates two records) are not atomic.

- [ ] Add `@Transactional` to `PlayerStatsService.recordGameResult()`
- [ ] Add `@Transactional` to `LobbyService.startGame()`
- [ ] Add `@Transactional` to `UserService.register()` and `UserService.login()`
- [ ] Audit other service methods for transaction boundaries

### 5b. Add database migrations (Flyway)
Schema is managed by `ddl-auto=update` which is unsafe for production. No migration history.

- [ ] Add Flyway dependency to `build.gradle.kts`
- [ ] Create initial migration (`V1__initial_schema.sql`) from current entity definitions
- [ ] Set `ddl-auto=validate` (or `none`) and rely on Flyway for schema management
- [ ] Add migration for any future schema changes

### 5c. Optimistic locking for concurrent access
No `@Version` columns on entities — concurrent requests could overwrite each other's changes.

- [ ] Add `@Version` column to `GameEntity`, `LobbyEntity`, `PlayerStatsEntity`
- [ ] Handle `OptimisticLockException` in services with appropriate retry or error response

## 6. Testing

### 6a. Controller tests
No tests for `GameController`, `LobbyController`, or `StatsController`.

- [ ] Add `GameControllerTest` (create game, apply action, get state, delete)
- [ ] Add `LobbyControllerTest` (create, join, leave, start, list)
- [ ] Add `StatsControllerTest` (get stats, leaderboard)
- [ ] Test auth-required endpoints return 401 without token

### 6b. Full game round-trip test
No test plays a complete game from deal to GAME_OVER.

- [ ] Add integration test that plays a full game (deal -> discard -> cut -> peg -> count -> new round -> eventual win)
- [ ] Verify scoring is correct at each stage
- [ ] Verify history events are complete and in order

### 6c. Game restore test
No test verifies that `Game.restore()` produces a game that behaves identically to the original.

- [ ] Add test: create game, play some actions, persist state, restore, verify state matches
- [ ] Add test: restore game and continue playing through to completion

## 7. Deployment & Infrastructure

### 7a. CI/CD pipeline
Only a Copilot setup workflow exists — no actual CI pipeline that runs on push/PR.

- [ ] Create `.github/workflows/ci.yml` (build + test on push/PR to master)
- [ ] Add linting or static analysis step (detekt for Kotlin)

### 7b. Docker Compose improvements
`docker-compose.yml` has PostgreSQL but no app service, and no prod profile activation.

- [ ] Add `app` service to `docker-compose.yml` that builds and runs the Spring Boot app
- [ ] Pass `SPRING_PROFILES_ACTIVE=prod` and DB credentials as environment variables
- [ ] Add health check wait for PostgreSQL before app starts

### 7c. CORS configuration
No CORS config for REST endpoints — browser clients from different origins will be blocked.

- [ ] Add CORS configuration in `SecurityConfig` or a dedicated `WebMvcConfigurer`
- [ ] Make allowed origins configurable via properties

## 8. Code Quality

- [ ] Extract shared AI utility methods (`combinations()`, `findRunContinuation()`) into a common `AIUtils` object
- [ ] Fix `ScoreBreakdown` inconsistency: `totalScore` field vs `total()` method compute differently
- [ ] Filter AI players from leaderboard results in `PlayerStatsService`
