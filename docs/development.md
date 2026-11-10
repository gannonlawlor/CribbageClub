# Development

Start with the [root README](../README.md) for the Docker backend setup. Install
only the tools needed for the component you want to work on.

## Backend

For native development, install JDK 21 and Rust. The Gradle wrapper builds the
Rust engine before compiling the Kotlin server. PostgreSQL 16 can run through
Docker Compose.

After creating `.env` using the README, run these commands from the repository
root. Source only an environment file you created and trust.

```bash
set -a
. ./.env
set +a
export DATABASE_PASSWORD="$DB_PASSWORD"

# Stop the containerized app if it is already using port 8080.
docker compose stop app
docker compose up -d postgres
./gradlew bootRun
```

`DB_PASSWORD` configures the Compose database; `DATABASE_PASSWORD` is the
server's environment variable. `JWT_SECRET` is required in every environment
and must be at least 32 bytes. Generate random credentials, and keep the same
values across restarts. Tests use an in-memory H2 database and an ephemeral
signing key.

```bash
./gradlew build
```

The server listens on port 8080. API documentation is available at
`http://localhost:8080/swagger-ui.html`; OpenAPI JSON is at `/v3/api-docs`.
Multiplayer updates use STOMP over SockJS at `/ws`.

## Mobile

Install Flutter with Dart 3.11 or newer and the Rust toolchain. iOS builds also
need macOS and Xcode; Android builds need the Android SDK.

```bash
cd mobile
flutter pub get
dart run build_runner build
flutter run --flavor dev
```

The development flavor uses `http://localhost:8080` by default. On the Android
emulator, point the app at the host machine:

```bash
flutter run --flavor dev --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

For a physical device, use a backend address reachable from that device. See
[the mobile guide](../mobile/README.md) for app structure and build flavors.

```bash
flutter analyze lib
cargo build --release --manifest-path ../engine/Cargo.toml
flutter test
```

Building the native Rust library first makes it available to the Flutter test
host. Analysis is scoped to `lib` to avoid diagnostics from vendored build tools.

## Web

Install Node.js 22.12 or newer, npm, Rust, and `wasm-pack`. Start the backend,
then run:

```bash
cd web
npm ci
npm run build:wasm
npm run dev
```

Open `http://localhost:5173`. Vite proxies `/api` and `/ws` to the backend on port
8080. Production builds regenerate the WebAssembly package automatically.

```bash
npm run build
npm test
```

## Rust engine

```bash
cd engine
cargo test
```

The engine is shared by all clients and the server. Changes to its bindings may
also require rebuilding the relevant native or WebAssembly package.

## Secret checks

Install the repository's commit hook with [uv](https://docs.astral.sh/uv/):

```bash
uvx pre-commit install --install-hooks
```

If you already have `pre-commit`, use `pre-commit install --install-hooks`.
Gitleaks checks staged changes for credential patterns and rejects hardcoded
runtime passwords or signing-key fallbacks. Never commit `.env`, service-account
credentials, signing keys, or provisioning profiles.

GitHub Actions scans history for secrets on every push and pull request. The CI
workflow selects backend and mobile checks based on changed paths. Backend
changes run build/test and Detekt jobs; successful backend pushes to `main` also
publish a container image. Web checks are currently run locally using the
commands above.
