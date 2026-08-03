# Cribbage Club — Mobile

Flutter app for iOS and Android built from a single Dart 3.11+ codebase. Supports both online multiplayer (via REST + WebSocket) and offline AI games (via native Rust FFI).

## Getting Started

### Prerequisites

- Flutter SDK 3.11+ (stable channel)
- Xcode (for iOS builds)
- Android Studio or Android SDK (for Android builds)
- Rust toolchain (for building the native engine)

### Setup

```bash
flutter pub get                      # install dependencies
dart run build_runner build          # generate freezed/json_serializable code
flutter run                          # run on connected device or simulator
```

### Build Flavors

```bash
# Development (local backend at localhost:8080)
flutter run --flavor dev

# Alpha flavor (public staging backend)
flutter run --flavor alpha --dart-define-from-file=dart_define/alpha.json

# Release builds
flutter build apk --flavor alpha --dart-define-from-file=dart_define/alpha.json
flutter build ipa --flavor alpha --dart-define-from-file=dart_define/alpha.json
```

### Testing

```bash
flutter test                         # run all tests
flutter analyze                      # static analysis
```

## Project Structure

```
mobile/lib/
├── main.dart                        # Entry point, provider setup
├── app.dart                         # MaterialApp.router, GoRouter, theme
├── config/
│   ├── constants.dart               # API URL, timeouts, animation durations, storage keys
│   ├── routes.dart                  # 12 routes with auth guard
│   └── theme/                       # Light/dark themes, color system
├── core/
│   ├── api/
│   │   ├── rest_client.dart         # Dio HTTP client with JWT interceptor
│   │   └── websocket_client.dart    # STOMP over SockJS with reconnection
│   ├── auth/
│   │   ├── auth_provider.dart       # AuthNotifier (login/register/guest/upgrade)
│   │   └── auth_service.dart        # JWT persistence via SharedPreferences
│   ├── engine/
│   │   ├── local_game_service.dart  # Rust FFI for game simulation
│   │   └── local_analysis_service.dart  # Rust FFI for discard analysis
│   ├── models/                      # freezed + json_serializable models
│   │   ├── card.dart                # PlayingCard, Rank, Suit
│   │   ├── game_state.dart          # GameState, GameStage, Player
│   │   ├── game_action.dart         # Sealed union: DiscardToCrib, PlayCard, etc.
│   │   ├── game_history_event.dart  # 8+ event types matching backend
│   │   └── game_analysis.dart       # GameAnalysis, RoundAnalysis, DiscardOption
│   └── services/
│       ├── settings_service.dart    # SharedPreferences read/write for all settings
│       ├── settings_provider.dart   # SettingsState + SettingsNotifier (Riverpod)
│       ├── analysis_cache_service.dart   # Local analysis cache
│       ├── local_game_history_service.dart  # Local game persistence (50-game cap)
│       ├── game_upload_service.dart  # Sync local games to server on login
│       └── game_feedback_service.dart  # Haptics + system sounds
├── features/
│   ├── game/                        # Core gameplay (online + local AI)
│   │   ├── screens/game_screen.dart # Main game board
│   │   ├── widgets/                 # HandFan, PlayArea, CribArea, CribbageBoard,
│   │   │                            # GameControls, ScorePopupOverlay, etc.
│   │   ├── state/                   # GameNotifier, LocalGameNotifier, providers
│   │   └── animation/              # GameAnimationController, AnimationEvent
│   ├── auth/                        # Login, register, guest, upgrade screens
│   ├── home/                        # Dashboard, game history, leaderboard
│   ├── analysis/                    # Post-game discard analysis
│   ├── replay/                      # Step-through game replay
│   ├── daily_puzzle/                # Daily puzzle with streak tracking
│   ├── friends/                     # Friend list, requests, challenges
│   ├── lobby/                       # Lobby browser and waiting room
│   ├── settings/                    # Settings screen (appearance, play style, audio)
│   └── puzzle/                      # Custom puzzle mode (skeleton)
├── shared/
│   ├── widgets/                     # LoadingOverlay, AuthRequired
│   └── utils/                       # CardUtils (sorting, display)
└── src/rust/                        # flutter_rust_bridge generated bindings
```

## State Management

Riverpod with manual providers (no codegen — incompatible with Dart 3.11 analyzer).

**Key providers:**

| Provider | Type | Purpose |
|----------|------|---------|
| `authProvider` | StateNotifierProvider | Auth state (login, register, guest, upgrade) |
| `settingsProvider` | StateNotifierProvider | All app settings (theme, sound, play style) |
| `gameNotifierProvider(gameId)` | StateNotifierProvider.family | Online game state |
| `localGameNotifierProvider(gameId)` | StateNotifierProvider.family | Local AI game state |
| `analysisProvider(gameId)` | FutureProvider.family | Multi-layer analysis cache |
| `selectedCardsProvider(gameId)` | StateProvider.family | Card selection during discard |
| `gameAnimationProvider(gameId)` | Provider.family | Animation controller per game |

## Key Patterns

- **Local vs server games**: `isLocalGame(gameId)` checks `gameId.startsWith('local_')`. Local games use Rust FFI directly; server games use REST + WebSocket.
- **Analysis caching**: Local cache -> server cache -> on-device Rust compute -> cache everywhere -> fire-and-forget upload to server.
- **Card model**: Named `PlayingCard` to avoid conflict with Flutter's `Card` widget.
- **WebSocket**: STOMP with exponential backoff reconnection. REST for action ordering; WebSocket for push updates.
- **Game actions**: REST-first (not WebSocket) to ensure ordering. WebSocket updates suppressed during REST in-flight.

## Settings

Settings are persisted via SharedPreferences and managed through Riverpod.

| Setting | Default | Description |
|---------|---------|-------------|
| Dark Mode | OFF | Casino felt dark theme |
| Sound Effects | ON | Card, score, and game sounds |
| Haptic Feedback | ON | Vibration on card play and scoring |
| Auto-Deal | ON | Automatically deal cards |
| Auto-Cut Deck | ON | Automatically cut the deck |
| Auto-Go | ON | Automatically say Go when no cards can be played |
| Auto-Play All Cards | OFF | Tap to play or discard instantly (skips confirmation) |
| Auto-Play During Pegging | ON | Tap to play cards during pegging without confirm button |
| Animation Speed | 1.0x | Scales all animation durations (0.5x to 2.0x) |

## Models & Serialization

- All models use `freezed` + `json_serializable` with `build_runner`
- Sealed unions use `@FreezedUnionValue('TypeName')` to match backend Jackson discriminators
- Enums use `@JsonValue('UPPER_SNAKE')` to match backend
- Regenerate with: `dart run build_runner build`

## Build Notes

- `build_runner` v2.5.x uses an older analyzer — generated code succeeds even with Dart 3.11 syntax in app code
- Removed `riverpod_generator` and `riverpod_lint` due to analyzer_plugin incompatibility with Dart 3.11
- Rust engine bindings generated by flutter_rust_bridge with `default_dart_async: false` (sync FFI calls)
- WASM build for web at `mobile/web/pkg/`
