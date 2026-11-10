# Cribbage Club

[![CI](https://github.com/gannonlawlor/CribbageClub/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/gannonlawlor/CribbageClub/actions/workflows/ci.yml)
[![Secret scanning](https://github.com/gannonlawlor/CribbageClub/actions/workflows/secrets.yml/badge.svg?branch=main)](https://github.com/gannonlawlor/CribbageClub/actions/workflows/secrets.yml)

Cribbage for solo practice and games with friends. Play against the computer
offline, compete online, and review your decisions after each game.

The Flutter app for iOS and Android is the main development focus. This
repository also includes a React web client, a Kotlin server, and a shared Rust
engine for game rules, AI, and analysis.

## Features

- **Offline play** with three AI difficulty levels.
- **Online multiplayer** with matchmaking, private lobbies, friends, and challenges.
- **Post-game analysis and replay** to compare discards and revisit each hand.
- **Daily puzzles, ratings, and leaderboards** for practice and competition.
- **Customizable play** with optional automatic actions, sound, and haptics.

## Run locally

Clone the repository, then start the backend and PostgreSQL with Docker Compose.
Docker and OpenSSL are required for these commands.

```bash
git clone https://github.com/gannonlawlor/CribbageClub.git
cd CribbageClub

# Create private local credentials once. Existing .env files are preserved.
test -e .env || (
  umask 077
  printf 'DB_PASSWORD=%s\nJWT_SECRET=%s\n' \
    "$(openssl rand -hex 24)" "$(openssl rand -hex 32)" > .env
)

docker compose up --build -d
```

The backend runs at `http://localhost:8080`. Explore its API at
[`/swagger-ui.html`](http://localhost:8080/swagger-ui.html) or check
[`/actuator/health`](http://localhost:8080/actuator/health).

Keep `.env` for future runs: changing its database password does not change the
password in an existing database volume. Never commit this file.

To run the mobile or web client, work on the backend without Docker, or run the
tests, see the [development guide](docs/development.md).

## Repository layout

| Directory | Purpose | Stack |
|---|---|---|
| [`mobile/`](mobile/) | iOS and Android app | Flutter, Riverpod |
| [`web/`](web/) | Browser client | React, TypeScript, Vite |
| [`src/`](src/) | Multiplayer, accounts, persistence, and API | Kotlin, Spring Boot, PostgreSQL |
| [`engine/`](engine/) | Shared game rules, AI, and analysis | Rust |

The same Rust engine runs in the mobile app through native bindings, in the
browser through WebAssembly, and on the server through JNA.

## Development and security

See the [development guide](docs/development.md) for setup and checks. Bug reports
should include the platform, reproduction steps, and expected behavior; use
[GitHub Issues](https://github.com/gannonlawlor/CribbageClub/issues).

Runtime credentials must be supplied through environment variables. GitHub
secret scanning, push protection, and Gitleaks checks help prevent accidental
credential commits. The development guide explains how to install the local
commit hook. Keep tokens and private keys out of source code, logs, and issues.

## License

All rights reserved.
