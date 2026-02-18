# Frontend Plan — Cribbage Club

## Vision

A cross-platform (iOS, Android, Web) cribbage app comparable to Chess.com and LiChess in quality and feel. Fast, polished, real-time multiplayer with depth features like post-game analysis and daily puzzles.

## Tech Stack

- **Framework:** Flutter (single codebase for web, iOS, Android)
- **Language:** Dart
- **State Management:** Riverpod
- **Routing:** GoRouter
- **HTTP Client:** Dio
- **WebSocket:** `stomp_dart_client` + `web_socket_channel`
- **Code Generation:** `freezed` + `json_serializable` for models
- **Local Storage:** `shared_preferences` (auth tokens), `drift` or `hive` (offline cache)
- **Push Notifications:** Firebase Cloud Messaging
- **Audio:** `audioplayers` (card sounds, peg clicks)

## Why Flutter

- Canvas-based rendering is ideal for a card game — card fan layouts, peg board, dealing animations are all custom drawing, which Flutter does natively
- Pixel-identical UI across all three platforms from one codebase
- Excellent animation framework (`AnimatedWidget`, `CustomPainter`, implicit/explicit animations)
- WASM compilation for web improves load times
- Solo developer: one widget tree, one test suite, one build pipeline

## Project Location

The Flutter project lives at `frontend/` in the monorepo alongside the Spring Boot backend. The toolchains are independent — Gradle ignores `frontend/`, Flutter ignores `src/`.

```
CribbageClub/
├── src/                          # Spring Boot backend
├── frontend/                     # Flutter project root
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart              # MaterialApp, GoRouter, theme
│   │   ├── config/
│   │   │   ├── routes.dart       # Route definitions
│   │   │   ├── theme.dart        # Colors, typography, card dimensions
│   │   │   └── constants.dart    # API base URL, WebSocket URL
│   │   ├── core/
│   │   │   ├── api/
│   │   │   │   ├── rest_client.dart       # Dio client for REST endpoints
│   │   │   │   └── websocket_client.dart  # STOMP client (connect, subscribe, send)
│   │   │   ├── models/                    # Mirrors backend Kotlin models
│   │   │   │   ├── card.dart              # Card, Rank, Suit (freezed)
│   │   │   │   ├── game_state.dart        # GameState, GameStage
│   │   │   │   ├── game_action.dart       # Sealed action types (freezed)
│   │   │   │   ├── game_history_event.dart
│   │   │   │   ├── lobby.dart
│   │   │   │   └── player.dart
│   │   │   └── auth/
│   │   │       └── auth_service.dart      # JWT storage, refresh, login/register
│   │   ├── features/
│   │   │   ├── home/                      # Main menu / dashboard
│   │   │   ├── game/
│   │   │   │   ├── state/                 # Riverpod providers for game state
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── cribbage_board.dart    # Peg board (CustomPainter)
│   │   │   │   │   ├── card_widget.dart       # Single card rendering
│   │   │   │   │   ├── hand_fan.dart          # Player's hand layout
│   │   │   │   │   ├── play_area.dart         # Center table for pegging
│   │   │   │   │   ├── crib_area.dart         # Crib display
│   │   │   │   │   ├── cut_card.dart          # Cut card with flip animation
│   │   │   │   │   ├── score_popup.dart       # Animated scoring overlay
│   │   │   │   │   └── game_controls.dart     # Action buttons, turn prompts
│   │   │   │   └── screens/
│   │   │   │       └── game_screen.dart       # Composes all game widgets
│   │   │   ├── lobby/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── lobby_list_screen.dart
│   │   │   │   │   └── lobby_screen.dart
│   │   │   │   └── state/
│   │   │   ├── profile/                   # Stats, rating, match history
│   │   │   ├── analysis/                  # Post-game hand review
│   │   │   └── settings/
│   │   └── shared/
│   │       ├── widgets/                   # Reusable UI components
│   │       └── utils/                     # Formatters, constants
│   ├── test/
│   ├── assets/
│   │   ├── images/                        # Card faces, card backs, board texture
│   │   └── sounds/                        # Card slap, peg click, shuffle
│   ├── pubspec.yaml
│   └── analysis_options.yaml
├── CLAUDE.md
├── TODO.md
├── FRONTEND.md
└── docker-compose.yml
```

## Key Riverpod Providers

```
gameStateProvider(gameId)     # Current GameState, updated via WebSocket
webSocketProvider             # STOMP connection lifecycle
authProvider                  # JWT token, user info, login state
lobbyListProvider             # Available lobbies, auto-refreshing
```

## Backend Integration

### REST Endpoints Used

| Client Action | Method | Endpoint |
|--------------|--------|----------|
| Login / Register | POST | `/api/auth/login`, `/api/auth/register` |
| List games | GET | `/api/games` |
| Get game state | GET | `/api/games/{gameId}` |
| Create AI game | POST | `/api/games/ai` |
| Apply action | POST | `/api/games/{gameId}/actions` |
| List lobbies | GET | `/api/lobbies/waiting` |
| Create lobby | POST | `/api/lobbies` |
| Join lobby | POST | `/api/lobbies/{lobbyId}/join` |
| Leave lobby | POST | `/api/lobbies/{lobbyId}/leave` |
| Start game | POST | `/api/lobbies/{lobbyId}/start` |

### WebSocket (STOMP)

| Direction | Destination | Purpose |
|-----------|------------|---------|
| Connect | `/ws` | SockJS fallback handshake |
| Send | `/app/game/action` | Send GameAction |
| Send | `/app/game/join` | Join a game's WebSocket topic |
| Send | `/app/game/leave` | Leave a game's WebSocket topic |
| Send | `/app/game/state` | Request current state |
| Subscribe | `/topic/game/{gameId}` | Game state updates |
| Subscribe | `/topic/game/{gameId}/players` | Player join/leave events |
| Subscribe | `/queue/game-state` | Direct state responses |
| Subscribe | `/queue/errors` | Error messages |

### Optimistic UI

For responsiveness, apply actions locally before server confirmation:
1. Player taps a card to play it
2. Animate the card moving to the play area immediately
3. Send the action to the server via WebSocket
4. When server state arrives, reconcile (should match; if not, snap back)

## Screens

### Home Screen
- Large "Play" button (Chess.com style)
- Options: Quick Match, Play vs AI, Browse Lobbies, Create Private Game
- Current rating and recent results summary
- Navigation to Profile, Settings

### Game Screen (core — 80% of effort)

```
┌──────────────────────────────────┐
│  Opponent name          Score: 45 │
│  ┌────────────────────────────┐  │
│  │  Opponent's hand (backs)   │  │
│  └────────────────────────────┘  │
│                                   │
│        ┌──────────┐              │
│        │ Cut Card │    [Crib]    │
│        └──────────┘              │
│                                   │
│   ┌── Play Area ──────────────┐  │
│   │ Played cards    Count: 23  │  │
│   └────────────────────────────┘  │
│                                   │
│  ┌────────────────────────────┐  │
│  │   Your hand (face up)      │  │
│  └────────────────────────────┘  │
│  Your name              Score: 32 │
│                                   │
│  ┌────────────────────────────┐  │
│  │     Cribbage Board         │  │
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

- **Cribbage board**: CustomPainter with two peg tracks, animated peg movement on score changes
- **Cards**: Tappable to select (discard phase), tappable/draggable to play (pegging)
- **Stage indicator**: "Your turn to discard", "Waiting for opponent", "Pegging — count is 23"
- **Score popups**: Animated "+2 for 15s", "+6 for a run of 3" overlays
- **History log**: Expandable drawer showing game events

### Lobby Browser
- List of open games: player name, rating, time created
- Create game with options
- Quick match for instant pairing

### Profile / Stats
- Rating (Elo or Glicko-2)
- Win/loss record, average hand score
- Game history with tap to review

### Post-Game Analysis
- Step-by-step replay of the hand
- Optimal discard comparison ("You discarded 5-6, optimal was 4-7: +2 expected points")
- Score breakdown per round

## Phased Development

### Phase 1: Playable Core
Get a working game you can actually play.

- Flutter project setup (routing, Riverpod, theme)
- REST client + STOMP WebSocket client
- Dart models mirroring backend types (freezed + json_serializable)
- Game screen with basic card rendering (tap to select, no animations)
- Score display (simple numbers, no peg board yet)
- Play vs AI flow (POST `/api/games/ai`, WebSocket for updates)
- Basic auth (login/register, JWT storage)

### Phase 2: Game Feel
Make it feel like a real card game.

- Card dealing animation (slide from deck)
- Card play animation (hand to play area)
- Cut card flip animation
- Cribbage board with animated pegs (CustomPainter)
- Score popups with scoring descriptions
- Haptic feedback on mobile
- Sound effects (card play, peg movement, shuffle)
- "Waiting for opponent" indicator
- Stage transition animations

### Phase 3: Multiplayer & Social
Real human-vs-human play.

- Lobby browser screen
- Create / join / leave lobby
- Quick match / matchmaking
- Push notifications ("It's your turn") via FCM
- In-game communication (predefined messages: "Nice hand!", "Good game")
- Friend system, direct challenges

### Phase 4: Retention & Depth
What makes Chess.com/LiChess sticky.

- Post-game analysis with optimal discard comparison
- Game replay (step through any completed game)
- Rating system (Elo or Glicko-2)
- Leaderboard
- Stats dashboard (win rate, avg hand score, best hand)
- Daily puzzle: "What's the optimal discard?" (cribbage equivalent of chess puzzles)

### Phase 5: Platform Polish
Ship-ready quality.

- Responsive layouts (phone portrait, tablet landscape, desktop wide)
- Keyboard shortcuts for web (number keys to select cards, Enter to confirm)
- Dark mode
- App store assets and metadata
- Web PWA support (installable from browser)
- Performance profiling and optimization

### Frontend TODO — Guest Mode, Private Lobbies, Leaderboard

These tasks correspond to the backend features added in V2 (guest mode, private lobbies, enriched leaderboard).

#### Guest Mode
- Add "Play as Guest" button on login/register screen — calls `POST /api/auth/guest`
- Store guest JWT the same as regular JWT (Dio interceptor works unchanged)
- Show upgrade banner/modal after first AI game prompting guest to create an account
- Add upgrade screen — username, password, optional display name — calls `POST /api/auth/upgrade`
- Update `authProvider` to track `isGuest` flag from `/api/auth/me` response

#### Private Lobbies
- Add "Create Private Game" option on home screen — calls `POST /api/lobbies` with `isPrivate: true`
- Show invite code (e.g. `CRIB-A3X7`) on lobby waiting screen with copy-to-clipboard button
- Add "Join by Code" screen/dialog — text input for invite code, calls `POST /api/lobbies/join-by-code`
- Handle `JoinByCodeResult` response — if `gameState` is non-null, navigate directly to game screen (auto-started)
- Add share button to generate a deep link (e.g. `https://cribbageclub.com/join/CRIB-A3X7`) for invite codes

#### Active Games & History
- Update home screen to show active games list — calls `GET /api/games/me`
- Add game history screen — calls `GET /api/games/me/history`
- Tap an active game to resume it, tap a completed game to review it

#### Leaderboard
- Add leaderboard screen — calls `GET /api/stats/leaderboard`
- Display `displayName` instead of `playerId` for each entry
- Link from home screen / profile section

#### REST Endpoints Added
| Client Action | Method | Endpoint |
|--------------|--------|----------|
| Play as guest | POST | `/api/auth/guest` |
| Upgrade guest | POST | `/api/auth/upgrade` |
| Create private lobby | POST | `/api/lobbies` (with `isPrivate: true`) |
| Join by invite code | POST | `/api/lobbies/join-by-code` |
| My active games | GET | `/api/games/me` |
| My game history | GET | `/api/games/me/history` |
| Leaderboard (enriched) | GET | `/api/stats/leaderboard` |

## Backend Prerequisites

These backend TODO items should be completed before or alongside frontend development:

1. **CORS configuration** (TODO #7c) — browser clients will be blocked without this
2. ~~**PlayerGameView DTO** (TODO #1)~~ — done (GameStateFilter now filters per-player)
3. **WebSocket authentication** (TODO #2) — needed before multiplayer goes live

## Design Inspiration

- **Chess.com**: Clean home screen with prominent "Play" button, smooth piece animations, post-game analysis, daily puzzles, rating system
- **LiChess**: Fast and lightweight feel, free analysis tools, clean game board focus, responsive across devices
- **Target feel**: Fast turn response (<100ms perceived), smooth 60fps card animations, minimal UI chrome during gameplay
