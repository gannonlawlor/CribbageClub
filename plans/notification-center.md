# In-App Notifications and Notification Center

## Context

Every real-time social event already publishes a typed DTO to STOMP `/user/queue/notifications` via `NotificationWebSocketService` (`src/main/kotlin/com/jackabee/cribbageclubserver/websocket/NotificationWebSocketService.kt`): FRIEND_REQUEST, FRIEND_ACCEPTED, CHALLENGE_RECEIVED/DECLINED/CANCELLED, GAME_FOUND, ACHIEVEMENT_UNLOCKED. Delivery is fire-and-forget on an in-memory SimpleBroker — nothing persisted or replayed — and **the mobile app never subscribes to that queue**. The only notification UI today is a count dot from `GET /api/friends/notifications/count` (`FriendController.kt:97`, pending friend requests + pending challenges, computed on read) fetched on screen mount via `notificationCountProvider`. Push (FCM) fires only when the user is offline (`PushNotificationService.sendIfOffline`). On mobile, the STOMP client connects lazily and only from `GameNotifier` (`game_providers.dart:133`), and `WebSocketClient.onStatusChange` is a single-slot callback owned by `GameNotifier` — both need attention for an app-wide feed.

Confirmed product decision: full notification center — persisted history (V14), read/unread, feed screen, replay, unread badge on the bottom nav profile tab.

**Migration numbering: this feature uses V14.** (V15 is reserved by plans/account-recovery.md, V16 by plans/admin-controls.md.)

**Coordination note:** plans/play-while-waiting.md also adds a `/user/queue/notifications` subscription (GAME_FOUND only) and mounts an overlay host. Whichever lands second builds on the first's `subscribeToNotifications` in `websocket_client.dart`; this plan's generalized `NotificationBannerHost` supersedes any matchmaking-only banner styling.

Key decisions:
- **Persisted types:** FRIEND_REQUEST, FRIEND_ACCEPTED, CHALLENGE_RECEIVED, ACHIEVEMENT_UNLOCKED. **Transient (WS/banner only, no row):** GAME_FOUND — only actionable in the moment; the game itself is the durable artifact (it appears in `/api/games/me` and the home Resume section; a stale "game found" row days later is noise). CHALLENGE_DECLINED and CHALLENGE_CANCELLED are also transient — they are retractions, not events to archive; cancellation additionally *retracts* the stored CHALLENGE_RECEIVED row.
- **`ref_id` column** (friendshipId or lobbyId) so retraction/reconciliation needs no JSON queries.
- **Retention:** per-user cap of 200 enforced at insert, plus a daily sweep deleting read notifications older than 90 days.
- **The existing count endpoint stays.** It counts *actionable pending items* — a different semantic from *unread feed items*. Friends screen and the profile Friends row keep it; the nav badge and center use the new unread count.

## Phase 1 — Backend: persistence + shared emit path

**New `src/main/resources/db/migration/V14__notifications.sql`:**
```sql
CREATE TABLE notifications (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id),
    type VARCHAR(40) NOT NULL,
    payload JSONB NOT NULL,
    ref_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    read_at TIMESTAMP WITH TIME ZONE
);
CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id) WHERE read_at IS NULL;
CREATE INDEX idx_notifications_user_ref ON notifications(user_id, ref_id);
```

**New `entity/NotificationEntity.kt`** — String UUID id (Persistable pattern like `UserEntity`), explicit `@Column` names throughout, `payload` mapped `@JdbcTypeCode(SqlTypes.JSON) @Column(columnDefinition = "jsonb") var payload: String`, `Instant` timestamps, `readAt: Instant?`. If H2 integration tests choke on JSON, fall back to TEXT in the entity mapping — the Postgres migration keeps jsonb either way.

**New `repository/NotificationRepository.kt`** — `findByUserIdOrderByCreatedAtDescIdDesc(pageable)`, cursor variant `...AndCreatedAtBefore...`, `countByUserIdAndReadAtIsNull`, `findByUserIdAndRefIdAndReadAtIsNull`, `@Modifying` bulk `markAllRead(userId, now)`, native delete for the per-user cap (`DELETE ... WHERE user_id = ? AND id NOT IN (SELECT id ... ORDER BY created_at DESC LIMIT 200)`), `deleteByReadAtBefore(cutoff)`.

**New `service/UserNotificationService.kt`** — named to avoid the existing `notificationService` injection of `NotificationWebSocketService` in `FriendService`. The single shared method keeping DB row + WS + push in sync:
- `notify(userId, type, payload: Map<String, Any?>, refId: String? = null, persistent: Boolean, push: PushSpec? = null): String?` — when persistent: build entity (UUID, `Instant.now()`), save, enforce cap; always: send the WS DTO **carrying the row id**; when `push != null`: `pushNotificationService.sendIfOffline(...)` with the same data maps used today. Returns the notification id.
- `retractChallenge(userId, lobbyId)` — mark the unread CHALLENGE_RECEIVED row with `refId = lobbyId` read.
- `markFriendRequestHandled(userId, friendshipId)` — same for accepted/declined friend requests.
- `list(userId, before: Instant?, limit)`, `unreadCount(userId)`, `markRead(id, userId)` (owner check), `markAllRead(userId)`.

**Modified `websocket/NotificationWebSocketService.kt`** — add `val id: String? = null` to `FriendRequestNotification`, `FriendAcceptedNotification`, `ChallengeNotification`, `AchievementUnlockedNotification` so the client can reconcile live frames against fetched rows. Transient DTOs unchanged.

**Rewire call sites** (each replaces its WS + push pair with one `userNotificationService.notify(...)`, same payload fields as the current DTOs):
- `service/FriendService.kt:97` (request sent → persistent + push) and `:144` (accepted → persistent, no push, as today). `acceptFriendRequest` also calls `markFriendRequestHandled(addresseeId, friendshipId)`; same in any decline/remove path.
- `controller/ChallengeController.kt:44` (create → persistent + push), `:101` (decline → transient WS to challenger + `retractChallenge(challengedUserId, lobbyId)`), `:128` (cancel → transient WS + `retractChallenge`). `acceptChallenge` also calls `retractChallenge` so the row doesn't sit unread after the game starts.
- `service/LobbyService.kt:356` `notifyGameFound` → `notify(..., persistent = false, push = ...)`.
- `service/AchievementService.kt:230` `notifyAfterCommit` → persistent notify (payload = achievement summaries), preserving the existing after-commit timing.

Transactionality: `notify` inserts join the caller's transaction where one exists; WS/push fire immediately as today — acceptable because the client reconciles by refetching (Phase 3), and achievements already defer to after-commit.

**New `controller/NotificationController.kt`** (`/api/notifications`; covered by the existing `/api/**` authenticated matcher in `SecurityConfig` — no security change):
- `GET /api/notifications?limit=30&before={ISO instant}` → `{ items: [{id, type, payload, refId, createdAt, readAt}], hasMore }` (cursor = `createdAt` of last item).
- `GET /api/notifications/unread-count` → `{ count }`.
- `POST /api/notifications/{id}/read` → 204.
- `POST /api/notifications/read-all` → 204.

**`service/CleanupService.kt`** — add a daily `@Scheduled` purge: `deleteByReadAtBefore(now - 90d)`.

## Phase 2 — Mobile plumbing: models, REST, WS subscription

- **New `mobile/lib/core/models/notification.dart`** — freezed `AppNotification(id, type, payload Map<String,dynamic>, refId, createdAt, readAt)` with `enum NotificationType { @JsonValue('FRIEND_REQUEST') friendRequest, ..., unknown }` using `unknownEnumValue: NotificationType.unknown` so future server types don't crash old clients; `NotificationPage(items, hasMore)`. Run `dart run build_runner build`.
- **`mobile/lib/core/api/rest_client.dart`** — `getNotifications({DateTime? before, int limit = 30})`, `getUnreadNotificationCount()`, `markNotificationRead(String id)`, `markAllNotificationsRead()`.
- **`mobile/lib/core/api/websocket_client.dart`** —
  - `subscribeToNotifications({required void Function(Map<String, dynamic>) onNotification})`: key `'user-notifications'`, destination `/user/queue/notifications`, decode to a raw map (payloads are heterogeneous; typed parsing happens in the notifier). Registered in `_pendingSubscriptions` so it survives reconnect like the others.
  - Replace the single `onStatusChange` callback with a listener list (`addStatusListener`/`removeStatusListener`) — today `GameNotifier._connectWebSocket` owns the only slot, and a notifications listener would silently steal it. Migrate `GameNotifier` to the list API in the same change.

## Phase 3 — Mobile state: NotificationsNotifier, replay, banner generalization

**New `mobile/lib/core/providers/notifications_provider.dart`:**
- `notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>` (not autoDispose — app-wide feed). State: `items`, `unreadCount`, `isLoading`, `hasMore`, `error`.
- Lifecycle: watches `authProvider`; on login (and at construction when already logged in) it connects the WS if needed, calls `subscribeToNotifications`, adds a status listener, and does the initial `getNotifications()` + `getUnreadNotificationCount()`. On logout: clears state, removes listener.
- Live WS frame: parse `type`; persisted types (id != null) → dedupe by id, prepend, `unreadCount++`, enqueue banner; transient types → banner only. FRIEND_REQUEST / CHALLENGE_RECEIVED / CHALLENGE_CANCELLED / CHALLENGE_DECLINED additionally `ref.invalidate(notificationCountProvider)` so the old actionable dot updates live too — fixing today's screen-mount staleness for free.
- **Replay-on-reconnect:** the status listener fires on `ConnectionStatus.connected` → refetch unread count + first page and merge by id (server rows are the source of truth; anything emitted while the socket was down appears in the fetch). Cold app start gets the same guarantee from the initial fetch, which also covers events that arrived only as pushes while offline.
- Expose `unreadNotificationCountProvider = Provider<int>` selecting `unreadCount` for badges.
- `loadMore()` (cursor pagination), `markRead(id)` / `markAllRead()` (optimistic local update + REST).

**Generalize the banner host** (`mobile/lib/shared/widgets/achievement_banner.dart` → new `mobile/lib/shared/widgets/notification_banner.dart`):
- `BannerItem(kicker, title, subtitle, icon, iconColor, route)`; `NotificationBannerQueue` (same FIFO StateNotifier mechanics, keyed dedupe) + `NotificationBannerHost` reusing the existing slide-down/hold/slide-away implementation, with tap → dismiss then `router.go(route)`.
- Per-type routes mirror `push_notification_service.dart` exactly: FRIEND_REQUEST/FRIEND_ACCEPTED/CHALLENGE_RECEIVED/CHALLENGE_DECLINED/CHALLENGE_CANCELLED → `/friends`; GAME_FOUND → `/game/{gameId}`; ACHIEVEMENT_UNLOCKED → `/me`. Kickers stay quiet, matching the "ACHIEVEMENT UNLOCKED" style: "FRIEND REQUEST", "CHALLENGE", "GAME READY".
- Achievements keep their look: `achievement_service.dart` enqueues a `BannerItem` with the trophy icon and tier color (small adapter); `AchievementBannerQueue/Host` are deleted; `app.dart` swaps `AchievementBannerHost` for `NotificationBannerHost` in the `MaterialApp.builder` Stack.

## Phase 4 — Mobile UI: center screen, entry points, nav badge

**New `mobile/lib/features/notifications/screens/notifications_screen.dart`**, route `/notifications` (MaterialPage) in `mobile/lib/config/routes.dart`:
- Grouped list: Today / This week / Earlier. Row: per-type icon tile, title line ("gannon sent you a friend request", "Challenge from mia", "Achievement — The Perfect Hand"), time-ago, accent unread dot.
- **Mark-read behavior (decision):** opening the screen calls `markAllRead()` once the first page loads — the badge exists to say "something new is here" and clears the moment you look. Rows keep their unread styling for the current visit (styling keyed off a snapshot taken before the call). Row tap deep-links via the same per-type routes.
- Infinite scroll via `loadMore()`; pull-to-refresh refetches page 1 + count. Empty state: "Nothing yet." in `textTertiary`.

**Entry points:**
- Home header (`home_screen.dart` `_Header`): a bell icon button before the rating chip with a small accent dot when unread > 0; tap → `context.push('/notifications')`.
- Profile (`my_profile_screen.dart`): `_LinkRow(icon: Icons.notifications_none, label: 'Notifications', badge: unread)` above the Friends row. The Friends row badge keeps `notificationCountProvider` (actionable pending semantics).

**Nav badge** (`mobile/lib/shared/widgets/cc_bottom_nav.dart`): convert `CcBottomNav` to a ConsumerWidget; `_NavItem` gains `showDot: bool`; the Profile item sets it from `unreadNotificationCountProvider > 0`. A quiet 6px accent dot at the icon's top-right — no number, consistent with the design language.

**`notificationCountProvider` migration:** stays for pending-count semantics (`friends_screen.dart` Requests segment and its invalidations, profile Friends row). Document the split in a comment on both providers.

## Phase 5 — Retention polish + deploy

- Verify per-user cap query performance (single-user, index-backed delete on the insert path).
- Staging: push to master → CI image → pull/restart on titan; Flyway applies V14 on boot; check `/actuator/health` and logs.

## Verification

Backend (`./gradlew test`):
- `UserNotificationServiceTest` — persistent notify saves a row and the WS DTO carries the row id; transient notify saves nothing; push spec forwarded to `sendIfOffline`; cap trims to 200; `retractChallenge` marks only the matching unread row; `markRead` rejects a non-owner.
- `NotificationControllerTest` — cursor pagination (two pages, no overlap/gap), unread-count, read-all idempotence, 401 unauthenticated.
- Call-site tests: friend request creates a row for the addressee; accepting marks the addressee's FRIEND_REQUEST row read and creates FRIEND_ACCEPTED for the requester; challenge cancel leaves no unread CHALLENGE_RECEIVED; game found creates no row.

Mobile (`mobile/scripts/test.sh`):
- Unit: notifier dedupes a WS frame whose id is already in the fetched page; reconnect triggers refetch-and-merge; unknown `type` doesn't throw; transient frame banners without touching items; unread math under optimistic mark-read.
- Widget: banner tap navigates per type; nav dot appears/disappears with unread count; notifications screen groups, marks all read on open, paginates.

Manual (two accounts on staging): friend request lands as banner + row + nav dot on a foregrounded device; challenge banner tap opens /friends; cancel the challenge → recipient's row flips read; kill the app, send events, relaunch → they're in the center (replay); airplane mode → push arrives → open app → row present and consistent; achievement unlock still banners with trophy styling.

## Critical files

- `src/main/kotlin/com/jackabee/cribbageclubserver/websocket/NotificationWebSocketService.kt` (DTOs gain row id)
- `src/main/kotlin/com/jackabee/cribbageclubserver/service/FriendService.kt` (rewire to `UserNotificationService`)
- `mobile/lib/core/api/websocket_client.dart` (notifications subscription, status-listener list)
- `mobile/lib/shared/widgets/achievement_banner.dart` (generalized into `notification_banner.dart`)
- `mobile/lib/core/providers/notification_provider.dart` (kept; semantics documented vs the new feed)
