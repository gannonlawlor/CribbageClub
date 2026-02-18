# CLAUDE.md — Engine (Rust)

## Overview

Rust crate (`cribbage-engine`) implementing the complete cribbage game engine, three AI difficulty levels, and discard analysis. Consumed via:
- **Mobile (Flutter)**: flutter_rust_bridge (native FFI on iOS/Android)
- **Backend**: JNA (native shared library on JVM)

## Build & Test

```bash
cd engine
cargo build --release    # build native library (used by JVM backend)
cargo test               # run all tests
cargo build --target wasm32-unknown-unknown --release  # WASM for web
```

The backend's Gradle build automatically runs `cargo build --release` via the `cargoReleaseBuild` task.

## Project Structure

```
engine/src/
├── lib.rs                # Public modules
├── card.rs               # Card, Rank, Suit with serde + pegging values
├── deck.rs               # Deck with shuffle, deal, cut
├── scoring.rs            # Hand scoring (15s, pairs, runs, flushes, nobs)
├── score_breakdown.rs    # Detailed score breakdown
├── game_engine.rs        # Core game engine (stage transitions, validation)
├── game_state.rs         # GameState struct (players, scores, stage, history)
├── game_stage.rs         # GameStage enum (6 stages)
├── game_action.rs        # GameAction enum (5 action types)
├── game_history.rs       # GameHistoryEvent enum (8 event types)
├── player.rs             # Player struct
├── error.rs              # GameError enum
├── ai/
│   ├── mod.rs            # AiPlayer trait
│   ├── ai_utils.rs       # Shared utilities (combinations, run continuation)
│   ├── basic_ai.rs       # Easy: heuristic discard, simple pegging
│   ├── medium_ai.rs      # Medium: EV-based discard, tactical pegging
│   └── hard_ai.rs        # Hard: full EV analysis + sophisticated pegging evaluation
├── analysis/
│   ├── mod.rs
│   └── discard_analyzer.rs  # Exhaustive discard analysis (all 15 keeps)
├── api/
│   └── simple.rs         # flutter_rust_bridge FFI functions (12 public)
├── c_api/
│   └── mod.rs            # C-compatible FFI for JNA (backend)
└── frb_generated.rs      # flutter_rust_bridge auto-generated glue
```

Test fixtures at `engine/tests/fixtures/game_scenarios.json`.

## Key Components

### Game Engine (`game_engine.rs`)
- Full cribbage rules: dealing, discarding, cutting, pegging (to 31), counting, dealer rotation
- Stage-based state machine with validation
- History tracking of all game events
- `Game::new()`, `Game::apply_action()`, `Game::restore(state)`

### Scoring (`scoring.rs`)
- `calculate_hand_score(hand, cut, is_crib)` — complete cribbage scoring
- 15s (2 pts each), pairs (2 pts), runs (1 pt/card), flushes (4-5 pts), nobs (1 pt)
- Crib flush requires all 5 cards same suit

### AI Players (`ai/`)
Three difficulty levels implementing `AiPlayer` trait:
- **Basic**: Heuristic discard (keeps 15-combinations, avoids discarding aces/fives), simple pegging (targets 15/31, avoids leaving count at 5)
- **Medium**: Expected value-based discard (hand EV across all cuts), tactical pegging with pair/run awareness
- **Hard**: Full EV analysis (hand + simplified crib EV), sophisticated pegging with trap plays, defensive penalties, and multi-factor scoring

### Discard Analyzer (`analysis/discard_analyzer.rs`)
- Evaluates all 15 possible keeps from a 6-card hand
- For each keep: average hand score across all 46 cut cards
- Crib estimation: simplified scoring of discards + random cut cards
- Returns sorted list of `DiscardOption` (best first)
- Used for post-game analysis and daily puzzle evaluation

### FFI Layer

**flutter_rust_bridge (`api/simple.rs`)** — 12 public functions:
- `engine_new(p1, p2, difficulty)` — Create new game (returns JSON state)
- `engine_apply_action_json(state, action)` — Apply action (returns JSON state)
- `engine_process_ai_json(state, difficulty)` — Process AI turn (returns JSON state)
- `analyze_discards_json(hand, is_dealer)` — Analyze all 15 discards (returns JSON)
- `calculate_hand_score_json(hand, cut, is_crib)` — Score a hand
- Plus restore, state query, and utility functions

**C API (`c_api/mod.rs`)** — C-compatible FFI for JNA:
- Same functionality as flutter_rust_bridge but with C calling convention
- String parameters/returns for JSON interchange
- Memory management via `engine_free_string()`

## Dependencies

```toml
serde = { version = "1", features = ["derive"] }
serde_json = "1"
rand = "0.8"
flutter_rust_bridge = "=2.11.1"

[target.'cfg(target_arch = "wasm32")'.dependencies]
getrandom = { version = "0.2", features = ["js"] }  # WASM random support
```

## Conventions

- All public types derive `Serialize, Deserialize, Clone, Debug`
- Enums use serde `rename_all = "SCREAMING_SNAKE_CASE"` to match backend/frontend
- No unsafe code in game logic (only in auto-generated FFI glue)
- Exhaustive pattern matching on all enums
- `GameError` for all fallible operations (not panics)
