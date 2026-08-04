# Backlog

Future features with completed technical plans, ordered by suggested priority. Each links to a full implementation plan in `plans/` (format: Context → Phases → Verification). Update the Status column as work starts/lands.

| # | Feature | Plan | Status | Why this priority |
|---|---------|------|--------|-------------------|
| 1 | Account recovery — forgot password/username, required verified email | [plans/account-recovery.md](plans/account-recovery.md) | Planned | Launch blocker: no recovery path exists; also fixes irrevocable 90-day JWTs (`token_version`) |
| 2 | Admin user management + account deletion | [plans/admin-controls.md](plans/admin-controls.md) | Planned | Contains the App Store 5.1.1(v) **account deletion** launch blocker; roles, bans, audit log, web admin UI |
| 3 | In-app notifications + notification center | [plans/notification-center.md](plans/notification-center.md) | Planned | Replaces the mount-time-only dot with live banners, persisted feed, unread nav badge |
| 4 | Play while you wait (quick-match multitasking) | [plans/play-while-waiting.md](plans/play-while-waiting.md) | Planned | Background/roam during matchmaking with push + local notification when the game is ready |
| 5 | Interactive cribbage tutorial | [plans/tutorial.md](plans/tutorial.md) | Planned | Removable "Learn cribbage" home tile; 8 lessons + guided real hand vs easy bot |
| 6 | Launch asset & icon pipeline | [plans/launch-assets.md](plans/launch-assets.md) | Planned | Complete asset inventory with Gemini prompts (store art, 25 achievement glyphs, 16 avatars, web favicon/og) — needed before store submission, independent of the rest |

## Cross-plan coordination

- **Flyway migration reservations:** V14 = notification center · V15 = account recovery · V16 = admin/moderation. If a plan lands out of order, renumber to the next free version and update the other plans' Context sections.
- **Account recovery before admin controls.** Admin's reset-password endpoint reuses V15's `account_tokens` machinery; both extend `JwtService.generateToken` (final signature `(userId, username, isGuest, tokenVersion, role)`) and share `UserAuthStateCache`. Admin includes a fallback if it must land first.
- **Play-while-waiting ↔ notification center.** Both add the `subscribeToNotifications` (`/user/queue/notifications`) subscription in `mobile/lib/core/api/websocket_client.dart` and both touch the app-wide banner overlay in `app.dart`. Whichever lands second builds on the first's subscription; the notification center's generalized `NotificationBannerHost` supersedes any matchmaking-only banner styling.
- **Launch assets ↔ achievements/tutorial/notifications.** Achievement glyph subjects come from the catalog in [plans/achievements.md](plans/achievements.md); the tutorial's lesson-1 board illustration and the Android notification small icon are both produced by the asset plan.
- **iOS push entitlements** (`aps-environment`, currently absent) are specified in play-while-waiting Phase 3 but benefit every push-dependent feature — do that platform config with whichever push-touching plan ships first.

## Completed plans (for reference)

- [plans/achievements.md](plans/achievements.md) — implemented
- [plans/bot-fallback-matchmaking.md](plans/bot-fallback-matchmaking.md) — implemented
