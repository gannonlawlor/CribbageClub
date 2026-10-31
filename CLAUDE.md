# CLAUDE.md — Cribbage Club

## Project Overview

Cribbage Club is a cross-platform multiplayer Cribbage card game inspired by Chess.com and LiChess. The project is a monorepo with four sub-projects:

- **Backend** (`src/`): Spring Boot 3.4 server — game logic, persistence, real-time WebSocket, auth, ratings. See `src/CLAUDE.md`.
- **Mobile** (`mobile/`): Flutter app targeting iOS and Android. See `mobile/CLAUDE.md`.
- **Web** (`web/`): React SPA for browser play, including the marketing landing page. See `web/CLAUDE.md`.
- **Engine** (`engine/`): Rust crate powering game simulation, AI opponents, and discard analysis. See `engine/CLAUDE.md`.

## Monorepo Layout

```
CribbageClub/
├── src/                          # Spring Boot backend (Kotlin)
├── mobile/                       # Flutter app (Dart) — iOS & Android
├── web/                          # React SPA (TypeScript) — browser
├── engine/                       # Rust game engine
├── design/                       # Design language spec (Design Language.md) + comps
├── plans/                        # Per-feature technical plans (Context → Phases → Verification)
├── CLAUDE.md                     # This file (project overview)
├── TODO.md                       # Backend task list (all complete)
├── FRONTEND.md                   # Frontend plan and phased roadmap
├── BACKLOG.md                    # Future-feature backlog, indexes plans/
├── build.gradle.kts              # Backend + engine build
├── docker-compose.yml            # Dev: PostgreSQL + app
├── docker-compose.alpha.yml      # Staging/QA: app behind Tailscale Funnel + PostgreSQL
├── Dockerfile                    # Multi-stage backend container
└── .github/workflows/ci.yml     # CI: backend build+test, mobile analyze+test, web build+test
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Kotlin 1.9.25, Spring Boot 3.4.13, JDK 21, PostgreSQL, Flyway, STOMP/WebSocket |
| Mobile | Flutter/Dart 3.11+, Riverpod, GoRouter, Dio, freezed, flutter_rust_bridge |
| Web | React 19, TypeScript, Zustand, React Router, Tailwind CSS, Vite |
| Engine | Rust, serde, flutter_rust_bridge (FFI to Flutter), JNA (FFI to JVM), wasm-bindgen (WASM for web) |
| Infra | Docker, GitHub Actions CI, Tailscale Funnel (public staging) |

## Build & Run

```bash
# Backend (compiles Rust engine first via Gradle task)
./gradlew build          # compile + test
./gradlew bootRun        # run server (needs PostgreSQL on 5432)

# Mobile (Flutter)
cd mobile
flutter pub get          # install deps
flutter run              # run on connected device
flutter test             # run tests
dart run build_runner build  # regenerate freezed/json code

# Web (React)
cd web
npm install              # install deps
npm run dev              # dev server
npm run build            # production build (tsc + vite)
npm test                 # run tests

# Engine (standalone)
cd engine
cargo build --release    # native library
cargo test               # run Rust tests

# Infrastructure
docker compose up -d     # start PostgreSQL + app (dev)
```

## Checks Before Committing

Run only the checks for the directories that changed. They can run in parallel.

| Changed | Check |
|---------|-------|
| `mobile/` | `cd mobile && flutter analyze lib` |
| `src/` | `JAVA_HOME=/Users/gannon/Library/Java/JavaVirtualMachines/openjdk-22.0.2/Contents/Home ./gradlew compileKotlin` |
| `web/` | `cd web && npx tsc -b --noEmit` |
| `engine/` | `cd engine && cargo check` |

- **Scope Flutter analysis to `lib`.** Bare `flutter analyze` reports about 90 pre-existing errors from vendored `rust_builder/cargokit/` and `test_driver/integration_test.dart`. That's also why `mobile/scripts/test.sh` fails at its analyze step.
- **`flutter test` has 2 known failures.** `local_game_service_test.dart` and `local_game_notifier_test.dart` can't load the Rust FFI library in the test host. If you're unsure whether another failure is yours, compare against `main`.
- **Format Dart files you touched** with `dart format` before committing.

## Commits and Branches

- **Commit style:** plain capitalized imperative summaries with no type prefix, such as "Persist and resume in-progress local AI games". This repo doesn't use conventional commits. A semicolon can join two coupled changes. For multi-file changes, add a body wrapped at about 72 columns that explains why.
- **Never stage:**
  - `mobile/dart_define/*.json` if it has gained anything beyond the API URL
  - Any credential, keystore, `.p12` or `.mobileprovision`, or an `ExportOptions.plist` change that embeds a team ID you didn't mean to publish
  - Generated files whose source didn't change: `*.freezed.dart`, `*.g.dart`, `engine/pkg/` and `mobile/lib/src/rust/frb_generated*.dart`. Stage these only with the model or Rust change that regenerated them
- **Branches:** `main` is checked out at the repo root, and feature work usually lives on a `claude/*` branch in `.claude/worktrees/<name>`.
- **Releases:** if a shipped change is mobile-facing, offer `/release`. It doesn't run automatically.

## Game Flow

1. **DEALING** — 6 cards dealt to each player
2. **DISCARDING_TO_CRIB** — Each player discards 2 cards to the crib
3. **CUTTING** — Non-dealer cuts deck; Jack ("His Nobs") scores 2 for dealer
4. **PEGGING** — Alternating card play to 31; scoring for 15s, 31s, pairs, runs
5. **COUNTING** — Non-dealer counts first, then dealer, then crib scored
6. **GAME_OVER** — First player to 121 wins

## Key API Endpoints

### REST

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/guest` | Create guest account |
| POST | `/api/auth/register` | Register with username/password |
| POST | `/api/auth/login` | Login |
| POST | `/api/auth/upgrade` | Upgrade guest to full account |
| GET | `/api/games/me` | My active games |
| GET | `/api/games/me/history` | My completed games |
| POST | `/api/games/ai` | Create AI game (difficulty: basic/medium/hard) |
| POST | `/api/games/{id}/actions` | Apply game action |
| POST | `/api/games/{id}/resign` | Resign a game |
| GET | `/api/games/{id}/analysis` | Get/compute discard analysis |
| POST | `/api/games/{id}/analysis` | Upload client-computed analysis |
| POST | `/api/games/import` | Import local games to server |
| POST | `/api/lobbies/quick-match` | Quick game matchmaking (matches on time control) |
| GET | `/api/lobbies/time-controls` | Available time control presets |
| GET | `/api/lobbies/public` | Lobby browser |
| POST | `/api/lobbies` / `.../join` / `/api/lobbies/join-by-code` | Create/join lobbies |
| GET/POST | `/api/friends/**` | Friends: search, requests, accept/decline |
| POST | `/api/challenges` (+ accept/decline/cancel) | Direct friend challenges |
| GET | `/api/profiles/{userId}` | Public profile (+ `/head-to-head`) |
| POST | `/api/device-tokens` | Register push notification token |
| GET | `/api/stats/leaderboard` | Top 10 players |
| GET | `/api/puzzles/daily` | Daily puzzle (5-puzzle challenge) |
| POST | `/api/puzzles/{id}/solve` | Submit puzzle solution |

### WebSocket (STOMP)

- **Connect:** `/ws` (SockJS fallback, JWT validated on CONNECT)
- **Send:** `/app/game/action`, `/app/game/join`, `/app/game/leave`, `/app/game/state`
- **Subscribe:** `/topic/game/{gameId}`, `/queue/game-state`, `/queue/errors`

## Architecture Highlights

- **Dual engine**: Rust crate used both server-side (JNA) and client-side (flutter_rust_bridge/WASM) for game logic and analysis
- **Analysis caching**: Local (SharedPreferences) → server (PostgreSQL) → on-device compute → cache everywhere
- **Game state filtering**: `GameStateFilter` hides opponent hands, deck, and crib from each player's view
- **Auth**: JWT with 90-day expiry, guest accounts, rate-limited auth endpoints
- **Real-time**: STOMP over WebSocket with authenticated subscriptions, REST for action ordering guarantees
- **Turn timers**: Selectable time controls (BLITZ/RAPID/CASUAL/UNLIMITED) with per-player time banks and server-side timeout forfeit
- **Push notifications**: FCM (friend requests, challenges, game found), sent only when the user is offline

## Current Focus

- **Mobile first**: All client-side UI/UX changes target mobile (Flutter) only for now. Web will be updated after mobile launches.

## Coding Conventions

- **Backend**: Kotlin data classes, sealed classes for actions/events, `require()` for validation, `@Transactional` on multi-step ops, SLF4J logging
- **Mobile**: Riverpod manual providers (no codegen), freezed models, `isLocalGame()` prefix check for offline games, `PlayingCard` (not `Card`) to avoid Flutter widget conflict
- **Web**: Zustand stores, plain TypeScript interfaces (no codegen), Tailwind utility classes, feature-folder structure
- **Engine**: Rust idiomatic patterns, serde for JSON, no unsafe code, exhaustive pattern matching
- **Serialization**: Jackson `@JsonTypeInfo(property = "type")` on backend, `@FreezedUnionValue` on frontend, enums as UPPER_SNAKE
