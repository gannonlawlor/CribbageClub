//! wasm-bindgen API for the React web app.
//!
//! Mirrors `api/simple.rs` but uses `#[wasm_bindgen]` instead of FRB attributes.
//! All functions use JSON string interchange.
//!
//! Engine handles: wasm-bindgen can't pass opaque Rust structs across the JS
//! boundary, so we use a global handle pool. JS gets integer handles (indices),
//! and functions look up engines by index. `engine_free(handle)` releases slots.

use std::sync::Mutex;
use wasm_bindgen::prelude::*;

use crate::ai::ai_player::{self, AIDifficulty};
use crate::analysis::{discard_analyzer, glicko2};
use crate::card::Card;
use crate::deck::Deck;
use crate::game_action::GameAction;
use crate::game_engine::GameEngine;
use crate::game_state::GameState;
use crate::player::Player;
use crate::scoring;

// ── Handle pool ──────────────────────────────────────────────────────

static ENGINE_POOL: Mutex<Vec<Option<GameEngine>>> = Mutex::new(Vec::new());

fn insert_engine(engine: GameEngine) -> u32 {
    let mut pool = ENGINE_POOL.lock().unwrap();
    // Reuse a freed slot if available
    for (i, slot) in pool.iter_mut().enumerate() {
        if slot.is_none() {
            *slot = Some(engine);
            return i as u32;
        }
    }
    // No free slot — push a new one
    pool.push(Some(engine));
    (pool.len() - 1) as u32
}

fn with_engine<F, R>(handle: u32, f: F) -> Result<R, String>
where
    F: FnOnce(&mut GameEngine) -> Result<R, String>,
{
    let mut pool = ENGINE_POOL.lock().unwrap();
    let slot = pool
        .get_mut(handle as usize)
        .and_then(|s| s.as_mut())
        .ok_or_else(|| format!("Invalid engine handle: {handle}"))?;
    f(slot)
}

// ── Game Engine API ──────────────────────────────────────────────────

#[wasm_bindgen]
pub fn engine_new(
    game_id: &str,
    player1_id: &str,
    player1_name: &str,
    player2_id: &str,
    player2_name: &str,
    seed: Option<f64>,
) -> Result<u32, JsError> {
    let players = vec![
        Player::new(player1_id.to_string(), player1_name.to_string()),
        Player::new(player2_id.to_string(), player2_name.to_string()),
    ];
    let deck = seed.map(|s| Deck::with_seed(s as u64));
    let engine = GameEngine::new(game_id.to_string(), players, deck)
        .map_err(|e| JsError::new(&e.to_string()))?;
    Ok(insert_engine(engine))
}

#[wasm_bindgen]
pub fn engine_restore(state_json: &str) -> Result<u32, JsError> {
    let state: GameState =
        serde_json::from_str(state_json).map_err(|e| JsError::new(&format!("JSON parse error: {e}")))?;
    let engine =
        GameEngine::restore(state).map_err(|e| JsError::new(&e.to_string()))?;
    Ok(insert_engine(engine))
}

#[wasm_bindgen]
pub fn engine_current_state_json(handle: u32) -> Result<String, JsError> {
    with_engine(handle, |engine| {
        serde_json::to_string(&engine.current_state()).map_err(|e| e.to_string())
    })
    .map_err(|e| JsError::new(&e))
}

#[wasm_bindgen]
pub fn engine_apply_action_json(handle: u32, action_json: &str) -> Result<String, JsError> {
    let action: GameAction = serde_json::from_str(action_json)
        .map_err(|e| JsError::new(&format!("JSON parse error: {e}")))?;
    with_engine(handle, |engine| {
        let state = engine.apply_action(action).map_err(|e| e.to_string())?;
        serde_json::to_string(&state).map_err(|e| e.to_string())
    })
    .map_err(|e| JsError::new(&e))
}

#[wasm_bindgen]
pub fn engine_process_ai_json(
    handle: u32,
    ai_player_id: &str,
    difficulty: &str,
    max_iterations: u32,
) -> Result<String, JsError> {
    let diff = parse_difficulty(difficulty)?;
    let ai_id = ai_player_id.to_string();
    with_engine(handle, |engine| {
        let state =
            ai_player::process_ai_actions(engine, &ai_id, diff, max_iterations as usize)
                .map_err(|e| e.to_string())?;
        serde_json::to_string(&state).map_err(|e| e.to_string())
    })
    .map_err(|e| JsError::new(&e))
}

#[wasm_bindgen]
pub fn engine_free(handle: u32) {
    let mut pool = ENGINE_POOL.lock().unwrap();
    if let Some(slot) = pool.get_mut(handle as usize) {
        *slot = None;
    }
}

// ── Scoring API ──────────────────────────────────────────────────────

#[wasm_bindgen]
pub fn calculate_hand_score_json(
    hand_json: &str,
    cut_card_json: &str,
    is_crib: bool,
) -> Result<i32, JsError> {
    let hand: Vec<Card> = serde_json::from_str(hand_json)
        .map_err(|e| JsError::new(&format!("JSON parse error: {e}")))?;
    let cut_card: Card = serde_json::from_str(cut_card_json)
        .map_err(|e| JsError::new(&format!("JSON parse error: {e}")))?;
    Ok(scoring::calculate_hand_score(&hand, cut_card, is_crib))
}

// ── Analysis API ─────────────────────────────────────────────────────

#[wasm_bindgen]
pub fn analyze_discards_json(hand_json: &str, is_dealer: bool) -> Result<String, JsError> {
    let hand: Vec<Card> = serde_json::from_str(hand_json)
        .map_err(|e| JsError::new(&format!("JSON parse error: {e}")))?;
    let options = discard_analyzer::analyze_all_discards(&hand, is_dealer);

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

    serde_json::to_string(&serializable).map_err(|e| JsError::new(&e.to_string()))
}

#[wasm_bindgen]
pub fn explain_keep_json(
    hand_json: &str,
    keep_json: &str,
    is_dealer: bool,
) -> Result<String, JsError> {
    let hand: Vec<Card> = serde_json::from_str(hand_json)
        .map_err(|e| JsError::new(&format!("JSON parse error: {e}")))?;
    let keep: Vec<Card> = serde_json::from_str(keep_json)
        .map_err(|e| JsError::new(&format!("JSON parse error: {e}")))?;
    let explanation = discard_analyzer::explain_keep(&hand, &keep, is_dealer);
    serde_json::to_string(&explanation).map_err(|e| JsError::new(&e.to_string()))
}

#[wasm_bindgen]
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

// ── Helpers ──────────────────────────────────────────────────────────

fn parse_difficulty(s: &str) -> Result<AIDifficulty, JsError> {
    match s {
        "basic" | "easy" => Ok(AIDifficulty::Basic),
        "medium" => Ok(AIDifficulty::Medium),
        "hard" => Ok(AIDifficulty::Hard),
        _ => Err(JsError::new(&format!("Unknown difficulty: {s}"))),
    }
}
