# CLAUDE.md — Mobile (Flutter)

## Overview

Flutter app targeting iOS and Android from a single Dart 3.11+ codebase. Uses Riverpod for state, GoRouter for routing, Dio for HTTP, STOMP for WebSocket, and flutter_rust_bridge for native Rust FFI.

## Build & Run

```bash
flutter pub get                   # install dependencies
flutter run -d chrome             # run on web
flutter test                      # run tests
flutter analyze                   # static analysis
dart run build_runner build       # regenerate freezed/json_serializable code

# Development (local backend)
flutter run --flavor dev                                              # connected device

# Alpha (Tailscale backend)
flutter run --flavor alpha --dart-define-from-file=dart_define/alpha.json

# Release builds
flutter build apk --flavor alpha --dart-define-from-file=dart_define/alpha.json
flutter build ipa --flavor alpha --dart-define-from-file=dart_define/alpha.json
```

## Project Structure

```
mobile/lib/
├── main.dart                     # Entry point, ProviderScope
├── app.dart                      # MaterialApp.router, GoRouter, theme
├── config/
│   ├── routes.dart               # 12 routes with auth guard
│   ├── theme.dart                # Felt-green dark theme, card dimensions
│   └── constants.dart            # API base URL, timeouts
├── core/
│   ├── api/
│   │   ├── rest_client.dart      # Dio HTTP client with JWT interceptor
│   │   └── websocket_client.dart # STOMP over SockJS with reconnection
│   ├── auth/
│   │   ├── auth_provider.dart    # AuthNotifier (login/register/guest/upgrade)
│   │   └── auth_service.dart     # JWT persistence via SharedPreferences
│   ├── engine/
│   │   ├── local_game_service.dart     # Rust FFI for game simulation
│   │   └── local_analysis_service.dart # Rust FFI for discard analysis
│   ├── models/                   # freezed + json_serializable models
│   │   ├── card.dart             # PlayingCard, Rank, Suit
│   │   ├── game_state.dart       # GameState, GameStage, Player
│   │   ├── game_action.dart      # Sealed union: DiscardToCrib, PlayCard, etc.
│   │   ├── game_history_event.dart # 8 event types matching backend
│   │   ├── game_analysis.dart    # GameAnalysis, RoundAnalysis, DiscardOption
│   │   └── ...                   # lobby, auth, friends, puzzle, stats models
│   └── services/
│       ├── analysis_cache_service.dart    # Local analysis cache (SharedPreferences)
│       ├── local_game_history_service.dart # Local game persistence (50-game cap)
│       ├── game_upload_service.dart        # Sync local games to server
│       └── game_feedback_service.dart      # Haptics + system sound
├── features/
│   ├── game/          # Core gameplay (online + local AI)
│   ├── auth/          # Login, register, guest, upgrade screens
│   ├── home/          # Dashboard, game history, leaderboard
│   ├── analysis/      # Post-game discard analysis
│   ├── replay/        # Step-through game replay
│   ├── daily_puzzle/  # Daily puzzle with streak tracking
│   ├── friends/       # Friend list, requests, challenges
│   ├── lobby/         # Lobby waiting room
│   └── puzzle/        # Custom puzzle mode (skeleton)
├── shared/
│   ├── widgets/       # LoadingOverlay, AuthRequired
│   └── utils/         # CardUtils (sorting, display)
└── src/rust/          # flutter_rust_bridge generated bindings
```

## State Management (Riverpod)

Manual providers (no riverpod_generator — incompatible with Dart 3.11 analyzer).

**Key providers:**
- `authProvider` — StateNotifierProvider for auth state
- `restClientProvider` / `webSocketClientProvider` — Singleton service providers
- `gameNotifierProvider(gameId)` — Online game state per game
- `localGameNotifierProvider(gameId)` — Local AI game state per game
- `analysisProvider(gameId)` — FutureProvider with multi-layer cache
- `selectedCardsProvider(gameId)` — Card selection during discard
- `gameAnimationProvider(gameId)` — Animation controller per game

## Key Patterns

- **Local vs server games**: `isLocalGame(gameId)` checks `gameId.startsWith('local_')`. Local games use Rust FFI directly; server games use REST + WebSocket.
- **Analysis caching**: Local cache → server cache → on-device Rust FFI compute → cache everywhere → fire-and-forget upload to server.
- **Card model**: Named `PlayingCard` to avoid conflict with Flutter's `Card` widget.
- **Null-aware map elements**: Dart 3.11 syntax `'key': ?nullableValue` (? on value, not key).
- **WebSocket**: STOMP with exponential backoff reconnection. REST for action ordering guarantees; WebSocket for push updates.
- **Game actions**: REST-first (not WebSocket) to ensure ordering. WebSocket updates suppressed during REST in-flight (`_actionInFlight` flag).

## Models & Serialization

- All models use `freezed` + `json_serializable` with `build_runner`
- Sealed unions use `@FreezedUnionValue('TypeName')` to match backend Jackson discriminators
- Enums use `@JsonValue('UPPER_SNAKE')` to match backend
- Regenerate with: `dart run build_runner build`

## Feature Status

| Feature | Status | Notes |
|---------|--------|-------|
| Local AI games | Complete | 3 difficulty levels via Rust engine |
| Online multiplayer | Complete | REST + WebSocket |
| Auth (login/register/guest) | Complete | JWT, guest upgrade flow |
| Game screen + board | ~85% | Cards, board, animations, controls |
| Discard analysis | ~85% | Multi-layer cache, Rust FFI compute |
| Game replay | ~70% | Step-through playback, speed control |
| Daily puzzle | ~85% | Deterministic seeding, streak tracking |
| Game history | ~90% | Local + server, upload sync |
| Friends | ~60% | Skeleton UI, REST integration |
| Lobbies | ~10% | Minimal waiting room |
| Leaderboard | ~40% | Basic list display |
| Sound/haptics | ~20% | SystemSound only, no custom audio |

## Build Notes

- `build_runner` v2.5.x uses older analyzer — generated code succeeds for model files even if main.dart has Dart 3.11 syntax
- Removed `riverpod_generator` and `riverpod_lint` due to analyzer_plugin incompatibility with Dart 3.11
- WASM build for Rust engine: `mobile/web/pkg/` contains compiled WASM + JS glue
- `flutter_rust_bridge.yaml` config: `default_dart_async: false` (sync FFI calls)
