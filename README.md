# Cribbage Club

**The Card Game. Elevated.**

A modern cribbage experience with real-time multiplayer, AI opponents at every skill level, and deep post-game analysis. Play on iOS, Android, or the web.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Kotlin, Spring Boot 3.4, JDK 21, PostgreSQL, Flyway, STOMP/WebSocket |
| Mobile | Flutter/Dart, Riverpod, GoRouter, Dio, freezed, flutter_rust_bridge |
| Web | React 19, TypeScript, Zustand, React Router, Tailwind CSS, Vite |
| Engine | Rust, serde, flutter_rust_bridge (mobile FFI), wasm-bindgen (web WASM), JNA (JVM FFI) |
| Infra | Docker, GitHub Actions CI, Tailscale |

## Monorepo Layout

```
CribbageClub/
├── src/          # Spring Boot backend (Kotlin)
├── mobile/       # Flutter app (Dart) — iOS & Android
├── web/          # React SPA (TypeScript) — browser
├── engine/       # Rust game engine & AI
├── landing/      # Static marketing landing page
└── docker-compose.yml
```

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

## Features

- **Play vs AI** — Three difficulty levels (basic, medium, hard) powered by a Rust engine with expected-value analysis
- **Real-Time Multiplayer** — STOMP/WebSocket matchmaking and private lobbies
- **Post-Game Analysis** — Exhaustive discard analysis evaluating all 15 possible keeps across 46 cut cards
- **Daily Puzzles** — Five puzzles per day with streak tracking
- **Ratings** — Glicko-2 rating system with leaderboard
- **Friends & Challenges** — Friend requests, direct challenges, online status
- **Game Replay** — Step-through replay viewer with transport controls
- **Cross-Platform** — iOS, Android, and web with shared game engine

## Architecture

The Rust engine is the single source of truth for game rules and is consumed three ways:

- **Mobile**: Native FFI via flutter_rust_bridge
- **Web**: WASM via wasm-bindgen (built with `wasm-pack`)
- **Backend**: Shared library via JNA (C FFI)

Cargo feature flags (`frb` default, `wasm-web`) control which FFI layer is compiled.

**Analysis caching** flows: local storage → server (PostgreSQL) → on-device compute → cache everywhere.

**Game state filtering** ensures each player only sees their own hand, with opponent cards and crib hidden until the appropriate game stage.

## Game Flow

1. **Dealing** — 6 cards dealt to each player
2. **Discarding** — Each player discards 2 cards to the crib
3. **Cutting** — Non-dealer cuts; Jack scores 2 for dealer
4. **Pegging** — Alternating play to 31 with scoring
5. **Counting** — Non-dealer counts first, then dealer, then crib
6. **Game Over** — First to 121 wins

## Deployment

### Docker (Development)

```bash
docker compose up -d
```

Starts PostgreSQL and the Spring Boot app on port 8080. Requires `JWT_SECRET` environment variable.

### Docker (Alpha)

```bash
docker compose -f docker-compose.alpha.yml up -d
```

Uses Tailscale for private networking. Requires `TS_AUTHKEY`, `TS_HOSTNAME`, `TS_FQDN`, `DB_PASSWORD`, and `JWT_SECRET` environment variables.

## CI

GitHub Actions runs on push/PR to `master`:

- **Backend** — `./gradlew build` + Detekt linting (with PostgreSQL service)
- **Mobile** — `flutter analyze` + `flutter test`
