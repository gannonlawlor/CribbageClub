# Play While You Wait — Quick-Match Technical Plan

## Context

Quick-match today traps the user on `LobbyWaitingScreen` (mobile/lib/features/lobby/screens/lobby_waiting_screen.dart): the search is local widget state, a 3-second REST poll of `GET /api/lobbies/{id}`, and both the back button and swipe-back call `POST /api/lobbies/{id}/leave` — leaving the screen means leaving the queue. Nothing on the client subscribes to `/user/queue/notifications`, so the server's STOMP `GameFoundNotification` (websocket/NotificationWebSocketService.kt) is sent into the void; the poll is what actually navigates to the game. There is no foreground FCM handler, no local-notification support, and iOS has no push entitlement at all.

**Goal:** while searching, the user can navigate anywhere in the app (daily/practice puzzle, local bot game) or background the app, and still reliably learn when the match is found — in-app banner when foregrounded, notification when backgrounded. Per confirmed product decision, bot-fallback matchmaking also pairs backgrounded/offline users and notifies them via push ("you always get a game").

**Verified facts that shape the design:**

- The mobile app initiates STOMP **only** from `GameNotifier` (mobile/lib/features/game/state/game_providers.dart:133-157). A fresh-session quick-matcher has no WS session → `WebSocketSessionRegistry.isUserOnline()` is false → the bot sweep skips them today and `sendIfOffline` pushes to a foregrounded user. Connecting the socket at search start fixes an existing bug, not just enables the feature.
- `WebSocketClient` (mobile/lib/core/api/websocket_client.dart) has reconnection + resubscribe machinery and a `_pendingSubscriptions` map keyed by string — a `'user-notifications'` subscription slots in beside `'user-state'`/`'user-errors'`. It has **no intentional-disconnect method**; `_handleDisconnect` early-returns when `_status == disconnected`, so adding one is safe.
- `AchievementBannerHost` mounted in `MaterialApp.builder`'s Stack (mobile/lib/app.dart:71-76) is the proven pattern for a router-surviving overlay; the matchmaking chip/banner host mirrors it.
- All GAME_FOUND senders funnel through `LobbyService.notifyGameFound` (LobbyService.kt:356) — one server choke point already carrying `data = {type: GAME_FOUND, gameId}` on the push.
- `PushNotificationService.sendIfOffline` (service/PushNotificationService.kt:23) already implements the "FCM only when no live socket" rule; no change needed there.
- `Lobby` model already serializes `isQuickMatch` and `createdAt` to the client (model/lobby/Lobby.kt); `LobbyEntity.playersJson` means "find my lobby" must scan-and-parse (cheap: WAITING lobbies are few; `BotMatchmakingService.fillLobby` already does exactly this).
- `CleanupService` (service/CleanupService.kt) deletes lobbies with `updatedAt` older than 15 min (`lobby.timeout.inactive-minutes`), WAITING and IN_GAME alike; `GET /lobbies/{id}` does not touch `updatedAt`.
- Mobile push tap-routing for GAME_FOUND → `/game/{gameId}` already works for background-tap and cold-start (mobile/lib/core/services/push_notification_service.dart:86-103). Missing: `FirebaseMessaging.onMessage` (foreground) and any local-notification display.
- iOS has **no** `aps-environment` entitlement (mobile/ios/Runner/Runner.entitlements has only game-center), no `GoogleService-Info.plist` in Runner, no `UIBackgroundModes`. Android has no `google-services.json` in-repo (`firebase_availability.dart` degrades to "no push"). Push works today only if these are provisioned out-of-band — Phase 3 makes the required config explicit.
- Tests: `BotMatchmakingServiceTest.kt`, `CleanupServiceTest.kt`, `LobbyControllerTest.kt`, `LobbyServiceTest.kt` all exist and need updates.

**Coordination note:** the notification-center plan (plans/notification-center.md) also adds a `/user/queue/notifications` subscription and generalizes the banner host. Whichever plan lands second builds on the first's subscription and dispatch; the notification center's `NotificationBannerHost` supersedes any matchmaking-only banner styling.

**Key UX decisions (made here, not during implementation):**

- Back/swipe-back from the quick-match waiting screen **keeps searching** (pops to home; a persistent chip appears). Only the explicit button — relabeled "Cancel search" — leaves the queue. Private/invite lobbies keep today's leave-on-back behavior.
- Global overlay: a pinned bottom chip ("Finding a game · 0:42" + cancel affordance) on every route while searching, except the waiting screen itself and the found game's own screen. When the match is found and the user is anywhere other than the waiting screen, the chip becomes a "Match found — {opponent}" banner with a **Join** action; it never force-navigates (protects mid-hand local games and mid-solve puzzles). On the waiting screen, auto-navigation is preserved.
- On app **pause**, the client proactively disconnects STOMP (recommended over relying on iOS's nondeterministic socket suspension — see Phase 2 §2.6 rationale). FCM is then the sole backgrounded channel; a local notification covers only the sub-second race where GAME_FOUND arrives between pause and disconnect.

## Phase 1 — Backend

### 1.1 Relax the bot-fallback online gate (`BotMatchmakingService.kt`)

`src/main/kotlin/com/jackabee/cribbageclubserver/service/BotMatchmakingService.kt:82` — replace:

```kotlin
if (!sessionRegistry.isUserOnline(waiter.id)) return
```

with a reachability gate: fill if `sessionRegistry.isUserOnline(waiter.id) || deviceTokenService.hasTokensForUser(waiter.id)`. Add `DeviceTokenService` as a constructor dependency and update the KDoc comment (lines 79-81) — the rationale becomes "match anyone we can *reach*; a user with no socket and no push tokens would never learn the game started and would eat a rated timeout loss, so leave them for the cleanup sweep."

- New `DeviceTokenService.hasTokensForUser(userId: String): Boolean` — back it with a `DeviceTokenRepository.existsByUserId(userId)` derived query rather than loading token rows.
- When the fill proceeds, `joinLobbyById` → `notifyGameFound` → `sendIfOffline` fires FCM because the waiter has no socket. No new notification code needed.
- **Accepted trade-off** (flag in code comment): a push-notified user's clock starts at game creation. Max staleness is bounded — `wait-seconds` (60) + sweep interval (10s) after the search began — and quick-match defaults to RAPID with a time bank, so the push arrives while the bank is intact. A clock grace period for unclaimed games is Phase 4.

### 1.2 Cleanup interplay: don't sweep an actively-watched search (`LobbyService.kt`)

`LobbyService.removeInactiveLobbies` (LobbyService.kt:262): before deleting a `WAITING` quick-match lobby, check whether any player in it is WS-online (`WebSocketSessionRegistry` — add as a `LobbyService` constructor dep, or pass a predicate from `CleanupService`). If online, `touch` the entity (`updatedAt = now`, save) instead of deleting. Effect:

- A foregrounded searcher (who now holds a socket, per Phase 2) can never have their queue swept out from under them, even if bots are disabled or the bot pool is exhausted.
- A **backgrounded** searcher's lobby still expires after 15 min if bots never filled it (i.e., they have no device tokens, per 1.1) — correct: unreachable searches should die. The client shows "search expired" on return (Phase 2 §2.8).
- No config change needed; `lobby.timeout.inactive-minutes=15` stays.

### 1.3 New endpoint: restore my quick-match search — `GET /api/lobbies/quick-match/mine`

`LobbyController.kt`: add

```kotlin
@Operation(summary = "Get the caller's current quick-match lobby, if any")
@GetMapping("/quick-match/mine")
fun getMyQuickMatch(@RequestAttribute("userId") userId: String): ResponseEntity<Lobby>
```

returning `200 Lobby` or `404`. `LobbyService.findQuickMatchLobbyForUser(userId)`: scan `findByStatusAndIsPrivateFalseAndChallengedUserIdIsNull(WAITING)` plus the same query for `IN_GAME` status, filter `isQuickMatch && players.any { it.id == userId }`, prefer `IN_GAME` (a found-but-unjoined game) over `WAITING`, newest `createdAt` wins. The path is two literal segments so there is no ambiguity with `/{lobbyId}`; already covered by the `/api/**` authenticated matcher.

Why both statuses: the resume flow (Phase 2 §2.8) needs to distinguish "still searching" (WAITING → re-show chip) from "your game started while you were away and you missed/dismissed the push" (IN_GAME + `gameId` → show Match-found banner).

### 1.4 Tests

- `BotMatchmakingServiceTest.kt`: waiter offline + has tokens → filled; waiter offline + no tokens → skipped; waiter online → filled (existing).
- `LobbyServiceTest.kt` / `CleanupServiceTest.kt`: WAITING quick-match lobby with online waiter survives sweep with bumped `updatedAt`; offline waiter's lobby still deleted; IN_GAME lobbies unaffected.
- `LobbyControllerTest.kt`: `quick-match/mine` — 404 when none, WAITING body, IN_GAME preferred over WAITING.

## Phase 2 — Mobile

### 2.1 `WebSocketClient` additions (`mobile/lib/core/api/websocket_client.dart`)

- `subscribeToNotifications({required void Function(Map<String, dynamic>) onNotification})` — destination `/user/queue/notifications`, key `'user-notifications'`, registered in `_pendingSubscriptions` so it survives reconnects, exactly mirroring `subscribeToErrors`. Decode JSON and hand the raw map up; dispatch on `json['type']` happens in the listener service (the queue is shared with FRIEND_REQUEST, CHALLENGE_*, ACHIEVEMENT_UNLOCKED — don't bake GAME_FOUND-only parsing into the transport).
- `disconnect()` — intentional teardown: `_reconnectTimer?.cancel()`, `_setStatus(ConnectionStatus.disconnected)` **before** `_stompClient?.deactivate()` so `_handleDisconnect`'s early-return suppresses reconnection. Keep `_pendingSubscriptions` intact so `reconnectIfNeeded()` restores everything on resume.
- `connectIfNeeded()` — thin wrapper so non-game callers can bring the socket up: if never connected, `connect(onConnect: (){}, onError: (_){})`; else `reconnectIfNeeded()`. (Today `reconnectIfNeeded` no-ops when `_onConnectCallback == null`, i.e. before any game. This wrapper is what the matchmaking notifier calls.)

### 2.2 Message model (`mobile/lib/core/models/websocket_messages.dart`)

Add a freezed `GameFoundMessage { required String gameId, required String opponentName, int? timestamp }` matching `GameFoundNotification` (NotificationWebSocketService.kt). Regenerate with `mobile/scripts/codegen.sh`.

### 2.3 Global matchmaking state — `mobile/lib/features/lobby/state/matchmaking_provider.dart` (new)

Manual Riverpod (no codegen), app-lifetime (not autoDispose):

```dart
enum MatchmakingStatus { idle, searching, found, expired }

class MatchmakingState {
  final MatchmakingStatus status;
  final String? lobbyId;
  final String? gameId;        // set when found
  final String? opponentName;
  final DateTime? startedAt;   // for the elapsed timer on the chip
}

final matchmakingProvider =
    StateNotifierProvider<MatchmakingNotifier, MatchmakingState>(...);
```

`MatchmakingNotifier` (deps: `restClientProvider`, `webSocketClientProvider`):

- `start({String? timeControl})` — calls `restClient.quickMatch()`. If the result has `gameState` (instant human match) → set `found` immediately. Else set `searching(lobbyId, startedAt: now)`, start the 3s `Timer.periodic` poll (moved here from the waiting screen), call `wsClient.connectIfNeeded()` and `subscribeToNotifications(...)` routing `type == 'GAME_FOUND'` to `_onGameFound`. Connecting here is what makes the server's `isUserOnline` true — required for the bot sweep to see the waiter and for `sendIfOffline` to correctly *skip* push while foregrounded.
- `_poll()` — `GET /api/lobbies/{lobbyId}`; `status == inGame && gameId != null` → `_onGameFound(gameId, opponentName from lobby players)`; 404 → `_expire()`. Poll and STOMP are redundant on purpose (poll is the SimpleBroker-has-no-replay safety net); `_onGameFound` is idempotent — ignore if already `found` with the same `gameId`.
- `_onGameFound(gameId, opponentName)` — cancel poll, set `found`. If app lifecycle is not `resumed` (see §2.6 race), ask `LocalNotificationService` to fire. Navigation is **not** done here; hosts react (§2.4/§2.5).
- `cancel()` — `POST /api/lobbies/{id}/leave` (best-effort), cancel poll, `idle`.
- `clear()` — `idle` without leaving (used after Join, or dismissing found/expired banners).
- `restore()` — `GET /api/lobbies/quick-match/mine`: WAITING → re-enter `searching` (recompute `startedAt` from `lobby.createdAt`); IN_GAME+gameId → `found` (no-op to `clear()` if the current route is already that game); 404 → if previously `searching`, `_expire()`, else stay idle.
- Listen to `authProvider` (same pattern as `pushNotificationSyncProvider`): logout while searching → `cancel()`.

### 2.4 Overlay host — `mobile/lib/features/lobby/widgets/matchmaking_overlay.dart` (new)

`MatchmakingOverlayHost`, mounted in `app.dart`'s `MaterialApp.builder` Stack next to `AchievementBannerHost`. Watches `matchmakingProvider` and the current location (via `routerProvider`'s listenable):

- Hidden when: `idle`; on `/lobby/{state.lobbyId}` (the waiting screen is the full-size view); on `/game/{state.gameId}` (already in the found game). **Visible over local games** (`/game/local_*`), puzzles, and any other route.
- `searching` → bottom-pinned chip (safe-area aware): spinner + "Finding a game · m:ss" (ticker from `startedAt`) + an X that calls `cancel()`. Tapping the chip body → `context.push('/lobby/{lobbyId}')`.
- `found` → banner: "Match found — {opponentName}" with **Join** (`router.go('/game/{gameId}')` then `clear()`) and a dismiss X (`clear()` only — pair the dismiss with copy like "Game started — your clock is running" to be honest about consequences). Never auto-navigates.
- `expired` → one-shot banner "Search expired" with **Search again** (`start()`) and dismiss (`clear()`).
- Style on `AchievementBannerHost`'s visual language (surfaceChrome, borderStrong, 12px radius).

### 2.5 Screen refactors

- **`lobby_waiting_screen.dart`**: for quick-match lobbies (`lobby.isQuickMatch == true`, or entered via `matchmakingProvider.lobbyId`), delete the local `_pollTimer`/`_fetchLobby` and render from `ref.watch(matchmakingProvider)` + a one-time `getLobby` fetch for display data. `CcSwipeBack.onBack` and header back → plain `context.backOrHome()` (search continues; chip appears). The red button relabels to "Cancel search" → `notifier.cancel()` then pop. `ref.listen(matchmakingProvider)`: on `found` while this screen is topmost → `context.pushReplacement('/game/{gameId}')` + `clear()` (preserves today's auto-join); on `expired` → show the existing `CcMessage` error UI ("This search expired"). **Private/invite lobbies keep the file's current standalone behavior unchanged** — branch on `isPrivate`/`inviteCode`.
- **`home_screen.dart` `_quickMatch`**: replace the direct `restClient.quickMatch()` with `ref.read(matchmakingProvider.notifier).start()`, then navigate: `found` → `/game/{gameId}`, `searching` → `/lobby/{lobbyId}`. If already `searching`, just `context.push('/lobby/{lobbyId}')` (no duplicate queue entry — server would reject "Player already in lobby" anyway).

### 2.6 Lifecycle: proactive STOMP disconnect on pause (`mobile/lib/app.dart`)

Extend `didChangeAppLifecycleState`:

```dart
if (state == AppLifecycleState.paused) {
  ref.read(webSocketClientProvider).disconnect();
}
if (state == AppLifecycleState.resumed) {
  ref.read(webSocketClientProvider).reconnectIfNeeded();
  ref.read(matchmakingProvider.notifier).restore();
}
```

**Recommendation and rationale — disconnect proactively, don't rely on natural socket drop.** On iOS the suspended socket can look alive to the server for tens of seconds to minutes; during that window `sendIfOffline` skips FCM and the STOMP frame lands in a suspended process — the user learns nothing while their clock runs. An explicit disconnect on `paused` makes the server's presence view flip to offline within one frame, so the push path is deterministic. `paused` fires reliably before iOS suspends the Dart isolate; `inactive` (app-switcher peek, notification shade) deliberately does **not** disconnect. Cost: socket churn on brief app switches — acceptable because `reconnectIfNeeded` + `_resubscribeAll` already restore state cheaply, and in-game reconnects already trigger a state re-fetch. Active online games use REST for actions, so disconnect only affects notification freshness.

Track lifecycle in a tiny `appLifecycleProvider` (`StateProvider<AppLifecycleState>`) updated in the same observer so `MatchmakingNotifier._onGameFound` can check foreground/background without a BuildContext.

### 2.7 Notification channels: local + FCM foreground

- Add **`flutter_local_notifications`** to `mobile/pubspec.yaml`. New `mobile/lib/core/services/local_notification_service.dart` (+ manual provider): initialize once at startup (Android channel id `match_found`, name "Match found"; FCM's `requestPermission()` already covers iOS alert permission); `showMatchFound(gameId, opponentName)`; tap callback (`onDidReceiveNotificationResponse`) parses payload `game:{gameId}` → `routerGetter().go('/game/$gameId')` (same getter-injection pattern as `PushNotificationService`).
- Its only trigger is the pause-race: `_onGameFound` fires it when `appLifecycleProvider` is not `resumed` — i.e., GAME_FOUND arrived over a socket that outlived `paused` (Android background, or the sub-second iOS window before `disconnect()` completes). With §2.6 in place this is rare but is exactly the "backgrounded with socket alive" case.
- **FCM foreground handler**: in `push_notification_service.dart.initialize()`, add `FirebaseMessaging.onMessage.listen(_handleForegroundMessage)`; for `type == GAME_FOUND` invoke an `onGameFound` callback injected from `pushNotificationServiceProvider` (keeps the service router-only) that forwards to `matchmakingProvider`. This covers a foregrounded user whose socket dropped (flaky network) where the server correctly sent FCM: they get the in-app banner instead of silence.
- Dedupe is inherent: all three paths (STOMP, poll, FCM-foreground) converge on the idempotent `_onGameFound`; the OS-notification paths (FCM background tap, local-notification tap) route straight to `/game/{id}`, and `restore()`/route-awareness clears leftover chip state.

### 2.8 Restore flows

- **Cold start from push tap**: `getInitialMessage()` → `/game/{id}` — already works, unchanged.
- **Manual reopen while still queued**: `resumed` → `restore()` → WAITING → chip reappears, poll restarts, socket reconnects.
- **Manual reopen after match found (push missed/dismissed)**: `restore()` → IN_GAME → found banner "Match found — {name} · Join".
- **Manual reopen after lobby swept**: previous state `searching` + 404 → expired banner.
- Also call `restore()` once at app startup post-login (piggyback on the auth-transition listener in §2.3) for cold starts not initiated by a push.

### 2.9 Mobile tests

- `MatchmakingNotifier` unit tests (mock RestClient/WebSocketClient): start→searching, instant-match→found, poll IN_GAME→found, poll 404→expired, cancel leaves lobby, `_onGameFound` idempotency, restore matrix (WAITING/IN_GAME/404).
- Widget test: overlay hidden on `/lobby/{id}`, visible chip on `/`, found banner Join navigates.
- Update any existing `lobby_waiting_screen` tests for the quick-match/private branch.

## Phase 3 — Platform config

Without these, the push leg silently does nothing on iOS (the repo builds "no-push" by design — `firebase_availability.dart`).

1. **iOS entitlements** — `mobile/ios/Runner/Runner.entitlements`: add `aps-environment` = `development` (Xcode swaps to `production` at archive/TestFlight). Enable the Push Notifications capability in `Runner.xcodeproj`.
2. **iOS Info.plist** — add `UIBackgroundModes` with `remote-notification` (lets FCM data payloads wake the app; the GAME_FOUND push is notification+data so tap-routing works regardless, but this future-proofs silent updates).
3. **APNs key in Firebase** — upload the APNs auth key (.p8) to the Firebase project's iOS app config (console step, not repo). Without it FCM→iOS delivery fails silently.
4. **Firebase config files** — `mobile/ios/Runner/GoogleService-Info.plist` and `mobile/android/app/google-services.json` are intentionally not in the repo; document in `mobile/CLAUDE.md` that push QA requires dropping them in, and that `initializeFirebase()` degrades gracefully without them.
5. **Android 13+ notification permission** — `firebase_messaging`'s `requestPermission()` already triggers the POST_NOTIFICATIONS runtime prompt; verify `flutter_local_notifications` setup (small icon resource, channel created at init) on Android.
6. **Server**: no new config keys required. Existing: `cribbage.bots.wait-seconds`, `cribbage.bots.match-sweep-interval-ms`, `lobby.timeout.inactive-minutes` unchanged.

## Phase 4 — Deferred

- **Clock grace for push-claimed games**: pause/extend the first turn clock until the notified player first fetches game state, so a bot match claimed 60s after the push isn't half-forfeited. Touches timer/game services — meaningful scope, and RAPID's time bank makes it tolerable at current stakes.
- **"Search expired" push**: when `removeInactiveLobbies` sweeps a quick-match lobby whose waiter has device tokens, `sendIfOffline("Still want a game?", ...)`. Nice re-engagement hook, not core.
- **Generalize the notification listener**: route CHALLENGE_RECEIVED / FRIEND_REQUEST from the new `/user/queue/notifications` subscription into in-app banners — this is plans/notification-center.md's territory; only GAME_FOUND is dispatched here.
- **Multi-node presence**: `WebSocketSessionRegistry` and SimpleBroker are single-node; offline queuing/replay of missed STOMP notifications is out of scope (the REST poll + `quick-match/mine` restore are the compensations).
- **Web client** parity.

## Verification

Backend:
1. `./gradlew test` — new/updated `BotMatchmakingServiceTest`, `CleanupServiceTest`, `LobbyServiceTest`, `LobbyControllerTest` green.
2. Manual (staging): quick-match on device A, background the app, confirm within ~70s the bot fills the lobby and FCM is attempted (server log lines from `BotMatchmakingService` + `PushNotificationService`); repeat with a token-less user and confirm skip + 15-min sweep.

Mobile:
3. `mobile/scripts/test.sh` (analyze + tests) and `mobile/scripts/codegen.sh` after model changes.
4. Manual matrix on a physical iPhone + Android (alpha flavor, staging backend), two accounts:
   - Search → back → chip on home → open daily puzzle → second account quick-matches → banner appears, Join lands in game.
   - Search → start local bot game → match found mid-hand → banner over the game, no forced navigation.
   - Search → background app → match found → push arrives; tap → game screen; cold-start tap → game screen.
   - Search → background → match found → reopen manually without tapping push → found banner via `restore()`.
   - Search → background 20+ min with bots disabled → reopen → "search expired".
   - Cancel search from chip and from waiting screen → server lobby deleted (`GET /api/lobbies/{id}` → 404).
   - Quick-match while a foregrounded socket is alive → **no** push received (`sendIfOffline` skip now actually exercised, since the client holds a socket while searching).

## Critical files

- `mobile/lib/features/lobby/state/matchmaking_provider.dart` (new — the core of the feature)
- `mobile/lib/core/api/websocket_client.dart` (notifications subscription, `disconnect()`, `connectIfNeeded()`)
- `mobile/lib/features/lobby/screens/lobby_waiting_screen.dart` (refactor onto the provider; back no longer leaves)
- `src/main/kotlin/com/jackabee/cribbageclubserver/service/BotMatchmakingService.kt` (reachability gate)
- `src/main/kotlin/com/jackabee/cribbageclubserver/service/LobbyService.kt` (sweep-skip for online waiters, `findQuickMatchLobbyForUser`)
