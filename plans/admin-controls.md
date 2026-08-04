# Admin User Management + Account Deletion

## Context

There is no admin or moderation surface: no roles, no ban flag, no user list, and — an App
Store blocker — **no user-initiated account deletion** (Guideline 5.1.1(v); mobile
Settings only has Sign out). Staging is behind Tailscale Funnel but production won't be,
so authorization must be real, not network topology.

**Confirmed decisions:** secured `/api/admin/**` REST + a minimal admin section in the
React web app (admin-only routes). Role model chosen: `role VARCHAR` (`USER`/`ADMIN`)
rather than `is_admin boolean` — leaves room for `MODERATOR` without another migration.

**Verified codebase facts that shape the design:**
- Latest migration is **V13**; **V14 is reserved by the planned notification center and
  V15 by the account-recovery plan — this feature uses V16** (single migration; the audit
  table fits in V16, no V17 needed).
- `SecurityConfig` filterChain: permitAll list, then `/api/**` authenticated, then
  `anyRequest().permitAll()`. **No `@EnableMethodSecurity`, no roles anywhere**;
  `JwtAuthenticationFilter` and `StompAuthChannelInterceptor` set `authorities = emptyList()`.
- `JwtService` claims: sub/username/isGuest; 90-day expiry; **no way to invalidate issued
  tokens** (the account-recovery plan adds `users.token_version` + `UserAuthStateCache`;
  this plan reuses both — see ordering note below).
- `games.player1_id/player2_id` are plain VARCHARs with **no FKs** — hard-deleting a user
  orphans game rows and breaks ProfileController/leaderboard/replays for opponents. Related
  tables: player_stats, friendships, device_tokens, player_achievements,
  achievement_progress, puzzle_solves, account_tokens (V15), lobbies (playersJson).
- `GlobalExceptionHandler` maps IllegalArgumentException→400, IllegalStateException→409;
  bans need a 403, so a new exception + handler is added.
- Bots (V13): seeded `is_bot` users must be excluded from ban/delete/promote.
- Web: feature folders `web/src/features/<name>/`, Zustand `web/src/auth/auth-store.ts`
  (token/userId/username/isGuest in localStorage), routes in `web/src/App.tsx`
  (react-router 7 `<Routes>` in a shared `<Layout>`).
- `GameEntity` stores stateJson as TEXT — audit `detail` follows the same JSON-in-TEXT
  pattern (JSONB would break the H2 test schema, which Hibernate generates from entities).

**Ordering / coordination:** execute AFTER plans/account-recovery.md. Dependencies on it:
`UserAuthStateCache` (extended here with role/banned/deleted), `token_version` (instant
token kill on ban/role change/delete), and the `account_tokens` machinery (admin
reset-password). If this plan must run first, build `UserAuthStateCache` here, skip the
tokenVersion bumps (60 s cache TTL still enforces bans), and defer the admin
reset-password endpoint. Both plans grow `JwtService.generateToken` — final signature:
`generateToken(userId, username, isGuest = false, tokenVersion = 0, role = "USER")`.

## Phase 1 — Migration V16 + entities

### `src/main/resources/db/migration/V16__admin_and_moderation.sql`

(match V1's timestamp type)

```sql
ALTER TABLE users ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'USER';
ALTER TABLE users ADD COLUMN banned_at TIMESTAMP;
ALTER TABLE users ADD COLUMN ban_reason VARCHAR(500);
ALTER TABLE users ADD COLUMN banned_until TIMESTAMP;   -- null = permanent; supports temp bans now, cheap
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMP;     -- anonymized accounts

CREATE TABLE admin_actions (
    id VARCHAR(255) PRIMARY KEY,
    admin_id VARCHAR(255) NOT NULL,        -- no FK: survives later anonymization; matches schema convention
    action VARCHAR(50) NOT NULL,           -- BAN | UNBAN | PROMOTE | DEMOTE | RESET_PASSWORD | DELETE_USER | SELF_DELETE
    target_user_id VARCHAR(255),
    detail TEXT,                           -- JSON string (stateJson pattern; H2-safe, unlike JSONB)
    created_at TIMESTAMP NOT NULL
);
CREATE INDEX idx_admin_actions_target ON admin_actions (target_user_id, created_at);
CREATE INDEX idx_admin_actions_admin ON admin_actions (admin_id, created_at);
```

No index on users.role/banned_at — user counts are tiny and admin queries are rare.

### Entities/repositories

- `UserEntity`: `var role: String = "USER"`, `var bannedAt: Instant?`,
  `var banReason: String?`, `var bannedUntil: Instant?`, `var deletedAt: Instant?`.
  Helper `fun isBanned(now: Instant) = bannedAt != null && (bannedUntil == null || bannedUntil!!.isAfter(now))`.
- New `entity/AdminActionEntity.kt` (Persistable pattern, UUID id) +
  `repository/AdminActionRepository.kt` (`findAllByOrderByCreatedAtDesc(Pageable)`).
- `UserRepository`: admin search
  `@Query` — `lower(username) LIKE :q OR lower(email) LIKE :q OR id = :raw`, optional
  filter flags (guests/bots/banned), `Pageable` → `Page<UserEntity>`. Also add
  `deleted_at IS NULL` to `searchByUsername` (friend search) and confirm the leaderboard
  query excludes deleted users (same place bots are excluded).

## Phase 2 — AuthZ mechanics

- `JwtService`: `generateToken(..., role: String = "USER")` → claim `"role"`; new
  `getRoleFromToken(token): String` (missing → "USER"). All existing call sites in
  `UserService` pass `user.role` (guests always "USER").
- `JwtAuthenticationFilter`: build authorities —
  `if (role == "ADMIN") listOf(SimpleGrantedAuthority("ROLE_ADMIN")) else emptyList()` —
  and set request attribute `"role"`.
- `SecurityConfig`:
  - Insert `.requestMatchers("/api/admin/**").hasRole("ADMIN")` **immediately before**
    `.requestMatchers("/api/**").authenticated()` (matcher order is first-match-wins; after
    the catch-all it would be dead).
  - Add `@EnableMethodSecurity` to the class and `@PreAuthorize("hasRole('ADMIN')")` on
    `AdminController` (class level) — defense in depth if the matcher list is ever reordered.
- **Stale-claim mitigation** (JWT role lives 90 days): every `AdminService` mutation and
  read starts with `requireCurrentAdmin(adminId)` — a live DB check that the caller's row
  still has `role = 'ADMIN'`, is not banned/deleted (one PK lookup; admin traffic is
  tiny). A demoted admin is locked out on their next request even with an old token.
  Additionally, promote/demote bump the target's `token_version` (if V15 landed) so the
  target's next request re-evaluates; otherwise re-login picks up the new role —
  document this in the endpoint's OpenAPI description.
- **First-admin bootstrap** — chosen: idempotent startup seed from env (over manual SQL:
  repeatable across environments, no prod psql access needed, self-documenting in
  .env.alpha.example). New `config/AdminBootstrap.kt`, `ApplicationRunner`:
  reads `app.admin.usernames=${ADMIN_USERNAMES:}` (comma list); for each, find by
  username; if found and role != ADMIN → promote + log info; if missing → log warn (user
  registers first, then restart). Add `ADMIN_USERNAMES` to application.properties,
  docker-compose files, `.env.alpha.example`.

## Phase 3 — Ban enforcement

- New `exception/AccountBannedException(message)` handled in `GlobalExceptionHandler` →
  403 `ErrorResponse(status=403, error="Forbidden", message=...)`.
- `UserService.login()`: after the password check — if `deletedAt != null` → the same
  generic "Invalid username or password" (deleted accounts are indistinguishable); if
  `isBanned(now)` → `AccountBannedException("Account suspended" + (until?.let { " until $it" } ?: ""))`.
  `upgradeGuest()`: same ban check (guests can be banned by id).
- **Existing tokens — pragmatic enforcement** (recommended over per-request DB hits):
  - REST: `UserAuthStateCache` (from the recovery plan) state grows
    `role/banned/deleted`; `JwtAuthenticationFilter` refuses to set authentication when
    banned or deleted. 60 s TTL means a ban bites on REST within a minute — fine.
    `AdminService.ban/unban/setRole/delete` call `cache.invalidate(targetId)` so it's
    usually instant anyway.
  - WS: `StompAuthChannelInterceptor` checks the cache on CONNECT and rejects banned/
    deleted users (connects are rare; a cache miss costing one DB read is fine).
  - Ban also bumps the target's `token_version` (V15) — makes existing tokens dead
    permanently, not just while banned-state is cached.
- **Active games: leave them.** A banned player simply can't act; the turn-timer
  machinery forfeits them on the normal clock, and the opponent gets a clean win. No
  special resign-on-ban path (keeps ban side-effect-free and reversible). Waiting
  lobbies age out via `CleanupService` within 15 minutes.

## Phase 4 — Admin API, audit log, anonymization

New `controller/AdminController.kt` (`@RequestMapping("/api/admin")`,
`@PreAuthorize("hasRole('ADMIN')")`, `@Tag(name = "Admin")`, DTOs at the bottom per
convention) delegating to new `service/AdminService.kt`.

| Endpoint | Body | Behavior |
|---|---|---|
| `GET /api/admin/users?q=&filter=all\|guests\|bots\|banned&page=0&size=25` | – | Paginated `AdminUserSummary` list (id, username, displayName, email, emailVerified, isGuest, isBot, role, bannedAt/banReason/bannedUntil, deletedAt, createdAt, lastLoginAt) |
| `GET /api/admin/users/{id}` | – | `AdminUserDetail`: summary + player_stats (rating, played, won) + last 10 games (id, opponent, winner, createdAt via GameRepository) + deviceTokenCount + friendCount |
| `POST /api/admin/users/{id}/ban` | `{reason, until?}` | Guards: not self, not bot, not already banned (409). Sets fields, invalidates cache, bumps token_version, audits |
| `POST /api/admin/users/{id}/unban` | – | Clears ban fields, audits |
| `POST /api/admin/users/{id}/role` | `{role}` | `USER`/`ADMIN` only; refuse self-demotion (last-admin lockout guard); audits PROMOTE/DEMOTE |
| `POST /api/admin/users/{id}/reset-password` | – | If target has a verified email → trigger the normal `AccountRecoveryService` reset email, respond `{method:"EMAIL"}`. Else → issue a PASSWORD_RESET token and return `{method:"CODE", code}` for the admin to read out over support channels (30 min, single-use). Audits WITHOUT the code. **Depends on V15 machinery.** |
| `DELETE /api/admin/users/{id}` | – | `AccountDeletionService.anonymize` (below); guards: not self, not bot; audits DELETE_USER |
| `GET /api/admin/overview` | – | Cheap counts: totalUsers (non-guest, non-bot, non-deleted), guests, bannedCount, newUsers7d, gamesCompletedToday, activeGames, waitingLobbies — simple repository `count` queries, no caching |
| `GET /api/admin/actions?page=&size=` | – | Paginated audit log |

Audit: `AdminService.record(adminId, action, targetId, detail: Map<String, Any?>)`
serializes detail with the injected `ObjectMapper` into the TEXT column. **Every admin
mutation writes exactly one row inside the same transaction.**

### `service/AccountDeletionService.kt` — anonymize, don't hard-delete (decision)

Hard delete would orphan `games.player1_id/player2_id` (no FKs) and break opponents'
history, ProfileController, replays, and the leaderboard joins. Anonymization keeps
referential integrity while purging PII. One `@Transactional` `anonymize(userId)`:

1. Active games: resign each via the existing forfeit/resign path (opponents get closure
   instead of a slow timeout).
2. `users` row: `username = "deleted_" + id.take(8)` (on the unlikely unique collision,
   extend the prefix), `displayName = "Deleted Player"`, `email = null`,
   `emailVerifiedAt = null`, `passwordHash = null`, `avatarIndex = null`,
   `deletedAt = now`, `tokenVersion++`.
3. Purge rows: `device_tokens`, `friendships` (both directions), `account_tokens`.
   Keep: `player_achievements`, `achievement_progress`, `puzzle_solves` (no PII beyond
   the opaque user id), and **keep `player_stats`** (recommended over zeroing — the
   leaderboard and friend search now exclude `deleted_at IS NOT NULL` users anyway, and
   opponents' rated-game context stays coherent).
4. `games` rows untouched — opponents see "Deleted Player" wherever the display name is
   resolved via the users table (verify ProfileController returns the anonymized name
   rather than 404 for deleted ids; adjust if it filters).
5. `userAuthStateCache.invalidate(userId)`.

## Phase 5 — User-initiated account deletion (App Store 5.1.1(v) — launch requirement)

Ships with this plan because it reuses `AccountDeletionService`, but is required for
launch regardless of the rest of the admin surface.

- Backend: `DELETE /api/auth/me` in `AuthController`, body
  `DeleteAccountRequest(password: String?)` (Spring accepts `@RequestBody` on DELETE; Dio
  and fetch both send it). Full accounts: `passwordEncoder.matches` or 400 "Password is
  incorrect". Guests: no password required (nothing to verify; the confirm dialog is the
  guard). Calls `anonymize(userId)`; writes an `admin_actions` row with
  `action = SELF_DELETE, admin_id = userId`. Response 200; client discards the token.
- Mobile: `mobile/lib/features/settings/screens/settings_screen.dart` Account section,
  below Sign out — "Delete account" row in the destructive/red style → `CcDialog` confirm
  explaining permanence ("Your profile and email are removed; finished games remain,
  shown as Deleted Player."); full accounts get a password field inside the dialog. On
  success: `authService.clearAuth()` → login screen. New
  `rest_client.deleteAccount(String? password)`.
- Web: same call wired later; not launch-blocking (no web store review).

## Phase 6 — Web admin UI (`web/src/features/admin/`)

- DTO plumbing: `UserService.AuthResponse` and `UserInfoResponse` gain `role`;
  `web/src/auth/auth-store.ts` adds `role: string` (persisted to localStorage beside
  isGuest; refreshed from `GET /api/auth/me` on `init()` so demotions reflect on reload).
- Files (feature-folder + Zustand conventions, Tailwind, minimal):
  - `web/src/features/admin/admin-api.ts` — typed fetch wrappers for every Phase 4 endpoint.
  - `web/src/features/admin/admin-store.ts` — Zustand: overview, user page (query, filter,
    page, results), selected user detail, action states.
  - `web/src/features/admin/AdminPage.tsx` — overview stat cards row + search input +
    filter select + users table (username, email, role, status badges guest/bot/banned/deleted,
    last login); row click opens the drawer.
  - `web/src/features/admin/UserDetailDrawer.tsx` — detail panel with Ban (reason +
    optional until), Unban, Promote/Demote, Reset password (shows returned code when
    `method === "CODE"`), Delete (type-username-to-confirm) — each behind a small confirm
    modal.
  - `web/src/features/admin/RequireAdmin.tsx` — `role !== 'ADMIN'` → `<Navigate to="/" />`
    (cosmetic guard; the server is the enforcement).
- `web/src/App.tsx`: `<Route path="/admin" element={<RequireAdmin><AdminPage /></RequireAdmin>} />`
  inside the Layout route; Layout nav shows an "Admin" link when `role === 'ADMIN'`.

### Deferred hardening
Recent-login re-confirmation for destructive admin ops, audit export, MODERATOR role,
admin 2FA — all deferred; the audit log gives traceability in the meantime.

## Verification

Backend (`./gradlew test`, plus new tests):
- Security integration test: non-admin JWT → 403 on `/api/admin/users`; admin JWT → 200;
  unauthenticated → 401 (proves matcher ordering).
- `AdminServiceTest`: ban/unban lifecycle, self-ban refused, bot-ban refused,
  self-demotion refused, every mutation writes an audit row, demoted admin's next call
  fails `requireCurrentAdmin`.
- `UserServiceTest`: banned login → 403 message, temp ban expiry allows login,
  deleted login → generic 400.
- `AccountDeletionServiceTest`: PII cleared, device_tokens/friendships purged,
  player_stats + games retained, active game forfeited, username collision path.
- `JwtAuthenticationFilterTest`: banned user's valid token yields no authentication after
  cache invalidation.
- `AdminBootstrap` test: idempotent (second run no-ops), missing username warns.

Web: `npm run build` and `npx tsc --noEmit` in `web/`; manual: non-admin visiting /admin
is redirected and gets 403s from the API.

Manual staging checks:
1. Set `ADMIN_USERNAMES` on titan, restart, confirm promote log line; login on web → Admin
   link appears; overview numbers sane.
2. Ban a test account with reason + until → its app: REST 401s within 60 s, WS CONNECT
   rejected, login shows the 403 suspension message; unban restores login.
3. Admin reset-password on an email-verified user → email path; on a legacy user → code
   path; code works in the mobile reset flow.
4. Delete a test user from the drawer → opponent's history shows "Deleted Player",
   leaderboard drops them, their token dead.
5. Mobile self-delete: guest (no password) and full account (wrong password rejected) →
   back at login; re-login with old creds fails generically.
6. Audit log lists every action above with the right admin/target.

## Critical files

- `src/main/kotlin/com/jackabee/cribbageclubserver/config/SecurityConfig.kt` (admin matcher + method security)
- `src/main/kotlin/com/jackabee/cribbageclubserver/config/JwtAuthenticationFilter.kt` (role authority, ban/delete check)
- `src/main/kotlin/com/jackabee/cribbageclubserver/service/JwtService.kt` (role claim)
- `src/main/kotlin/com/jackabee/cribbageclubserver/service/UserService.kt` (ban/deleted login checks)
- `web/src/features/admin/` (new admin UI)
