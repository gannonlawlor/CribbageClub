# Account Recovery — Forgot Password, Forgot Username, Email Verification

## Context

Cribbage Club accounts are username+password only. There is no email column, no outbound
email channel (only FCM push), and no way to recover a lost password or username. Issued
JWTs live 90 days and cannot be invalidated, so even a successful password reset today
would leave stolen tokens working.

**Confirmed product decisions:**
- Email becomes **required and verified** for new registrations and guest upgrades.
  Existing accounts get a **soft prompt** to add + verify an email (never a hard lock).
- Recovery flows (forgot password / forgot username) only work with a **verified** email.
- Mobile-first UX using **6-digit codes typed into the app**, not magic links (rationale in Phase 3).
- Web parity deferred (web is deprioritized); no web landing page is needed because we
  chose codes over links.

**Verified codebase facts that shape the design:**
- `users` (V1 + alters) has NO email column. Latest migration is **V13**; **V14 is
  reserved by the planned notification center — this feature uses V15.**
- `UserEntity` uses the `Persistable<String>` client-assigned-id pattern
  (src/main/kotlin/com/jackabee/cribbageclubserver/entity/UserEntity.kt).
- Auth DTOs are declared at the bottom of
  src/main/kotlin/com/jackabee/cribbageclubserver/controller/AuthController.kt;
  validation is `require()` in `UserService` (username ≥3, password ≥6) →
  `GlobalExceptionHandler` maps `IllegalArgumentException`→400, `IllegalStateException`→409.
- `JwtService` (jjwt 0.13, HS256) issues claims sub/username/isGuest, 90-day expiry, **no
  jti, no token versioning**. `JwtAuthenticationFilter` and `StompAuthChannelInterceptor`
  both parse the token and stash userId/username/isGuest.
- **`RateLimitFilter.shouldNotFilter` hardcodes exactly `/api/auth/login|register|guest`**
  — every new public auth endpoint MUST be added there or it ships unlimited.
- No `spring-boot-starter-mail` in build.gradle.kts. The "disabled when unconfigured"
  pattern to copy is `FcmConfig` (nullable credentials + warn log).
- Guests: id `guest_<hex>`, `passwordHash null`, `login()` rejects them — guests never
  have email; the **upgrade** flow gains the email requirement.
- Config pattern: `${ENV_VAR:default}` in application.properties, bare `${ENV_VAR}` in
  application-prod.properties, env via docker-compose*.yml + .env.alpha.example.
- Tests run on H2 with Flyway disabled (entities drive schema), so migrations need no H2
  compatibility, but **entities must map cleanly to H2** (no CITEXT/JSONB column types).
- Mobile: `mobile/lib/features/auth/screens/login_screen.dart` (login/register toggle, no
  forgot-password link), `upgrade_screen.dart`; API in `mobile/lib/core/api/rest_client.dart`
  (Dio); auth state in `mobile/lib/core/auth/auth_provider.dart` + `auth_service.dart`
  (SharedPreferences); settings sections in
  `mobile/lib/features/settings/screens/settings_screen.dart` (`_SectionCaption('Account')`).

**Coordination note:** the admin plan (plans/admin-controls.md, V16) also touches
`JwtService.generateToken`, `JwtAuthenticationFilter`, and introduces a shared
`UserAuthStateCache`. Whichever plan lands second extends rather than duplicates those.
This plan should land **first** (the admin "reset password for user" endpoint depends on
the token machinery built here).

## Phase 1 — Migration V15 + entities

### `src/main/resources/db/migration/V15__account_recovery.sql`

Match the timestamp column type used in V1 for `users.created_at` (check
`V1__initial_schema.sql` and use the same type):

```sql
ALTER TABLE users ADD COLUMN email VARCHAR(255);
ALTER TABLE users ADD COLUMN email_verified_at TIMESTAMP;   -- match V1's type
ALTER TABLE users ADD COLUMN token_version INT NOT NULL DEFAULT 0;

-- Case-insensitive uniqueness without the CITEXT extension (CREATE EXTENSION needs
-- elevated privileges on managed Postgres and adds a portability dependency; app code
-- also normalizes to lowercase, this index is the backstop).
CREATE UNIQUE INDEX idx_users_email_lower ON users (LOWER(email)) WHERE email IS NOT NULL;

-- ONE table with a type discriminator, not two: password-reset and email-verify tokens
-- have identical shape and identical hygiene rules (hash-only storage, single-use,
-- expiry, reissue-invalidates-prior). Two tables would duplicate all of that for zero
-- isolation benefit.
CREATE TABLE account_tokens (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    type VARCHAR(30) NOT NULL,          -- PASSWORD_RESET | EMAIL_VERIFY | EMAIL_CHANGE
    code_hash VARCHAR(64) NOT NULL,     -- SHA-256 hex of the 6-digit code; raw code never stored
    new_email VARCHAR(255),             -- EMAIL_CHANGE only: the address being verified
    attempts INT NOT NULL DEFAULT 0,
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL,
    version BIGINT NOT NULL DEFAULT 0
);
CREATE INDEX idx_account_tokens_user_type ON account_tokens (user_id, type);
```

No FK to users — consistent with the rest of the schema (games/friendships have none);
cleanup is explicit.

### Entity/repository changes

- `UserEntity`: add `var email: String? = null`, `var emailVerifiedAt: Instant? = null`,
  `var tokenVersion: Int = 0` (explicit `@Column(name = "token_version", nullable = false)`).
- New `entity/AccountTokenEntity.kt`: `Persistable<String>` pattern copied from
  `UserEntity` (UUID string id, `@Transient _isNew`, `@PostPersist/@PostLoad markNotNew`),
  fields mirroring the DDL, `@Version var version: Long = 0`.
- New `repository/AccountTokenRepository.kt`:
  `findByUserIdAndTypeAndUsedAtIsNull(userId, type): AccountTokenEntity?`,
  `deleteByUserIdAndType(userId, type)`, `deleteByExpiresAtBefore(cutoff): Int`.
- `UserRepository`: add `findByEmail(email: String): UserEntity?` and
  `existsByEmail(email: String): Boolean` (emails are stored normalized lowercase, see
  Phase 3, so plain equality is correct; the LOWER index backs it).

## Phase 2 — Email infrastructure

### Dependency

`build.gradle.kts`: `implementation("org.springframework.boot:spring-boot-starter-mail")`.

### `service/EmailService.kt` — FcmConfig-style "disabled when unconfigured"

Do NOT rely on Spring's `MailSenderAutoConfiguration` (its `@ConditionalOnProperty`
triggers on an empty-string `spring.mail.host`, which our `${SMTP_HOST:}` default pattern
would set). Instead build the sender ourselves, exactly like `FcmConfig` holds nullable
credentials:

```kotlin
@Service
class EmailService(
    @Value("\${app.email.host:}") private val host: String,
    @Value("\${app.email.port:587}") private val port: Int,
    @Value("\${app.email.username:}") private val username: String,
    @Value("\${app.email.password:}") private val password: String,
    @Value("\${app.email.from:Cribbage Club <noreply@example.com>}") private val from: String,
)
```

- `private val mailSender: JavaMailSenderImpl? = buildSender()` — null when `host` is
  blank, with `logger.warn("SMTP not configured — emails will be logged, not sent")`.
  Set `mail.smtp.auth=true`, `mail.smtp.starttls.enable=true` on the sender's javaMailProperties.
- Public methods, all `@Async("emailExecutor")` so auth endpoints never block on SMTP:
  `sendPasswordResetCode(to, code)`, `sendUsernameReminder(to, username)`,
  `sendVerificationCode(to, code)`, `sendEmailChangeCode(to, code)`.
- When `mailSender == null`, log the full message at INFO (this is how dev/staging reads
  codes without SMTP). When sending fails, log error — never propagate to the caller
  (the HTTP response already went out as 200).
- Templates are plain-text Kotlin strings inside EmailService, quiet tone, no
  exclamation points, e.g.:
  - Subject: `Your Cribbage Club password reset code`
  - Body: `Your password reset code is 483920.\n\nIt expires in 30 minutes. If you didn't request this, you can ignore this email.`

### `config/AsyncConfig.kt`

`@Configuration @EnableAsync` with a `@Bean("emailExecutor") ThreadPoolTaskExecutor`
(corePoolSize 1, maxPoolSize 2, queueCapacity 100, thread prefix `email-`). `@EnableAsync`
only affects `@Async`-annotated methods, so nothing else changes behavior.

### Configuration

`application.properties` (dev defaults = disabled):
```properties
# SMTP (optional — email features log instead of send when unconfigured)
app.email.host=${SMTP_HOST:}
app.email.port=${SMTP_PORT:587}
app.email.username=${SMTP_USERNAME:}
app.email.password=${SMTP_PASSWORD:}
app.email.from=${SMTP_FROM:Cribbage Club <noreply@example.com>}
```

`application-prod.properties`: add the same keys with bare `${SMTP_HOST}` etc. (prod
fails fast if unset, matching the JWT_SECRET pattern). Add the five env vars to
`docker-compose.yml`, `docker-compose.alpha.yml`, and `.env.alpha.example`.

## Phase 3 — Recovery service, endpoints, and token invalidation

### Codes, not magic links (decision)

6-digit codes typed into the app, because: (a) there is no universal-links/AASA
infrastructure in the mobile app and the web app is deprioritized, so a link would need
new infra on two fronts; (b) codes work when the user reads email on a different device
than the phone running the app; (c) no web fallback landing page is needed at all.
Brute-force mitigation for the 10^6 code space: codes are useless without the matching
email in the same request, tokens expire (30 min reset / 24 h verify), each token allows
**max 5 attempts** then self-invalidates, only one live token per (user, type), and the
endpoints sit behind `RateLimitFilter` (10 req/60 s/IP).

### `service/AccountRecoveryService.kt`

Core helpers:
- `issue(user, type, newEmail = null): String` — `@Transactional`: delete any prior token
  of the same type for the user (reissue invalidates prior), refuse reissue within 60 s of
  the previous `created_at` (`require()` → 400 "A code was sent recently — check your email"),
  generate `SecureRandom` 6-digit code (`"%06d"`), store SHA-256 hex of it, return the raw
  code to the caller for emailing.
- `consume(user, type, rawCode): AccountTokenEntity` — `@Transactional`: load live token
  (`usedAtIsNull`), check expiry, increment `attempts` and reject with a generic message
  when hash mismatch, hard-invalidate (mark used) after 5 failed attempts, mark `usedAt`
  on success. Generic failure message: "Invalid or expired code" (never distinguish
  wrong-code from expired from no-token).

Flows (all always-200 where noted — **no user enumeration**; the email send happens on
the async executor so response timing is uniform):
- `forgotPassword(email)`: normalize; find user by email; only if found AND
  `emailVerifiedAt != null` AND not a guest → issue PASSWORD_RESET (30 min) + send.
  Always returns silently.
- `resetPassword(email, code, newPassword): AuthResponse` — validate password ≥6, consume
  PASSWORD_RESET, set `passwordHash`, **increment `user.tokenVersion`**, delete other
  outstanding PASSWORD_RESET tokens, return a fresh `AuthResponse` (token minted with the
  new version) so the client is logged in immediately.
- `forgotUsername(email)`: same always-200/verified-only shape; sends the username
  reminder (email is unique, so exactly one account).
- `verifyEmail(userId, code)`: consume EMAIL_VERIFY → set `emailVerifiedAt = now`.
- `resendVerification(userId)`: require email present and unverified; issue EMAIL_VERIFY
  (24 h) + send (60 s cooldown applies).
- `requestEmailChange(userId, password, newEmail)`: reject guests; verify password
  (`passwordEncoder.matches`); validate + uniqueness-check newEmail; issue EMAIL_CHANGE
  (24 h) with `new_email` column set; send code **to the new address**. Old email stays
  active until confirmed. Legacy accounts adding their first email use this same flow
  (password still required).
- `confirmEmailChange(userId, code)`: consume EMAIL_CHANGE → set `email = token.newEmail`,
  `emailVerifiedAt = now` (re-check uniqueness inside the transaction; the partial unique
  index is the last line of defense).
- `@Scheduled(cron = "0 0 4 * * *") purgeExpiredTokens()` — `deleteByExpiresAtBefore(now)`,
  logged like `CleanupService`.

### Email validation + registration changes (`UserService`)

- Normalization: `email.trim().lowercase()` before every store/lookup.
- Validation via `require()`: matches `^[^@\s]+@[^@\s]+\.[^@\s]+$`, length ≤254, and
  `!userRepository.existsByEmail(normalized)` → "Email already in use".
- `register(username, password, displayName, email)` and
  `upgradeGuest(userId, username, password, displayName, email)`: email now required
  parameters; on success, issue EMAIL_VERIFY + async send (account is fully usable while
  unverified — verification only gates recovery).
- `login()` unchanged except it now mints tokens with the user's current `tokenVersion`.
- **Client compatibility:** old mobile builds omit email and will get a 400 with a
  readable inline message. Acceptable at alpha scale; ship the server and mobile build
  together (server first is fine — the error renders in the existing AuthState.error UI).

### `AuthController` endpoints + DTOs (DTOs at the bottom of the file, per convention)

| Endpoint | Auth | Body | Returns |
|---|---|---|---|
| `POST /api/auth/forgot-password` | public | `{email}` | 200 `{message: "If that email is on a verified account, a code is on its way."}` |
| `POST /api/auth/reset-password` | public | `{email, code, newPassword}` | `AuthResponse` |
| `POST /api/auth/forgot-username` | public | `{email}` | 200 generic message |
| `POST /api/auth/verify-email` | JWT | `{code}` | 200 |
| `POST /api/auth/resend-verification` | JWT | – | 200 |
| `PUT /api/auth/email` | JWT | `{password, newEmail}` | 200 (code sent to new address) |
| `POST /api/auth/email/confirm` | JWT | `{code}` | 200 |

- `RegisterRequest` / `UpgradeRequest` gain `val email: String`.
- `UserInfoResponse` (GET /me) gains `val email: String?` and `val emailVerified: Boolean`.
- `UserService.AuthResponse` gains `val email: String?` and `val emailVerified: Boolean`
  (mobile/web stores read them).

### Security wiring (both files MUST change)

- `SecurityConfig`: add `"/api/auth/forgot-password", "/api/auth/reset-password",
  "/api/auth/forgot-username"` to the existing permitAll auth matcher.
- `RateLimitFilter.shouldNotFilter`: replace the three-path check with a
  `companion object` `Set<String>` containing: login, register, guest, forgot-password,
  reset-password, forgot-username, verify-email, resend-verification. (verify/resend are
  authenticated but send email / burn attempts — cheap insurance to include them.)

### JWT invalidation — `token_version` (fixes the 90-day-token problem)

- `JwtService.generateToken(userId, username, isGuest = false, tokenVersion = 0)` → adds
  claim `"tv"`. New `getTokenVersionFromToken(token): Int` (missing claim → 0, so all
  pre-existing tokens read as version 0 and stay valid — no forced logout at deploy).
- New `config/UserAuthStateCache.kt` (`@Component`): `get(userId): CachedUserAuthState?`
  where the state holds `tokenVersion` (the admin plan extends it with role/banned/deleted).
  Backing: `ConcurrentHashMap<String, Entry>` with 60 s TTL per entry, loading from
  `UserRepository.findById` on miss; `invalidate(userId)` called on password reset. Bounded
  by opportunistic eviction of expired entries on write (small user base; same single-node
  assumption as the rest of the codebase).
- `JwtAuthenticationFilter`: after `isTokenValid`, load state from the cache; if
  `tokenTv < state.tokenVersion` → do NOT set authentication (request proceeds anonymous
  → 401 from the security chain). Unknown user (deleted) → same.
- `StompAuthChannelInterceptor`: same check on CONNECT (direct cache call; connects are
  rare so the possible DB hit is fine).
- All call sites of `generateToken` (register, login, createGuest, upgradeGuest, reset)
  pass `user.tokenVersion`.

## Phase 4 — Mobile (Flutter)

### API layer
- `mobile/lib/core/api/rest_client.dart`: `register`/`upgrade` gain `email`; new methods
  `forgotPassword(email)`, `resetPassword(email, code, newPassword)` (returns
  `AuthResponse`), `forgotUsername(email)`, `verifyEmail(code)`, `resendVerification()`,
  `changeEmail(password, newEmail)`, `confirmEmailChange(code)`.
- `mobile/lib/core/models/auth.dart`: `AuthResponse` + the /me model gain
  `email`/`emailVerified` (regenerate freezed/g files).
- `mobile/lib/core/auth/auth_provider.dart` / `auth_service.dart`: persist email +
  verified flag alongside the existing keys; `register`/`upgrade` signatures gain email;
  reset-password success path calls the same `saveAuth` as login.

### Screens
- `login_screen.dart`: register mode gains an email field (validated non-empty, contains
  "@"); login mode gains a right-aligned "Forgot password?" `TextButton` under the
  password field pushing the new recovery screen. A secondary "Forgot username?" text
  link lives on the recovery screen itself (keeps login uncluttered).
- New `mobile/lib/features/auth/screens/forgot_password_screen.dart`: two-step, single
  screen. Step 1: email field + "Send code" (+ the forgot-username link, which fires
  `forgotUsername` and shows the same neutral confirmation). Step 2: code field (6-digit,
  `TextInputType.number`) + new password field + submit; on success the returned
  `AuthResponse` is saved and the user lands home. Errors render inline via the existing
  AuthState.error / ErrorResponse-message pattern.
- `upgrade_screen.dart`: email field added (same validation).
- `settings_screen.dart` Account section: new "Email" row — subtitle shows
  "Not set" / "user@x.com — unverified" / "user@x.com"; taps push new
  `mobile/lib/features/settings/screens/email_settings_screen.dart`: shows current state;
  actions: add/change email (password + new email fields), enter verification code,
  "Resend code" (disabled 60 s after a send). Reads current email from GET /me via the
  auth provider.
- Soft prompt for legacy accounts: dismissible banner on the home screen
  (`mobile/lib/features/home/`) shown when `!isGuest && email == null` — "Add an email so
  you can recover your account." → routes to the email settings screen. Dismissal stored
  in SharedPreferences with a 14-day re-prompt.

## Phase 5 — Web (deferred)

Deferred except for noting the touch points: `web/src/auth/auth-store.ts` gains
email/emailVerified fields when the DTOs change (types only — keeps the build green);
LoginPage forgot-password link, a recovery page, and email settings are backlog. No reset
landing page is required because we chose codes over links.

## Verification

Backend (`./gradlew test`, plus new tests):
- `AccountRecoveryServiceTest`: issue/consume lifecycle, expiry rejection, single-use,
  5-attempt lockout, reissue deletes prior token, 60 s cooldown, unverified email sends
  nothing, guest email rejected, reset bumps tokenVersion.
- `UserServiceTest`: email required/normalized/unique on register + upgrade.
- `JwtServiceTest`: `tv` claim roundtrip; missing claim reads as 0.
- `JwtAuthenticationFilterTest`: token with stale `tv` yields no authentication.
- `RateLimitFilterTest`: new paths are filtered; `/api/auth/me` is not.
- `EmailServiceTest`: unconfigured mode logs and does not throw.
- SecurityConfig integration test: forgot/reset/forgot-username reachable unauthenticated.

Mobile: `flutter analyze && flutter test` in `mobile/` (regenerate codegen first:
`dart run build_runner build --delete-conflicting-outputs`); widget test for the recovery
screen's two-step transition.

Manual staging (Tailscale alpha, SMTP unset → codes appear in `docker logs`):
1. Register with email → verification code in logs → verify via app → /me shows verified.
2. Forgot password roundtrip → old JWT gets 401 afterward (proves token_version), new
   token works, WS reconnect works.
3. Forgot password with unknown email → identical 200, nothing logged/sent.
4. Forgot username → username in logs.
5. Email change: code goes to NEW address; old email works for recovery until confirm.
6. Legacy account (pre-V15 user): sees home banner, adds email via settings, verifies.
7. Rate limit: 11th forgot-password from one IP within 60 s → 429.

## Critical files

- `src/main/kotlin/com/jackabee/cribbageclubserver/service/UserService.kt` (email on register/upgrade)
- `src/main/kotlin/com/jackabee/cribbageclubserver/controller/AuthController.kt` (new endpoints + DTOs)
- `src/main/kotlin/com/jackabee/cribbageclubserver/service/JwtService.kt` (`tv` claim)
- `src/main/kotlin/com/jackabee/cribbageclubserver/config/JwtAuthenticationFilter.kt` (token-version check)
- `src/main/kotlin/com/jackabee/cribbageclubserver/config/RateLimitFilter.kt` (path allowlist)
