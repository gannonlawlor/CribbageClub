# Cribbage Club

**The Card Game. Elevated.**

A modern cribbage experience with real-time multiplayer, AI opponents at every skill level, and deep post-game analysis. Play on iOS, Android, or the web.

## Features

- **Play vs AI** — Three difficulty levels (Easy, Medium, Hard) powered by a Rust engine with expected-value analysis, playable fully offline
- **Real-Time Multiplayer** — STOMP/WebSocket matchmaking with private lobbies and friend challenges
- **Post-Game Analysis** — Exhaustive discard analysis evaluating all 15 possible keeps across 46 cut cards
- **Daily Puzzles** — A new discard puzzle every day with streak tracking
- **Ratings** — Glicko-2 rating system with leaderboard
- **Friends & Challenges** — Friend requests, direct challenges, online status indicators
- **Game Replay** — Step-through replay viewer with transport controls
- **Configurable Play Style** — Toggle auto-deal, auto-cut, auto-go, auto-play cards, and adjust animation speed
- **Cross-Platform** — iOS, Android, and web with a shared game engine

## Architecture

The project is a monorepo with four sub-projects:

```
CribbageClub/
├── src/       Spring Boot backend (Kotlin) — game logic, persistence, auth, WebSocket
├── mobile/    Flutter app (Dart) — iOS & Android
├── web/       React SPA (TypeScript) — browser client & landing page
├── engine/    Rust crate — game simulation, AI opponents, discard analysis
└── docker-compose.yml
```

The Rust engine is the single source of truth for game rules and is consumed three ways:

- **Mobile**: Native FFI via flutter_rust_bridge
- **Web**: WASM via wasm-bindgen (built with `wasm-pack`)
- **Backend**: Shared library via JNA (C FFI)

Cargo feature flags (`frb` default, `wasm-web`) control which FFI layer is compiled.

**Analysis caching** flows: local storage -> server (PostgreSQL) -> on-device compute -> cache everywhere.

**Game state filtering** ensures each player only sees their own hand, with opponent cards and crib hidden until the appropriate game stage.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Kotlin 1.9, Spring Boot 3.4, JDK 21, PostgreSQL, Flyway, STOMP/WebSocket |
| Mobile | Flutter/Dart 3.11+, Riverpod, GoRouter, Dio, freezed, flutter_rust_bridge |
| Web | React 19, TypeScript, Zustand, React Router, Tailwind CSS, Vite |
| Engine | Rust, serde, flutter_rust_bridge (mobile FFI), wasm-bindgen (web WASM), JNA (JVM FFI) |
| Infra | Docker, GitHub Actions CI, Tailscale |

## Getting Started

### Prerequisites

- JDK 21
- PostgreSQL 16
- Flutter SDK (stable)
- Node.js
- Rust toolchain + wasm-pack
- Docker (optional, for containerized dev)

### Backend

```bash
# Create credentials for your local database and server (keep them private).
export DB_PASSWORD="$(openssl rand -hex 24)"
export DATABASE_PASSWORD="$DB_PASSWORD"
export JWT_SECRET="$(openssl rand -hex 32)"

# Start PostgreSQL (via Docker or local install)
docker compose up -d postgres

# Build and test (compiles Rust engine first via Gradle task)
./gradlew build

# Run the server
./gradlew bootRun
```

The server starts on `http://localhost:8080`.

### Mobile (Flutter)

```bash
cd mobile
flutter pub get
dart run build_runner build    # generate freezed/json code
flutter run                   # run on connected device
flutter test
```

See [mobile/README.md](mobile/README.md) for build flavors and detailed setup.

### Web (React)

```bash
cd web
npm install
npm run build:wasm            # build Rust engine to WASM (first time)
npm run dev                   # dev server at http://localhost:5173
npm test
```

The dev server proxies `/api` and `/ws` to the backend at `localhost:8080`.

### Engine (Rust)

```bash
cd engine
cargo test                    # run tests (default flutter_rust_bridge feature)

# Build WASM for web
wasm-pack build --target web --release -- --no-default-features --features wasm-web
```

## Game Flow

1. **Dealing** — 6 cards dealt to each player
2. **Discarding** — Each player discards 2 cards to the crib
3. **Cutting** — Non-dealer cuts; Jack scores 2 for dealer (His Nobs)
4. **Pegging** — Alternating play to 31 with scoring for 15s, 31s, pairs, and runs
5. **Counting** — Non-dealer counts first, then dealer, then crib
6. **Game Over** — First to 121 wins

## API

### REST Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/guest` | Create guest account |
| POST | `/api/auth/register` | Register with username/password |
| POST | `/api/auth/login` | Login |
| POST | `/api/auth/upgrade` | Upgrade guest to full account |
| GET | `/api/games/me` | List active games |
| GET | `/api/games/me/history` | Completed game history |
| POST | `/api/games/ai` | Create AI game (difficulty: basic/medium/hard) |
| POST | `/api/games/{id}/actions` | Apply game action |
| GET | `/api/games/{id}/analysis` | Get/compute discard analysis |
| POST | `/api/games/import` | Import local games to server |
| GET | `/api/stats/leaderboard` | Top 10 players |
| GET | `/api/puzzles/daily` | Daily puzzle |

### WebSocket (STOMP)

- **Connect:** `/ws` (SockJS fallback, JWT validated on CONNECT)
- **Subscribe:** `/topic/game/{gameId}`, `/queue/game-state`, `/queue/errors`
- **Send:** `/app/game/action`, `/app/game/join`, `/app/game/leave`

## Deployment

### Docker (Development)

```bash
docker compose up -d
```

Starts PostgreSQL and the Spring Boot app on port 8080. Requires `DB_PASSWORD`
and `JWT_SECRET` (at least 32 random bytes). Store them in your shell or an
ignored `.env` file. Reuse the database password when restarting an existing
database volume; changing the variable does not update the database role.
The server fails at startup if its JWT secret is missing or too short.

### Docker (Staging / QA)

```bash
docker compose -f docker-compose.alpha.yml up -d
```

Runs the app behind a Tailscale sidecar that exposes it publicly via **Funnel**
at `https://cribbage-staging.tail0b042f.ts.net` — reachable by anyone (no tailnet
membership required), so friends can QA from any device. Requires `TS_AUTHKEY`
(tagged `tag:cribbage`), `TS_HOSTNAME`, `TS_FQDN`, `DB_PASSWORD`, and `JWT_SECRET`.
The live instance runs on the titan host under `/opt/cribbage-staging` and pulls
its image from GHCR.

**Staging deploys itself — never build the image locally.** Every push to
`main` that touches backend files runs the CI `image` job, which builds and
pushes `ghcr.io/gannonlawlor/cribbage:main` (plus a `sha-<short>` tag). A
Watchtower container on titan polls GHCR every 2 minutes and restarts the app
on the new image; Flyway applies any new migrations on boot. Verify with
`https://cribbage-staging.tail0b042f.ts.net/actuator/health`. To deploy
immediately instead of waiting for the poll:

```bash
ssh titan "cd /opt/cribbage-staging \
  && docker compose -f docker-compose.staging.yml pull app \
  && docker compose -f docker-compose.staging.yml up -d app"
```

## CI

Secret scanning runs on every push and pull request. Install the local commit
check with `uvx pre-commit install --install-hooks` (or `pre-commit install
--install-hooks` if already installed). It blocks known credential patterns and
hardcoded runtime secrets. Private keys, service-account files, and local
environment files must stay out of Git.

GitHub Actions runs on push/PR to `main`:

- **Backend** — `./gradlew build` + Detekt linting (with PostgreSQL service)
- **Mobile** — `flutter analyze` + `flutter test`
- **Web** — `npm run build` + `npm test`
- **Image** — on `main` pushes with backend changes, builds and pushes the
  backend Docker image to GHCR (`ghcr.io/gannonlawlor/cribbage:main`), ready
  for the staging host to pull — no local docker build or manual image deploy
  needed

## License

Private — All rights reserved.
