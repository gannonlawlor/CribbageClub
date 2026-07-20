# CLAUDE.md — Web (React)

## Overview

React SPA for playing Cribbage Club in the browser. TypeScript, Tailwind CSS, Zustand for state, React Router for navigation, STOMP/WebSocket for real-time game updates.

## Build & Run

```bash
npm install              # install dependencies
npm run dev              # dev server (Vite, hot reload)
npm run build            # production build (tsc -b && vite build)
npm run build:wasm       # build Rust engine to WASM (wasm-pack, output: ../engine/pkg)
npm test                 # run tests (vitest)
npm run test:watch       # tests in watch mode
npm run lint             # ESLint
```

Requires: Node.js (dev machine uses `/opt/homebrew/opt/node/bin`).

## Project Structure

```
web/src/
├── main.tsx                      # Entry point, React root
├── App.tsx                       # React Router config (15 routes)
├── index.css                     # Tailwind imports + CSS variables
├── api/
│   ├── config.ts                 # API base URL
│   ├── http-client.ts            # Fetch wrapper with JWT auth header
│   ├── rest-client.ts            # All REST endpoint functions
│   └── websocket-client.ts       # STOMP client (connect, subscribe, publish)
├── auth/
│   └── auth-store.ts             # Zustand store: login, register, guest, JWT
├── models/                       # TypeScript interfaces mirroring backend
│   ├── card.ts                   # PlayingCard, Rank, Suit enums, display maps
│   ├── game-state.ts             # GameState, GameStage enum
│   ├── game-action.ts            # GameAction union type
│   ├── game-history-event.ts     # 10 event types matching backend
│   ├── game-response.ts          # GameResponse (state + timing)
│   ├── game-analysis.ts          # GameAnalysis, RoundAnalysis, DiscardOption
│   ├── score-breakdown.ts        # ScoreBreakdown
│   ├── player.ts                 # Player
│   └── ...                       # auth, lobby, friend, puzzle, profile, stats
├── services/
│   └── analysis-cache.ts         # localStorage analysis cache
├── engine/
│   └── wasm-engine.ts            # Rust engine via WASM (wasm-pack build, aliased to
│                                 # ../engine/pkg in vite.config.ts) — puzzle analysis
├── features/
│   ├── landing/                  # Marketing landing page (shown at / when logged out)
│   ├── game/                     # Core gameplay
│   │   ├── GamePage.tsx          # Game board with responsive layout
│   │   ├── game-store.ts         # Zustand: game state, actions, WebSocket subs
│   │   └── components/           # CribbageBoard, CardWidget, HandFan,
│   │                               PlayArea, CutCard, GameControls,
│   │                               StageIndicator, HistoryLog, ScorePopup
│   ├── replay/                   # Game replay viewer
│   │   ├── ReplayPage.tsx        # Step-through replay with transport controls
│   │   └── replay-state.ts       # Snapshot state machine from history events
│   ├── analysis/                 # Post-game discard analysis
│   ├── daily-puzzle/             # 5/day puzzle challenge with streaks
│   ├── home/                     # Dashboard, AI games, active games
│   ├── auth/                     # Login, register, guest
│   ├── friends/                  # Friends list, requests, challenges, search
│   ├── lobby/                    # Lobby browser, join-by-code, waiting room
│   ├── profile/                  # Public player profiles with stats
│   ├── puzzle/                   # Practice puzzles (unlimited, WASM-analyzed)
│   └── ...
├── shared/
│   ├── Layout.tsx                # App shell: nav bar, notification badge
│   └── ...
└── test/
    └── setup.ts                  # Vitest setup (jsdom, testing-library matchers)
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | React 19.2, TypeScript 5.9 |
| Build | Vite 7.3, `@vitejs/plugin-react` |
| Styling | Tailwind CSS 4.1 (`@tailwindcss/vite` plugin) |
| State | Zustand 5.0 (manual stores, no codegen) |
| Routing | React Router 7.5 |
| HTTP | Fetch API via custom `http-client.ts` wrapper |
| WebSocket | `@stomp/stompjs` 7.1 (no SockJS fallback) |
| Animation | Framer Motion (`motion/react`) |
| Testing | Vitest 4.0, React Testing Library, jsdom |

## Routes

| Path | Component | Status |
|------|-----------|--------|
| `/` | RootPage (LandingPage logged out, HomePage logged in) | Complete |
| `/login` | LoginPage | Complete |
| `/upgrade` | UpgradePage | Complete |
| `/game/:gameId` | GamePage | Complete |
| `/analysis/:gameId` | AnalysisPage | Complete |
| `/replay/:gameId` | ReplayPage | Complete |
| `/daily-puzzle` | DailyPuzzlePage | Complete |
| `/history` | HistoryPage | Complete |
| `/leaderboard` | LeaderboardPage | Complete |
| `/friends` | FriendsPage | Complete |
| `/lobbies` | LobbyBrowserPage | Complete |
| `/join` | JoinByCodePage | Complete |
| `/lobby/:lobbyId` | LobbyWaitingPage | Complete |
| `/profile/:userId` | ProfilePage | Complete |
| `/puzzle` | PuzzlePage (practice puzzles) | Complete |

## Key Patterns

### State Management
- **Zustand stores** (not React context): `useGameStore`, `useAuthStore`, `useFriendsStore`, etc.
- Game store manages WebSocket subscriptions lifecycle (subscribe on load, unsubscribe on reset)
- `_actionInFlight` flag prevents WebSocket updates from overwriting optimistic REST responses

### API Layer
- `http-client.ts`: Thin fetch wrapper that auto-attaches JWT from `authStore`, handles JSON parsing, throws on non-OK responses
- `rest-client.ts`: One function per endpoint, typed with TypeScript generics
- `websocket-client.ts`: Singleton STOMP client with `connectWebSocket()`, `subscribe()`, `publish()`

### Game Board
- `CribbageBoard`: Canvas 2D API drawing with proportional scaling (all dimensions derived from canvas width)
- `CardWidget`: Framer Motion animated cards with selection glow, hover lift
- `HandFan`: Overlapping card layout with configurable sizing
- Responsive: `useIsDesktop()` hook (matchMedia 1024px) scales card sizes and switches to two-column layout

### Serialization
- Plain TypeScript interfaces (no codegen, no runtime validation)
- Enums as string enums matching backend UPPER_SNAKE (`GameStage.PEGGING`, `Rank.ACE`)
- Union types with `type` discriminator field matching backend Jackson `@JsonTypeInfo`

## Conventions

- Feature-folder organization (`features/[feature]/`)
- Components in `components/` subdirectory within feature
- Tailwind utility classes (no CSS modules, no styled-components)
- CSS variables for theme colors defined in `index.css`: dark charcoal surfaces (`--bg`, `--bg-deep`, `--surface`), primary action green (`--accent`), rating gold (`--gold`); legacy `--felt-green*` names alias to the charcoal surfaces
- Chess.com-style chrome: left sidebar app shell on desktop (`Layout.tsx`), player bars with Glicko ratings in-game, green primary CTAs
- `lg:` breakpoint (1024px) for desktop-specific styles
- Framer Motion for all animations (card selection, score popups, page transitions)
- Tests colocated with feature files (`*.test.tsx`)
