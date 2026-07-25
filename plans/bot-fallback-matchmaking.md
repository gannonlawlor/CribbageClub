# Bot Fallback Matchmaking — Technical Plan

## Context

Quick-match today (`LobbyService.quickMatch`) only pairs humans: if nobody compatible is waiting, the player sits in a `WAITING` lobby indefinitely. With a small player base, most searches never match. The fix: after ~60 seconds of waiting with no human available, a server-side bot with a human-like identity joins the player's lobby and plays them, with jittered "thinking" delays so its moves feel human.

**User-confirmed decisions:**
- Bots look **fully human** — human names, normal UUID ids, no client hint. Clients detect AI via the `ai_` id prefix and the "AI Opponent" name; bots avoid both, so **zero client changes are needed**.
- Bots are a **persistent pool** (16 seeded `UserEntity` rows) with a server-only `is_bot` flag.
- Bot games are **fully rated** (Glicko-2); bots have their own `player_stats` rows with seeded ratings that drift with results.
- **Difficulty matched to the player's rating**: each persona has a fixed engine difficulty (basic/medium/hard) and a seeded rating in the matching band; pick the bot rated closest to the waiter.
- Bot games use the lobby's **real time control** (`isAIGame = false` → timers, time banks, and timeout forfeit all apply to the bot like a human).

## Verified codebase facts that shape the design

- Waiting quick-match players are public non-challenge `WAITING` lobby DB rows with `createdAt` ([LobbyService.kt:119](src/main/kotlin/com/jackabee/cribbageclubserver/service/LobbyService.kt#L119)); `joinLobbyById` auto-starts via `gameService.createGame` and fires `notifyGameFound` (WS + push) to the waiter — the bot join reuses this path verbatim.
- **Do NOT reuse `CachedGame.aiPlayerId` for bots**: `applyHumanAction` synchronously drives any cached `aiPlayerId` to completion (`processAIActions`, maxIterations=10) — the bot would move instantly. Bots need separate `botPlayerId`/`botDifficulty` cache fields + entity columns, with `aiPlayerId` staying null.
- `RustEngineAdapter.processAI(maxIterations = 1)` is confirmed single-step (engine/src/ai/ai_player.rs) — one action per call; a discard phase is two delayed steps.
- `loadGame` (GameService.kt:582) only restores AI metadata when `isAIGame` — bot restore must read the new bot columns (this is the server-restart recovery path).
- Rating gate is id-prefix based (`PlayerStatsService` skips `ai_`/`guest_`): UUID-id bots get rated with **no changes** to the rating path. Leaderboard and friend search need explicit `is_bot` exclusions.
- `TurnTimerService.isTimed = !isAIGame && timeControl.isTimed` — bot games are timed automatically; if the bot driver ever fails, `TimeoutCheckService` forfeits the *bot* (graceful failure: the human wins a rated game).
- Latest migration is **V11**; new one is **V12**. Tests run on H2 with Flyway disabled, so tests seed bot rows programmatically.
- Time controls: BLITZ 10s/turn, RAPID 30s, CASUAL 60s — bot delays must be capped by a fraction of the turn limit.
- Single-node deployment is already assumed by the in-memory engine cache and session registry; the bot services inherit that assumption.

## Implementation

### 1. Migration `V12__bot_players.sql` + entity updates

`src/main/resources/db/migration/V12__bot_players.sql`:
- `users`: add `is_bot BOOLEAN NOT NULL DEFAULT FALSE`, `bot_difficulty VARCHAR(20)` (fixed per-persona; deriving from live rating would silently change a bot's strength).
- `games`: add `bot_player_id VARCHAR(255)`, `bot_difficulty VARCHAR(20)`.
- `lobbies`: add `is_quick_match BOOLEAN NOT NULL DEFAULT FALSE` — the discriminator so bots only fill quick-match lobbies, never user-created public lobbies (don't match on `name == "Quick Game"`).
- Indexes: partial on `users(is_bot)`, composite on `lobbies(status, is_quick_match, created_at)`.
- **Seed 16 bot users**: fixed literal UUIDs, `password_hash = NULL` (cannot log in), human usernames/display names, valid `avatar_index`, `created_at` spread over plausible past dates. Use `INSERT ... ON CONFLICT (username) DO NOTHING` to survive prod username collisions.
- **Seed matching `player_stats` rows**: rating per tier — basic 1160–1340, medium 1410–1600, hard 1660–1940; `rating_deviation = 200` (stable but able to drift); modest seeded `games_played`/`games_won` so profiles don't show "0 games, rating 1780" (the most obvious tell).
- Personas (username / difficulty / rating), e.g.: `mollyq` 1160, `tom_59` 1210, `lindad` 1250, `pegs_n_pints` 1300, `jbeckett` 1340 (basic); `sarahjk` 1410, `mikepegs` 1460, `anniemac` 1500, `dbl_run_dan` 1550, `heatherb77` 1590, `kwhitfield` 1600 (medium); `gcormier` 1660, `skunk_line_sam` 1730, `vpatel88` 1800, `muggins_marie` 1870, `the_cut_card` 1940 (hard).

Entity/repo changes:
- `UserEntity`: `isBot: Boolean = false`, `botDifficulty: String?`. Never add these to any DTO (ProfileResponse/UserSearchResult/AuthResponse are hand-built — keep them clean).
- `GameEntity`: `botPlayerId: String?`, `botDifficulty: String?` (explicit `@Column(name = ...)`).
- `LobbyEntity` + `Lobby` model: `isQuickMatch: Boolean = false`; `createLobby` gains the param, set `true` only from `quickMatch` (LobbyService.kt:137); thread through `toLobby`/`saveLobbyEntity`.
- `UserRepository`: `findByIsBotTrue()`. `GameRepository`: `findActiveBotGames()` (`winnerId IS NULL AND botPlayerId IS NOT NULL`).

### 2. Config — `BotProperties`

New `config/BotProperties.kt` (`@ConfigurationProperties(prefix = "cribbage.bots")`, mirroring `TimerProperties`): `enabled` (true), `waitSeconds` (60), `matchSweepIntervalMs` (10 000), `moveSweepIntervalMs` (5 000), per-stage delay ranges, `maxDelayFractionOfTurnLimit` (0.5, clamped ≤1.0 at load).

Delay defaults ("a little longer than normal"): discard 3–8 s per card, pegging play/Go 1.5–4.5 s, cut 1–2.5 s, count 2–5 s. For timed games, cap at `turnTimeLimitMs * 0.5` (BLITZ ⇒ ≤5 s, bank never drains); UNLIMITED uncapped.

`application.properties`: `cribbage.bots.enabled=${BOTS_ENABLED:true}`, `cribbage.bots.wait-seconds=${BOTS_WAIT_SECONDS:60}`.

### 3. GameService — bot game wiring

[GameService.kt](src/main/kotlin/com/jackabee/cribbageclubserver/service/GameService.kt):
- `CachedGame` gains `botPlayerId`/`botDifficulty` (aiPlayerId stays null for bot games so the legacy synchronous path no-ops).
- New optional constructor deps in the existing `@Autowired(required = false) = null` style: `userRepository`, `eventPublisher` (keeps `GameServiceTest`'s direct construction working).
- **`createGame` self-discovers bots**: look up player ids via `userRepository`, if one `isBot` → set bot fields on `CachedGame` + entity (via new `saveGameEntity` params). `isAIGame` stays `false` so timers/rating/sweep all treat it as a human game. After the initial broadcast, publish `BotActionPendingEvent(gameId)` (bot may owe opening discards). **No LobbyService signature changes needed** — the lobby auto-start path just works.
- `loadGame`: restore `botPlayerId`/`botDifficulty` from the entity (restart recovery).
- `applyHumanAction`: after broadcast, if `cached.botPlayerId != null && stage != GAME_OVER`, publish `BotActionPendingEvent`. Plain `@EventListener` (published outside a transaction).
- New `advanceBotGame(gameId): BotStepResult?` — the single engine-touching bot step, inside `withGameLock`: no-op if game gone/over/not a bot game or bot owes nothing; else `processAI(maxIterations = 1)`, then the same tail as `applyHumanAction` (timer `onActionReceived`/`onTurnStart`, persist, GAME_OVER eviction + stats, broadcast with timing). Returns `botStillPending` so the driver chains consecutive bot actions. `botOwesAction`: during `DISCARDING_TO_CRIB`, bot hand size > 4; otherwise `currentPlayerId == botId` (mirrors `TurnTimerService.playersOnClock`).
- New event class `BotActionPendingEvent(gameId)` beside `GameEndedEvent`.

### 4. `BotMoveService` — delayed move driver

New `service/BotMoveService.kt`. Mechanism: dedicated `ThreadPoolTaskScheduler` bean (`botMoveScheduler`, pool ~2 — don't share the single `@Scheduled` thread that `TimeoutCheckService` needs). No coroutines (codebase has none); `ScheduledFuture` gives dedup/cancellation.

- `pending: ConcurrentHashMap<gameId, ScheduledFuture>` deduplicates: `@EventListener onBotActionPending` and the sweep both call `maybeSchedule`, which schedules only if absent. `executeMove` removes its entry before acting, calls `gameService.advanceBotGame`, and reschedules while `botStillPending` (chains discard→discard, count→count runs). Exceptions (incl. `OptimisticLockingFailureException` from a concurrent timeout forfeit) are caught and logged; the sweep retries.
- Delay picked from the entity's `stage` column + capped by `turnTimeLimitMs` per §2.
- **Self-healing sweep** `@Scheduled(fixedDelay = moveSweepIntervalMs)`: `gameRepository.findActiveBotGames()` → `maybeSchedule` each. Covers missed events and server restarts (empty `pending` map repopulates within 5 s; `loadGame` restores engines). Worst case the bot "thinks" for sweep+delay — indistinguishable from a slow human.

### 5. `BotMatchmakingService` — the fallback sweep

New `service/BotMatchmakingService.kt`, `@Scheduled(fixedDelay = matchSweepIntervalMs)`:
1. Bail if disabled. Find `WAITING` public non-challenge lobbies where `isQuickMatch && createdAt <= now - waitSeconds` and exactly one player.
2. **Online gate**: skip unless `WebSocketSessionRegistry.isUserOnline(waiterId)` — matching an absent player would start their clock and hand them a rated loss.
3. `selectBot(waiterId)`: waiter rating from `playerStatsRepository` (default 1500); pool from `findByIsBotTrue()` joined with stats; exclude bots already in an active game with this waiter; sort by rating distance, pick randomly among the closest 2–3 so the same persona doesn't always appear.
4. Join via the existing `lobbyService.joinLobbyById(lobby.id, bot.id, bot.displayName)` — reuses auto-start, `notifyGameFound` (WS "Game Found" with the bot's human name), lobby persistence.
5. Per-lobby try/catch: if a human joined between query and join, the lobby `@Version` bump / `WAITING→IN_GAME` transition makes the bot's join throw — log debug, skip. `fixedDelay` prevents self-overlap.

### 6. Exclusions (rating path needs none)

- **Leaderboard**: new `PlayerStatsRepository` query adding `NOT EXISTS (SELECT 1 FROM UserEntity u WHERE u.id = p.playerId AND u.isBot = true)` to the existing prefix exclusions; switch `PlayerStatsService.getLeaderboard()` to it.
- **Friend search**: append `AND u.isBot = false` to `UserRepository.searchByUsername`; also `require(!addressee.isBot)` in `FriendService.sendFriendRequest` (exact-username path bypasses search). With friendship closed, challenges are closed too (`ChallengeController` requires friendship).
- **Deliberately open**: `/api/profiles/{botId}` and `/api/stats/{botId}` — tapping the bot's name must show a normal profile (why seeded stats matter).
- Guests: bot-vs-guest games stay unrated via the existing `guest_` gate but still record — don't gate the sweep on non-guest or guests wait forever.

### 7. Update `src/CLAUDE.md`

Migration table (V12), service list, config section.

## Tests

New tests under `src/test/kotlin/.../service/` (H2 + programmatic bot seeding since Flyway is off in tests; `GameServiceTest` keeps direct construction with a stubbed `userRepository`):
- **BotMatchmakingServiceTest**: stale quick-match lobby + online waiter → bot joins, `IN_GAME`, `botPlayerId` set, `isAIGame=false`, lobby's time control kept; young lobby / non-quick-match lobby / offline waiter → untouched; rating proximity picks the right tier; bot already playing the waiter excluded; optimistic-lock loss doesn't escape the sweep.
- **BotMoveServiceTest** (fake TaskScheduler): schedules once per game (event+sweep dedup), chains on `botStillPending`, survives exceptions, respects `enabled=false`; BLITZ delay ≤ 5 s, UNLIMITED uncapped.
- **GameServiceTest additions**: bot game creation sets bot cache/entity fields with `aiPlayerId` null; `advanceBotGame` applies exactly one action, no-ops on human's turn, drives a full game to GAME_OVER with stats recorded `isAIGame=false`; restart path restores bot metadata via `loadGame`.
- **PlayerStatsService/FriendService additions**: leaderboard and search exclude a seeded bot; friend request to a bot rejected.

## Verification (manual, end-to-end)

1. Local Postgres + `./gradlew bootRun` with `cribbage.bots.wait-seconds=10`; check Flyway applies V12 and 16 bot users/stats rows exist.
2. Quick-match (RAPID) from the mobile app, stay on the screen → "Game Found" within ~10–20 s vs a human-named opponent; confirm no `ai_` id or "AI Opponent" anywhere in WS payloads.
3. Play a full game: discards arrive as two separate delayed updates, pegging replies take 1.5–4.5 s, the bot's clock visibly runs, game ends, rating moves, `/api/profiles/{botId}` looks human.
4. BLITZ game: bot never times out. Kill and restart the server mid-bot-turn: move resumes within ~10 s (self-healing sweep + `loadGame`).
5. Two humans queueing simultaneously still match each other (bots only enter after the wait). Leaderboard and friend search show no bots.

## Risks / gotchas

- The one hard invariant: bot games must never populate `CachedGame.aiPlayerId`, or `applyHumanAction` drives the bot instantly and synchronously.
- Bot is on the clock while "thinking" — delay cap keeps the bank safe; clamp `maxDelayFractionOfTurnLimit ≤ 1.0` at load.
- If the driver fails entirely, the timeout sweep forfeits the bot — the human wins a rated game (acceptable failure mode; test it).
- Single-node assumption (in-memory `pending` map, engine cache) — inherited from the existing architecture; note in class KDoc.
