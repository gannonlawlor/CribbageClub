//! Public API for flutter_rust_bridge.
//!
//! This module exposes FFI-friendly functions and types. FRB scans these
//! `pub fn` declarations and generates corresponding Dart bindings.
//! Trait objects can't cross FFI, so AI difficulty is passed as an enum
//! and resolved on the Rust side.

use std::collections::HashMap;

use crate::ai::ai_player::{self, AIDifficulty};
use crate::analysis::{discard_analyzer, glicko2};
use crate::card::Card;
use crate::deck::Deck;
use crate::game_action::GameAction;
use crate::game_engine::GameEngine;
use crate::game_state::GameState;
use crate::player::Player;
use crate::scoring;

// ── FRB init ────────────────────────────────────────────────────────────

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

// ── Game Engine API ───────────────────────────────────────────────────

/// Opaque handle to a GameEngine. FRB will manage its lifetime.
#[flutter_rust_bridge::frb(opaque)]
pub struct RustGameEngine {
    inner: GameEngine,
}

/// Create a new game. Returns the engine handle.
pub fn engine_new(
    game_id: String,
    player1_id: String,
    player1_name: String,
    player2_id: String,
    player2_name: String,
    seed: Option<u64>,
) -> Result<RustGameEngine, String> {
    let players = vec![
        Player::new(player1_id, player1_name),
        Player::new(player2_id, player2_name),
    ];
    let deck = seed.map(Deck::with_seed);
    GameEngine::new(game_id, players, deck)
        .map(|inner| RustGameEngine { inner })
        .map_err(|e| e.to_string())
}

/// Restore a game from a serialized GameState JSON string.
pub fn engine_restore(state_json: String) -> Result<RustGameEngine, String> {
    let state: GameState =
        serde_json::from_str(&state_json).map_err(|e| format!("JSON parse error: {e}"))?;
    GameEngine::restore(state)
        .map(|inner| RustGameEngine { inner })
        .map_err(|e| e.to_string())
}

/// Get the current game state as a JSON string.
#[flutter_rust_bridge::frb(sync)]
pub fn engine_current_state_json(engine: &RustGameEngine) -> String {
    serde_json::to_string(&engine.inner.current_state()).unwrap_or_default()
}

/// Apply an action (JSON string) and return the new state as JSON.
pub fn engine_apply_action_json(
    engine: &mut RustGameEngine,
    action_json: String,
) -> Result<String, String> {
    let action: GameAction =
        serde_json::from_str(&action_json).map_err(|e| format!("JSON parse error: {e}"))?;
    let state = engine
        .inner
        .apply_action(action)
        .map_err(|e| e.to_string())?;
    serde_json::to_string(&state).map_err(|e| e.to_string())
}

/// Process AI actions in a loop and return the new state as JSON.
pub fn engine_process_ai_json(
    engine: &mut RustGameEngine,
    ai_player_id: String,
    difficulty: String,
    max_iterations: u32,
) -> Result<String, String> {
    let diff = parse_difficulty(&difficulty)?;
    let state =
        ai_player::process_ai_actions(&mut engine.inner, &ai_player_id, diff, max_iterations as usize)
            .map_err(|e| e.to_string())?;
    serde_json::to_string(&state).map_err(|e| e.to_string())
}

/// DEV ONLY: Set a player's score.
pub fn engine_dev_set_score(
    engine: &mut RustGameEngine,
    player_id: String,
    score: i32,
) -> Result<(), String> {
    engine
        .inner
        .dev_set_score(&player_id, score)
        .map_err(|e| e.to_string())
}

/// DEV ONLY: Set next hands (JSON map of player_id -> cards).
pub fn engine_dev_set_next_hands_json(
    engine: &mut RustGameEngine,
    hands_json: String,
) -> Result<(), String> {
    let hands: HashMap<String, Vec<Card>> =
        serde_json::from_str(&hands_json).map_err(|e| format!("JSON parse error: {e}"))?;
    engine.inner.dev_set_next_hands(hands);
    Ok(())
}

// ── Scoring API ───────────────────────────────────────────────────────

/// Calculate hand score from JSON cards.
#[flutter_rust_bridge::frb(sync)]
pub fn calculate_hand_score_json(hand_json: String, cut_card_json: String, is_crib: bool) -> Result<i32, String> {
    let hand: Vec<Card> = serde_json::from_str(&hand_json).map_err(|e| format!("JSON parse error: {e}"))?;
    let cut_card: Card = serde_json::from_str(&cut_card_json).map_err(|e| format!("JSON parse error: {e}"))?;
    Ok(scoring::calculate_hand_score(&hand, cut_card, is_crib))
}

// ── Analysis API ──────────────────────────────────────────────────────

/// Analyze all discard options. Returns JSON array of options.
pub fn analyze_discards_json(hand_json: String, is_dealer: bool) -> Result<String, String> {
    let hand: Vec<Card> = serde_json::from_str(&hand_json).map_err(|e| format!("JSON parse error: {e}"))?;
    let options = discard_analyzer::analyze_all_discards(&hand, is_dealer);

    // Convert to serializable format
    let serializable: Vec<serde_json::Value> = options
        .iter()
        .map(|o| {
            serde_json::json!({
                "keep": o.keep,
                "discard": o.discard,
                "expectedHandValue": o.expected_hand_value,
                "expectedCribValue": o.expected_crib_value,
                "expectedCombinedValue": o.expected_combined_value,
            })
        })
        .collect();

    serde_json::to_string(&serializable).map_err(|e| e.to_string())
}

/// Explain a specific keep choice. Returns JSON with guaranteed patterns,
/// per-cut scores, and crib impact.
#[flutter_rust_bridge::frb(sync)]
pub fn explain_keep_json(
    hand_json: String,
    keep_json: String,
    is_dealer: bool,
) -> Result<String, String> {
    let hand: Vec<Card> =
        serde_json::from_str(&hand_json).map_err(|e| format!("JSON parse error: {e}"))?;
    let keep: Vec<Card> =
        serde_json::from_str(&keep_json).map_err(|e| format!("JSON parse error: {e}"))?;
    let explanation = discard_analyzer::explain_keep(&hand, &keep, is_dealer);
    serde_json::to_string(&explanation).map_err(|e| e.to_string())
}

/// Calculate new Glicko-2 rating. Returns JSON result.
#[flutter_rust_bridge::frb(sync)]
pub fn glicko2_calculate_json(
    player_rating: f64,
    player_deviation: f64,
    player_volatility: f64,
    opponent_rating: f64,
    opponent_deviation: f64,
    opponent_volatility: f64,
    score: f64,
) -> String {
    let player = glicko2::Rating {
        rating: player_rating,
        deviation: player_deviation,
        volatility: player_volatility,
    };
    let opponent = glicko2::Rating {
        rating: opponent_rating,
        deviation: opponent_deviation,
        volatility: opponent_volatility,
    };
    let result = glicko2::calculate_new_rating(&player, &opponent, score);
    serde_json::json!({
        "newRating": result.new_rating,
        "newDeviation": result.new_deviation,
        "newVolatility": result.new_volatility,
    })
    .to_string()
}

// ── Helpers ───────────────────────────────────────────────────────────

fn parse_difficulty(s: &str) -> Result<AIDifficulty, String> {
    match s {
        "basic" | "easy" => Ok(AIDifficulty::Basic),
        "medium" => Ok(AIDifficulty::Medium),
        "hard" => Ok(AIDifficulty::Hard),
        _ => Err(format!("Unknown difficulty: {s}")),
    }
}
