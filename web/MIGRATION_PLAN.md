# CribbageClub Web Migration Plan

## Motivation

Flutter Web has known pain points: large bundle sizes (~2-4MB), slow initial load, non-standard DOM (CanvasKit vs HTML renderer), poor SEO, and accessibility limitations. A native web stack gives smaller bundles, standard DOM, better tooling, and a more "web-native" feel.

## How Lichess Does It

Lichess does **not** use Flutter for their web player. They have **completely separate codebases**:

| | Web (lichess.org) | Mobile (lichess-org/mobile) |
|---|---|---|
| **Language** | TypeScript | Dart (Flutter) |
| **Framework** | Snabbdom (minimal vDOM) | Flutter |
| **Chess board** | [chessground](https://github.com/lichess-org/chessground) (custom TS + DOM) | [flutter-chessground](https://github.com/lichess-org/flutter-chessground) (Dart) |
| **Chess logic** | [chessops](https://github.com/niklasf/chessops) (TypeScript) | [dartchess](https://github.com/lichess-org/dartchess) (Dart port of chessops) |
| **Engine** | Stockfish WASM | Stockfish via C++ FFI |
| **Repo** | [lichess-org/lila](https://github.com/lichess-org/lila) (`ui/` directory) | [lichess-org/mobile](https://github.com/lichess-org/mobile) |

The web frontend lives inside `lila/ui/` as a pnpm monorepo with ~20+ TypeScript modules (`ui/round/`, `ui/analyse/`, `ui/puzzle/`, `ui/lobby/`, etc.), built with **esbuild**. The backend (Scala/Play) does server-side rendering with Scalatags, then TypeScript hydrates client-side.

Key insight: **Lichess duplicates core logic** across three languages (TS, Dart, Scala) with idiomatic ports, rather than sharing code. Our Rust engine via WASM is a more efficient sharing strategy — one codebase powering all platforms.

## Recommended Stack

| Concern | Choice | Rationale |
|---------|--------|-----------|
| **Framework** | React (or Preact for size) | Largest ecosystem, best tooling, easy to hire for |
| **Language** | TypeScript | Type safety, matches our model complexity |
| **Bundler** | Vite | Fast dev server, native ESM, easy WASM integration |
| **State** | Zustand or Jotai | Lightweight, similar mental model to Riverpod |
| **Routing** | React Router v7 or TanStack Router | Auth guards, nested layouts |
| **HTTP** | Fetch API + thin wrapper | JWT interceptor equivalent |
| **WebSocket** | @stomp/stompjs | Direct STOMP support, matches our backend |
| **Styling** | Tailwind CSS or CSS Modules | Utility-first or scoped styles |
| **Animation** | Framer Motion | Declarative, handles card/board animations |
| **WASM** | wasm-pack (direct) | Rust engine compiled to WASM, no flutter_rust_bridge |
| **Local storage** | localStorage + IndexedDB | Replace SharedPreferences |
| **Testing** | Vitest + React Testing Library | Fast, modern |

## What We Keep

**Rust engine** — already compiles to WASM (`frontend/web/pkg/`). Switch from flutter_rust_bridge's WASM glue to standard `wasm-pack` / `wasm-bindgen` bindings. The 12 FFI functions (`engine_new`, `analyze_discards_json`, etc.) become direct JS imports from the WASM module.

**Entire backend** — REST endpoints, STOMP WebSocket, auth, everything stays untouched.

## What Must Be Rebuilt

The Flutter frontend has ~65+ Dart files across these layers:

- **20+ freezed models** — PlayingCard, GameState, GameAction, GameHistoryEvent, GameAnalysis, etc.
- **State management** — Riverpod providers (auth, game, analysis, notifications)
- **API client** — Dio HTTP with JWT interceptor, STOMP WebSocket with reconnection
- **15+ game widgets** — CribbageBoard, CardWidget, HandFan, ScorePopup, etc.
- **11 feature modules** — game, auth, home, analysis, daily_puzzle, friends, lobby, profile, puzzle, replay
- **Animation system** — Card dealing, play, peg movement, score popups
- **Routing** — GoRouter with auth guard

## Architecture

```
┌─────────────────────────────────────────┐
│              Monorepo                    │
├──────────┬──────────┬──────────┬────────┤
│ web/     │frontend/ │ engine/  │ src/   │
│ (React)  │(Flutter) │ (Rust)   │(Spring)│
│ TS+Vite  │iOS/Andr. │          │        │
│          │          │          │        │
│ ┌──────┐ │          │ ┌──────┐ │        │
│ │WASM  │◄├──────────┤►│ JNA  │►│        │
│ │import│ │   FRB    │ │      │ │        │
│ └──────┘ │          │ └──────┘ │        │
└──────────┴──────────┴──────────┴────────┘
```

The Rust engine stays central, compiled to WASM for web (via `wasm-pack`) and linked via flutter_rust_bridge for mobile. The backend is unchanged.

---

## Migration Phases

### Phase 0: Setup (~1 week)

- Scaffold `web/` directory with Vite + React + TypeScript
- Configure WASM integration with existing Rust engine via `wasm-pack`
- Set up CI for web build alongside existing Flutter CI
- Deploy to a separate route/subdomain initially (e.g., `beta.cribbageclub.com`)

### Phase 1: Foundation (~2 weeks)

Port the **core infrastructure**:

- **TypeScript models** — Port all 20+ freezed models to TypeScript interfaces/types with discriminated unions for sealed classes
  - PlayingCard (Rank + Suit enums)
  - GameState, GameStage, Player
  - GameAction union (DiscardToCrib, PlayCard, CutDeck, Go, CountHand, Forfeit)
  - GameHistoryEvent union (8 event types)
  - GameAnalysis > RoundAnalysis > PlayerRoundAnalysis > DiscardOption
  - Lobby, Friend, Puzzle, AuthState, etc.
- **API client** — Dio → Fetch wrapper with JWT interceptor, 401 auto-logout
- **STOMP client** — @stomp/stompjs connecting to `/ws`, same subscriptions:
  - `/topic/game/{gameId}` — Game state updates
  - `/user/queue/game-state` — Personal game updates
  - `/user/queue/errors` — Error messages
- **Auth flow** — Login/register/guest/upgrade screens, JWT persistence in localStorage
- **Routing** — React Router with auth guard (redirect to login when unauthenticated)
- **State management** — Zustand stores for auth, game state, notifications

### Phase 2: Game Play (~3-4 weeks)

The heaviest lift — port the **core game experience**:

- **Card rendering** — SVG or Canvas-based cards (2.5:3.5 aspect ratio). Consider an existing library or build custom SVG components
- **Cribbage board** — SVG or Canvas with peg animations. Most complex custom widget (~perimeter board wrapping three edges)
- **Hand fan layout** — CSS transforms for fanned card display with selection
- **Game screen** — Port the 839-line `game_screen.dart`: stage indicator, card selection, play area, scoring overlays
- **Online game state** — REST + WebSocket hybrid: REST for action ordering, WebSocket for push updates
- **Local AI games** — WASM engine integration: `engine_new()` → `engine_apply_action_json()` → `engine_process_ai_json()` loop
- **Animations** — Framer Motion for card dealing, play, peg movement, score popups
- **Turn timer / time bank** — Real-time sync with server

### Phase 3: Analysis & Puzzles (~2 weeks)

- **Analysis screen** — Show all 15 discard options with EV calculations from Rust WASM
- **Explain keep** — Algorithmic reasoning display
- **Analysis caching** — localStorage → server → WASM compute → cache everywhere
- **Daily puzzles** — 5-puzzle sets, streak tracking, score breakdown, leaderboard comparison

### Phase 4: Social & Secondary Features (~2 weeks)

- **Game history** — List view, local storage (IndexedDB for 50-game cap), server sync
- **Game replay** — Step-through with animation playback, speed control
- **Friends** — Friend list, search, requests, notifications
- **Lobbies** — Create, join by code, quick match
- **Leaderboard** — Top 10 display
- **Player profiles** — Public profile pages

### Phase 5: Polish & Cutover (~1-2 weeks)

- **Responsive design** — Mobile-web friendly layouts (CSS breakpoints)
- **PWA support** — Service worker, manifest, offline capability
- **Performance** — Code splitting, lazy loading routes, WASM streaming compilation
- **Bundle optimization** — Target <500KB initial load (vs Flutter's 2-4MB)
- **A/B testing** — Run both versions, compare engagement
- **Redirect** — Point main domain to new web app, keep Flutter for iOS/Android only

## Estimated Timeline

~10-12 weeks for a solo developer working full-time. The game screen + cribbage board + animations are the critical path.

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| WASM integration without flutter_rust_bridge | Rust functions already use JSON interchange (`*_json` suffix). Standard wasm-bindgen can expose the same interface easily |
| Card/board animation fidelity | Framer Motion + SVG can replicate Flutter's CustomPaint. Prototype the cribbage board first |
| STOMP compatibility | @stomp/stompjs is mature, same protocol — should be drop-in |
| Feature parity during transition | Keep Flutter web running until React web has full parity |
| Maintaining two frontends long-term | Only during transition. Once web is React, Flutter is mobile-only |

## Lessons from Lichess

1. **Separate repos/directories** for web and mobile — don't try to share UI code
2. **Thin, fast web bundle** — Lichess's board (chessground) is 10KB gzipped
3. **Server-side rendering for SEO pages** — even if the game itself is a SPA
4. **Modular UI packages** — each feature as its own module (analysis, game, puzzle)
5. **Keep the engine in one language** — our Rust-everywhere approach is better than their 3-language duplication
