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

---

## 9. Mobile Feature Polish

### 9a. Game Replay (~70% → ~90%)

Core replay works (step-through, seeking, playback speed, visual state reconstruction). Gaps:

- [x] Handle `GameForfeited` event in `ReplaySnapshotBuilder` (currently ignored — could crash or show blank)
- [x] Add pull-to-refresh on game history screen so replay list stays current

### 9b. Sound & Haptics (~70% → ~95%)

7 sound events wired up. One gap:

- [x] Add sound + haptic feedback for `CribRevealedEvent` (fires when crib is shown during counting, currently silent)

### 9c. Lobbies (~70% → ~85%)

Lobby browser, create/join, waiting room, invite codes, share all work. Gaps:

- [ ] Generate shareable deep link URL for invite codes (currently shares plain text, not `https://cribbageclub.com/join/CODE`)
- [ ] Handle incoming deep links to auto-join lobby by code

### 9d. Friends (~80% → ~90%)

Friend list, search, requests, challenges, online dots, push notifications all work. Gaps:

- [ ] Add cancel/retract button on outgoing friend requests (requires backend endpoint)
- [x] Sort friends list (online first, then alphabetical)

### 9e. Leaderboard (~80% → ~90%)

Top-3 podium, My Rank card, full leaderboard tiles, profile navigation all work. Gaps:

- [x] Add pull-to-refresh to leaderboard screen
- [ ] Show player's rank even when not in top 10 (requires backend endpoint for own rank)

### 9f. Settings (~80% → ~90%)

9 settings with SharedPreferences persistence, in-game settings sheet. Gaps:

- [x] Add "Use System Theme" option (follow device light/dark preference)
- [ ] Add notification preferences (toggle push notifications per event type — requires backend)

### 9g. Game History (~90% → ~95%)

Local + server history, upload sync on login/connectivity, analyze/replay buttons. Gaps:

- [x] Add pull-to-refresh on game history screen
- [ ] Add pagination for server game history (requires backend endpoint changes)

### 9h. Analysis (~85% → ~95%)

Multi-layer caching, summary stats, per-round your-vs-optimal comparison. Gaps:

- [x] Show full ranked list of all 15 discard options in analysis round cards (previously only showed optimal + player choice)
