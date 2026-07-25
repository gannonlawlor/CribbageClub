# Achievements — Fullstack Plan

## Context

Cribbage Club has no achievements today. We want ~25 achievements spanning trivial ("win a game") to hard ("skunk the hard AI", "score a 29 hand"). The server is the source of truth so achievements follow the account to any client, they render on player profiles, and the mobile app mirrors unlocks to iOS Game Center and Google Play Games. Decisions confirmed with the user: **no retroactive backfill** (counters start at feature launch), **mobile UI only** (API makes web trivial later), **show progress** toward locked counter achievements.

Key facts from exploration:
- Game-over funnels through `GameService.applyStateToEntity` (~line 680, checks `GameStage.GAME_OVER`, calls `playerStatsService.recordGameResult`). Other completion paths: `ForfeitService.forfeitGame` and `GameService.importLocalGames` (~line 481) — imported local games carry full `history` in stateJson, so offline feats unlock on import.
- Per-hand data lives in `GameState.history` (`HandCounted.totalPoints`, `CardPlayed(newCount, pointsScored)`, `DeckCut.dealerScoredNobs`, `CribCounted`, `GoAnnounced`, `RoundStarted`, `GameEnded`, `GameForfeited`) — everything needed for 29-hand, pegging, comeback, and skunk detection.
- AI games: `GameEntity.isAIGame` + `aiDifficulty` ∈ {basic, medium, hard}; AI ids prefixed `ai_`, guests `guest_`. Skunk = loserScore < 91, double < 61.
- Notification pattern to mirror: `NotificationWebSocketService` typed DTOs → `/user/queue/notifications`; `PushNotificationService.sendIfOffline` for FCM. (Mobile does NOT subscribe to `/user/queue/notifications` today — mobile uses fetch-and-diff instead, below.)
- Latest Flyway migration is V11 → new one is **V12**. Once-per-user pattern: `puzzle_solves` `UNIQUE(puzzle_id, user_id)`.
- Mobile has no games_services plugin, no `Runner.entitlements`, no Play Games config. Firebase core+messaging already set up. No app-wide banner system (only snackbars + `CcDialog`).
- Guest upgrade keeps the same user id, so guest-earned achievements survive upgrade.

## Achievement Catalog (25)

Tiers BRONZE/SILVER/GOLD. `Target` = counter achievement with progress display. Counters count **post-launch only** (tracked in `achievement_progress`, not lifetime `player_stats` — lifetime stats would silently backfill veterans).

| # | Key | Name | Trigger | Tier | Target |
|---|-----|------|---------|------|--------|
| 1 | FIRST_GAME | Welcome to the Club | Finish a game | BRONZE | – |
| 2 | FIRST_WIN | On the Board | Win a game | BRONZE | – |
| 3 | WINS_10 | Regular | Win 10 games (post-launch counter) | BRONZE | 10 |
| 4 | WINS_50 | Club Veteran | Win 50 games | SILVER | 50 |
| 5 | WINS_100 | Centurion | Win 100 games | GOLD | 100 |
| 6 | STREAK_5 | Hot Streak | Win 5 in a row (post-launch streak counter) | SILVER | 5 |
| 7 | STREAK_10 | Unstoppable | Win 10 in a row | GOLD | 10 |
| 8 | BEAT_AI_MEDIUM | Worthy Opponent | Beat medium AI | BRONZE | – |
| 9 | BEAT_AI_HARD | Machine Breaker | Beat hard AI | SILVER | – |
| 10 | SKUNK | Skunked! | Win with opponent < 91 (not forfeit) | SILVER | – |
| 11 | DOUBLE_SKUNK | Double Skunk | Win with opponent < 61 (not forfeit) | GOLD | – |
| 12 | SKUNK_AI_HARD | Humbled the Machine | Skunk the hard AI (not forfeit) | GOLD | – |
| 13 | COMEBACK | The Comeback | Win after trailing by ≥30 (history replay, not forfeit) | GOLD | – |
| 14 | HAND_20 | Twenty Club | Count a hand ≥ 20 | SILVER | – |
| 15 | HAND_24 | Twenty-Four Karat | Count a hand ≥ 24 | GOLD | – |
| 16 | HAND_29 | The Perfect Hand | Count the 29 hand | GOLD | – |
| 17 | CRIB_12 | Golden Crib | Count a crib ≥ 12 | SILVER | – |
| 18 | HIS_HEELS | His Heels | As dealer, score 2 for a cut jack (`DeckCut.dealerScoredNobs && cuttingPlayerId != user`) | BRONZE | – |
| 19 | PEG_31 | Thirty-One | Bring the count to exactly 31 | BRONZE | – |
| 20 | PEG_12_ROUND | Pegging Machine | 12+ pegging points in one round (sum CardPlayed+GoAnnounced per round) | GOLD | – |
| 21 | FIRST_ONLINE_WIN | People Person | Win vs a human | BRONZE | – |
| 22 | RATING_1600 | Sixteen Hundred | Rating ≥ 1600 after a rated game | GOLD | – |
| 23 | FRIEND_ADDED | Making Friends | Friend request accepted (both parties) | BRONZE | – |
| 24 | PUZZLE_FIRST | Daily Habit | Solve a daily puzzle | BRONZE | – |
| 25 | PUZZLE_OPTIMAL_10 | Optimizer | 10 optimal puzzle solves (post-launch counter) | SILVER | 10 |

Rules: never award `ai_` ids; guests earn normally. Forfeited games count for win/streak counters (consistent with `recordGameResult`) and for history feats that actually happened, but are excluded from SKUNK/DOUBLE_SKUNK/SKUNK_AI_HARD/COMEBACK (forfeit forces winner to 121, making skunks farmable). Evaluate both humans in online games; only the human in AI games; only the importing user for imports.

## Phase 1 — Backend (independently shippable)

Package root: `src/main/kotlin/com/jackabee/cribbageclubserver/`

**New: `src/main/resources/db/migration/V12__achievements.sql`**
```sql
CREATE TABLE player_achievements (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id),
    achievement_key VARCHAR(64) NOT NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE NOT NULL,
    game_id VARCHAR(255),
    CONSTRAINT uq_user_achievement UNIQUE (user_id, achievement_key)
);
CREATE INDEX idx_player_achievements_user ON player_achievements(user_id);

CREATE TABLE achievement_progress (   -- post-launch counters (fresh-start decision)
    user_id VARCHAR(255) PRIMARY KEY REFERENCES users(id),
    wins INT NOT NULL DEFAULT 0,
    current_win_streak INT NOT NULL DEFAULT 0,
    optimal_puzzle_solves INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    version BIGINT NOT NULL DEFAULT 0
);
```
Catalog is **code, not a table** (adding achievements = deploy, no migration).

**New files:**
- `model/achievement/Achievement.kt` — `enum class AchievementTier { BRONZE, SILVER, GOLD }` + `enum class Achievement(displayName, description, tier, target: Int? = null)` with all 25 (ordinal = sortOrder).
- `entity/PlayerAchievementEntity.kt`, `entity/AchievementProgressEntity.kt` — follow `PuzzleSolveEntity`/`PlayerStatsEntity` patterns (String id, `Instant`, `@Version` on progress).
- `repository/PlayerAchievementRepository.kt` (`findByUserId`, `findByUserIdAndAchievementKeyIn`), `repository/AchievementProgressRepository.kt`.
- `service/AchievementHistoryEvaluator.kt` — pure functions `(userId, GameState) -> Set<Achievement>`: HAND_20/24/29, CRIB_12, HIS_HEELS, PEG_31; PEG_12_ROUND (fold history, per-player accumulator reset at `RoundStarted`); COMEBACK (replay running scores from CardPlayed/GoAnnounced/HandCounted/CribCounted/DeckCut-nobs, award if winner's max deficit ≥ 30 and no `GameForfeited`).
- `service/AchievementService.kt` — depends only on repos, `PlayerStatsService`, `NotificationWebSocketService`, `PushNotificationService` (no circular deps):
  - `@Transactional award(userId, keys, gameId?)`: skip `ai_`/empty; insert missing rows, catching `DataIntegrityViolationException` per-row (unique constraint = concurrency backstop, mirrors puzzle_solves); returns newly awarded. Notify **after commit** via `TransactionSynchronizationManager` (forfeit/puzzle callers are `@Transactional`; `applyHumanAction` isn't) → WS DTO + `pushNotificationService.sendIfOffline(..., data = {"type": "ACHIEVEMENT_UNLOCKED", ...})`.
  - `evaluateGameEnd(entity, finalState)`: upsert `achievement_progress` (increment wins/streak per player), then check counters (WINS_*, STREAK_* from progress row), outcome checks (FIRST_GAME/FIRST_WIN/BEAT_AI_*/SKUNK*/FIRST_ONLINE_WIN/RATING_1600 — rating from `playerStatsService.getStats`), history checks via evaluator; `award(...)` per human player. Returns awarded list (import path uses it).
  - `evaluatePuzzleSolve(userId, isOptimal)`: PUZZLE_FIRST always; increment `optimal_puzzle_solves` when optimal → PUZZLE_OPTIMAL_10.
  - `evaluateFriendAccepted(a, b)`: FRIEND_ADDED both.
  - `getAchievementsFor(userId)`: merge catalog + earned rows + progress (from `achievement_progress`). No backfill.

**Modified files (hook points):**
- `service/GameService.kt` — after `recordGameResult` in the GAME_OVER branch of `applyStateToEntity` (~line 680): `achievementService?.evaluateGameEnd(entity, state)` (use the existing `@Autowired(required = false)` optional-dep style). In `importLocalGames` (~line 481): same call wrapped in try/catch so evaluation never fails the import loop; collect awarded list into response.
- `service/ForfeitService.kt` — after `recordGameResult` (~line 92): `evaluateGameEnd(entity, terminalState)`.
- `service/PuzzleService.kt` — end of `solvePuzzle`: `evaluatePuzzleSolve(...)`; add `unlockedAchievements` to `PuzzleSolveResponse`.
- `service/FriendService.kt` — in `acceptFriendRequest` after save (~line 130): `evaluateFriendAccepted(...)`.
- `controller/GameController.kt` — add `unlockedAchievements: List<AchievementDto> = emptyList()` to `ImportGamesResponse`.
- `websocket/NotificationWebSocketService.kt` — add `AchievementUnlockedNotification(type = "ACHIEVEMENT_UNLOCKED", achievements: List<AchievementSummary>, timestamp)` + sender, following existing DTO pattern.
- `SecurityConfig` — register new endpoints mirroring how `/api/profiles/**` is matched.

**New: `controller/AchievementController.kt`**
- `GET /api/achievements` — catalog (key, name, description, tier, target, sortOrder).
- `GET /api/profiles/{userId}/achievements` — merged view:
```json
{ "achievements": [ { "key": "WINS_50", "name": "Club Veteran", "description": "...",
    "tier": "SILVER", "target": 50, "progress": 23, "unlocked": false, "unlockedAt": null } ],
  "unlockedCount": 7, "totalCount": 25 }
```
This single endpoint makes later web display trivial.

## Phase 2 — Mobile in-app (Flutter, `mobile/`)

**Mechanism: fetch-and-diff**, not WebSocket (client doesn't subscribe to `/user/queue/notifications` today). At key moments the client fetches `GET /api/profiles/{me}/achievements`, diffs earned keys against a per-user "celebrated" set in SharedPreferences, banners the new ones, and re-pushes all earned to Game Center/Play Games (idempotent = reconciliation). Handles online unlocks, offline-earned-then-imported unlocks, and multi-device catch-up with one code path. Instant WS banners are a deferred nicety (Phase 4).

**New files:**
- `lib/core/models/achievement.dart` — freezed `AchievementStatus` (key, name, description, tier enum `@JsonValue('BRONZE')`…, target, progress, unlocked, unlockedAt) + `AchievementsResponse`; run `dart run build_runner build`.
- `lib/core/services/achievement_service.dart` — `AchievementSyncService.sync()`: fetch → diff vs `celebrated_achievements_<userId>` → persist union → enqueue banners → mirror all unlocked to platform. Plus `achievementsProvider` (FutureProvider for profile UI) and a family provider for other-player profiles.
- `lib/core/services/platform_achievements.dart` — `games_services` wrapper: `signIn()` (swallow/log failures; signed-out users just don't mirror), `unlock(key)` via `const Map<String, ({String ios, String android})> platformAchievementIds` covering all 25 keys. All platform achievements configured **standard/binary** (skip Play Games incremental — in-app UI already shows progress; avoids increment drift). Guard `Platform.isIOS || Platform.isAndroid`.
- `lib/shared/widgets/achievement_banner.dart` — top slide-down overlay banner (trophy, name, description), auto-dismiss ~3.5s, sequential queue via `StateNotifierProvider`. Host app-wide via `MaterialApp.router` `builder:` Stack in `lib/app.dart`. Style per `lib/config/theme.dart`.
- `lib/features/profile/widgets/achievements_section.dart` — shared section: `unlockedCount/25` header + tile grid (unlocked = tier-colored icon; locked = greyed + lock; counters = progress bar `progress/target`).

**Modified files:**
- `pubspec.yaml` — add `games_services`.
- `lib/core/api/rest_client.dart` — `getAchievements(userId)`, `getAchievementCatalog()`; extend `lib/core/models/import_games.dart` and puzzle response model with `unlockedAchievements`.
- `lib/features/game/screens/game_screen.dart` — local-game game-over microtask (~line 196): after `uploadSingleGame` succeeds, `sync()` (alongside existing `ref.invalidate(myProfileProvider)`). Online games: one-shot `sync()` when `gameOver` first observed for a non-local game (reuse the "already handled this gameId" guard pattern).
- Daily puzzle result handling — banner from `PuzzleSolveResponse.unlockedAchievements` (or just `sync()`).
- Friends accept handler — `sync()` after accept.
- `lib/core/services/auth_game_sync_provider.dart` — post-login, after `uploadAllLocalGames`: `platformAchievements.signIn()` then `sync()`.
- `lib/core/services/push_notification_service.dart` — `case 'ACHIEVEMENT_UNLOCKED':` → route to `/me` (~line 85).
- `lib/features/profile/screens/my_profile_screen.dart` + `profile_screen.dart` — add the shared achievements section.

## Phase 3 — Platform config (repo + console work)

iOS:
- New `mobile/ios/Runner/Runner.entitlements` with `com.apple.developer.game-center` = true; set `CODE_SIGN_ENTITLEMENTS` in all configs of `Runner.xcodeproj/project.pbxproj` (or Xcode → Signing & Capabilities → + Game Center). Enable Game Center on the App ID in the developer portal.
- App Store Connect → Game Center: create 25 achievements, IDs `cc_first_game` … `cc_puzzle_optimal_10` (point budget ≤ 1000, e.g. 10 bronze / 25 silver / 50 gold), 512×512 art each.

Android:
- Play Console → Play Games Services setup (use the existing Firebase project used for FCM): create game, add 25 achievements, note IDs + APP_ID; add release + debug SHA-1 OAuth credentials.
- New `mobile/android/app/src/main/res/values/games-ids.xml` (paste console-generated resources).
- `mobile/android/app/src/main/AndroidManifest.xml` — `<meta-data android:name="com.google.android.gms.games.APP_ID" android:value="@string/app_id"/>` inside `<application>`.

Multi-account note: platform identity is per-device and separate from the app account; two app accounts on one device both push to the same platform profile — accepted (platform unlocks are idempotent/monotonic).

## Phase 4 — Deferred
- STOMP subscription to `/user/queue/notifications` in `lib/core/api/websocket_client.dart` for instant banners when the opponent's move ends the game.
- Web profile achievements section (API already returns everything).
- Optional admin backfill job scanning `games.state_json` (explicitly out of scope per user decision).

## Verification

Backend (`./gradlew test`, H2 + Mockito per existing test patterns):
- `AchievementHistoryEvaluatorTest`: 29-hand, crib-12, HIS_HEELS dealer-vs-cutter, PEG_31, pegging round 12 vs 11, comeback deficit 30 vs 29, forfeit excludes SKUNK/COMEBACK.
- `AchievementServiceTest`: idempotent double-award, unique-constraint race path, `ai_` filtered, guest awarded, progress counters increment post-launch only, after-commit notification (mocked WS service), progress mapping in `getAchievementsFor`.
- Hook tests: game driven to GAME_OVER awards FIRST_GAME to both humans; `importLocalGames` with a 20-point `HandCounted` in stateJson awards HAND_20 and returns it in the response; forfeit winner gets win counters but never SKUNK.
- `AchievementControllerTest`: response shapes, auth.

Mobile (`mobile/scripts/test.sh` = analyze + test):
- Unit: sync diff (new unlock → banner queued + celebrated persisted; second sync → silent), platform ID map keys == all 25 catalog keys.
- Widget: banner queue sequencing/auto-dismiss; achievements section locked/unlocked/progress states.
- Manual: win a local AI game against dev backend → banner + profile section updates; airplane-mode game with big hand → login → import → banner; iOS sandbox Game Center account (unlock toast + listing); Android internal tester; signed-out-of-Game-Center run (no crash, server achievements still shown); guest → play → upgrade → achievements retained.
