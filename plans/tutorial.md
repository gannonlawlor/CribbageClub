# Interactive Cribbage Tutorial with Removable Home Tile

## Context

The app has no tutorial, rules, or onboarding content anywhere in `mobile/lib`. The home screen (`mobile/lib/features/home/screens/home_screen.dart`, ~1542 lines) is a hardcoded Column of private card widgets sharing a `_Card`/`_IconTile` shell. Settings persist through `SettingsService` (SharedPreferences) → `SettingsNotifier`/`SettingsState`, keys centralized in `mobile/lib/config/constants.dart`. Local offline games run through the Rust engine: `localGameServiceProvider` → `LocalGameService` (`mobile/lib/core/engine/local_game_service.dart`) → `rust.engineNew(...)`, rendered by the full game screen at `/game/{id}` when the gameId starts with `local_`.

**Goal:** a "Learn cribbage" tile on the home screen opening a playable, guided tutorial for people who don't know cribbage. Experienced players can remove the tile; the tutorial stays reachable from Settings afterward.

**Tutorial architecture decision: hybrid.** Short interactive concept lessons on standalone screens, followed by one guided real hand vs. the easy bot on the real game screen with a fixed deck and a narration-only coach strip.

Why not the alternatives:
- **Full "tutorial mode" on the game screen** is too invasive. `game_screen.dart` is ~1800 lines with action dispatch scattered across ~10 call sites plus four auto-play settings (`autoDeal`/`autoCut`/`autoGo`/`autoPlayPegging`) that interact with input timing. Only-valid-card enforcement would need interception at every path — high regression risk on the most complex screen in the app.
- **Standalone-only lessons** never put the learner on the real table, so the first real game is still cold.
- **Hybrid** gets both: bespoke mini-widgets teach each concept in isolation (reusing `CardWidget` from `mobile/lib/features/game/widgets/card_widget.dart`), then a real hand exercises the actual UI. The coach layer *narrates* (derived from `GameState.stage` + `history`) and never intercepts input — the game-screen change is one conditional widget mount.

**Engine support for a fixed deal:** the engine has `Deck::with_seed(u64)` exposed through `engine_new(seed: Option<u64>)`, and `Deck::from_cards(Vec<Card>)` exists (`engine/src/deck.rs`) but is **not** exposed over FFI. `engine_dev_set_next_hands_json` is unsuitable: it overrides hands without removing them from the deck, so the cut card can duplicate a hand card. A small Rust addition is needed: `engine_new_with_deck`. Determinism facts (from `engine/src/game_engine.rs`): player1 is always first dealer; `deal_cards` draws 6 to player1 (deck[0..6]) then 6 to player2 (deck[6..12]); `deck.cut()` removes the middle of the remaining 40 cards → **cut card = deck[32]**.

Design language: quiet, no cheerleading, zero exclamation points. All copy follows that.

## Lesson Outline

New feature module `mobile/lib/features/tutorial/`. Eight lessons in a paged flow with a progress rail; most have a small interactive exercise. Progress persists so the tutorial resumes.

| # | Lesson | Content / exercise |
|---|--------|--------------------|
| 1 | The race to 121 | The board, two players, points come from three places: pegging, your hand, the crib. Static board illustration. |
| 2 | Card values and fifteens | Face cards count 10, ace is 1. Exercise: tap two or three cards totaling 15 from a fixed row (local validation, shows the 2 points). |
| 3 | Pairs and runs | Pair = 2, run of 3+ = 1 per card. Exercise: tap the run hidden in a fixed set. |
| 4 | The deal and the crib | Six cards each, throw 2 to the dealer's crib. Discard basics: keep cards that work together; be careful throwing 5s or pairs into an opponent's crib. Exercise: pick 2 to throw from a fixed 6-card hand; per-choice feedback (reuse the approach from `mobile/lib/features/daily_puzzle/services/insight_generator.dart` / `explain_keep_json`). |
| 5 | The cut and His Heels | Non-dealer cuts; the cut card joins every hand at counting; a cut jack scores the dealer 2. Static. |
| 6 | Pegging to 31 | Alternate cards, running count, 15 for 2, pairs, runs, Go, 31 for 2, last card for 1. Exercise: a short scripted exchange — fixed opponent line, learner picks each play, widget scores it. |
| 7 | Counting the hand | 15s, pairs, runs, flush, His Nobs (jack matching the cut suit). Exercise: count a fixed hand + cut step by step. |
| 8 | The crib, then a real hand | Dealer counts the crib last; deal alternates; first to 121. Ends with the primary action: "Play a guided hand". |

Completion = finishing the guided hand.

## Phase 1 — Rust engine: fixed-deck constructor

**`engine/src/api/simple.rs`** — add:

```rust
pub fn engine_new_with_deck(
    game_id: String,
    player1_id: String, player1_name: String,
    player2_id: String, player2_name: String,
    deck_json: String,
) -> Result<RustGameEngine, String>
```

Parse `Vec<Card>` from JSON, validate exactly 52 unique cards, build `Deck::from_cards(cards)`, pass to `GameEngine::new`. No changes to `game_engine.rs` or `deck.rs`.

- Engine unit test: construct with a known 52-card order; assert player1 hand == deck[0..6], player2 == deck[6..12], and after both discards + cut the `cut_card` == deck[32]; assert the 52-unique validation error.
- Regenerate bindings: `flutter_rust_bridge_codegen generate` (config `mobile/flutter_rust_bridge.yaml`). Commit regenerated `mobile/lib/src/rust/api/simple.dart` + `frb_generated*`.
- `cargo test` in `engine/`.

## Phase 2 — Tutorial feature module (lessons 1–8)

New files:
- `mobile/lib/features/tutorial/screens/tutorial_screen.dart` — `TutorialScreen`: PageView of lessons, step rail, quiet "Skip" in the app bar. Resumes at the persisted step.
- `mobile/lib/features/tutorial/data/tutorial_lessons.dart` — lesson copy + fixed card sets as data, keeping copy out of widgets.
- `mobile/lib/features/tutorial/widgets/` — `lesson_page.dart` (shared scaffold: title, body, exercise slot, Continue), `fifteen_exercise.dart`, `run_exercise.dart`, `discard_exercise.dart`, `pegging_exercise.dart`, `counting_exercise.dart`, `board_illustration.dart`. Cards render via `CardWidget`; 15/pair/run validation is trivial Dart (no FFI except the discard exercise, which may use `LocalAnalysisService.explainKeep`).
- `mobile/lib/features/tutorial/state/tutorial_progress_provider.dart` — `TutorialProgressNotifier extends StateNotifier<TutorialProgress>` (`step`, `completed`), persisted directly to SharedPreferences (same pattern as `_BotDifficultyNotifier` in home_screen.dart). Keys added to `mobile/lib/config/constants.dart`: `tutorialStepKey = 'tutorial_step'`, `tutorialCompletedKey = 'tutorial_completed'`.

Routing (`mobile/lib/config/routes.dart`): `GoRoute(path: '/learn', pageBuilder: MaterialPage(child: TutorialScreen()))` (MaterialPage keeps the pop gesture, per the route conventions in that file).

## Phase 3 — Guided hand on the real game screen

- `mobile/lib/core/engine/local_game_service.dart` — add `createScriptedGame({required humanPlayerId, required humanPlayerName, required List<PlayingCard> deck})`: gameId `'local_tutorial_${millis}'` (keeps the `local_` prefix so `isLocalGame()` and all local plumbing work unchanged), **bot as player1** (dealer), human as player2, difficulty `'easy'`, calling the new `rust.engineNewWithDeck`. Human as non-dealer does the most: discards into the bot's crib, cuts, leads pegging, counts first.
- `mobile/lib/features/tutorial/data/tutorial_deck.dart` — the 52-card scripted order. Pedagogical intent: human hand (deck[6..12]) = `5♥ 6♠ 7♦ 8♣ Q♥ K♦` — the clean keep is 5-6-7-8 (run of four plus the 7+8 fifteen), throw Q K (safe-ish into an opponent crib); cut card (deck[32]) = `4♦`, turning the keep into a run of five with two fifteens (9 points) — a satisfying first count. Bot hand (deck[0..6]) deliberately mediocre. A Dart test asserts the dealt hands and cut card via `createScriptedGame`.
- `mobile/lib/features/tutorial/state/tutorial_game_provider.dart` — `tutorialGameIdProvider = StateProvider<String?>`, set when the guided hand starts, cleared on completion/exit.
- `mobile/lib/features/tutorial/widgets/tutorial_coach.dart` — `TutorialCoachStrip`: a slim panel watching `localGameNotifierProvider(gameId)`, deriving one short line from `(stage, currentPlayerId, history)`. Examples — discarding: "Keep the 5-6-7-8. Throw the queen and king to the crib — it belongs to your opponent this hand."; cutting: "Tap the deck to cut."; pegging (situational, since the easy AI's line isn't scripted): "You can still play under 31. Last card scores one."; counting: "Look for the run of five and the fifteens." Card-specific copy only where the script guarantees the state (discard, cut, first count). Includes an understated "End tutorial" link (clears the provider, resigns the local game).
- `mobile/lib/features/game/screens/game_screen.dart` — the **only** game-screen change: when `ref.watch(tutorialGameIdProvider) == gameId`, mount `TutorialCoachStrip(gameId: gameId)` between the table and the bottom controls. No input interception; auto-settings behave normally and the coach narrates whatever actually happened (if `autoCut` already cut, the strip explains the cut it sees).
- On `GameStage.gameOver` while in tutorial: mark `tutorialCompletedKey`, clear `tutorialGameIdProvider`, show a completion `CcDialog`: result, "You know enough to play. The easy bot is a good next step.", plus an optional "Remove the Learn tile from home" action (Phase 4 wiring).

## Phase 4 — Home tile, removal, and the Settings home

Tile visibility rides the existing settings pipeline (rendered on home, toggled from Settings):
- `mobile/lib/config/constants.dart` — `showLearnTileKey = 'show_learn_tile'`.
- `mobile/lib/core/services/settings_service.dart` — `setShowLearnTile(bool)`; include in `loadAll()` (default `true`).
- `mobile/lib/core/services/settings_provider.dart` — `SettingsState.showLearnTile` + `copyWith` + `SettingsNotifier.setShowLearnTile`; update the startup `loadAll` consumer in `main.dart`.

Home tile (`home_screen.dart`):
- New private `_LearnCard` using the existing `_Card`/`_IconTile` shell, placed after the `_DailyPuzzleCard/_PuzzleModeCard` row. Title "Learn cribbage"; subtitle "A short playable introduction" before completion, "Play it again anytime" after. Tap → `context.push('/learn')`. Rendered only when `ref.watch(settingsProvider).showLearnTile`.
- **Removal UX (decision):** long-press opens a `CcDialog` — "Remove from home. You can find it again under Settings." with Remove/Cancel. Because long-press is poorly discoverable, once `tutorial_completed` is true the tile also shows a small trailing dismiss (understated `×`, `colors.textTertiary`) opening the same dialog. Learners who haven't finished never see the `×`, so the tile can't be dismissed by accident before it has done its job — but long-press still works for experienced players who never want it.
- **Completion does not auto-hide or shrink the tile** (decision): silent layout changes read as bugs; removal stays an explicit user action, offered in the completion dialog and available on the tile.

Settings home (`mobile/lib/features/settings/screens/settings_screen.dart`):
- New "Help" section (`_SectionCaption('Help')` + `_Group`) between Puzzles and Appearance, two rows: `_ValueRow(label: 'Learn cribbage', value: completed ? 'Completed' : 'Not started', onTap: → '/learn')` — always present, so the tutorial stays reachable after tile removal — and `_ToggleRow(label: 'Show on home screen', value: settings.showLearnTile, onChanged: notifier.setShowLearnTile)` so removal is reversible. (Settings over Profile: the profile screen is server-identity focused, and guests without accounts still need the entry point.)

## Verification

- `cd engine && cargo test` — `engine_new_with_deck` determinism + validation tests.
- `mobile/scripts/test.sh` (analyze + test):
  - Unit: scripted deck → dealt hands + cut card assertions; tutorial progress persistence round-trip; exercise validators.
  - Widget: lesson pager advances and persists step; `_LearnCard` hidden when `showLearnTile` false; `×` only after completion; Settings row navigates; toggle restores the tile.
- Manual: fresh install → tile present → lessons 1–8 → guided hand: fixed cards appear, coach lines match each phase, completion dialog at game over; remove tile via long-press and via `×`; relaunch (removal persists); replay from Settings; kill mid-lesson → resume; run with `autoDeal/autoCut` toggled both ways to confirm coach copy still reads sensibly.

## Critical files

- `engine/src/api/simple.rs` (new `engine_new_with_deck` FFI)
- `mobile/lib/core/engine/local_game_service.dart` (`createScriptedGame`)
- `mobile/lib/features/home/screens/home_screen.dart` (`_LearnCard` + removal UX)
- `mobile/lib/features/game/screens/game_screen.dart` (single conditional coach-strip mount)
- `mobile/lib/core/services/settings_provider.dart` (`showLearnTile`)
