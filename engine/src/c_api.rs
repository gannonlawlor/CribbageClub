//! C-compatible FFI API for JNA (Spring Boot) integration.
//!
//! This module exposes `extern "C"` functions with C-compatible types
//! so they can be called via JNA from Kotlin/JVM. Uses the same
//! JSON-based data exchange pattern as the FRB API.
//!
//! Memory management:
//! - Strings returned by these functions are heap-allocated; callers
//!   MUST free them with `cribbage_string_free`.
//! - Engine handles are opaque pointers; callers MUST free them with
//!   `cribbage_engine_free`.
//! - On error, functions return null and set a thread-local error
//!   message retrievable via `cribbage_last_error`.

use std::cell::RefCell;
use std::collections::HashMap;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

use crate::ai::ai_player::{self, AIDifficulty};
use crate::analysis::{discard_analyzer, glicko2};
use crate::card::Card;
use crate::deck::Deck;
use crate::game_action::GameAction;
use crate::game_engine::GameEngine;
use crate::game_state::GameState;
use crate::player::Player;
use crate::scoring;

// ── Thread-local error ──────────────────────────────────────────────

thread_local! {
    static LAST_ERROR: RefCell<Option<String>> = const { RefCell::new(None) };
}

fn set_error(msg: String) {
    LAST_ERROR.with(|e| *e.borrow_mut() = Some(msg));
}

fn clear_error() {
    LAST_ERROR.with(|e| *e.borrow_mut() = None);
}

// ── Helpers ─────────────────────────────────────────────────────────

fn to_c_string(s: &str) -> *mut c_char {
    CString::new(s).unwrap_or_default().into_raw()
}

unsafe fn from_c_str(ptr: *const c_char) -> String {
    if ptr.is_null() {
        String::new()
    } else {
        CStr::from_ptr(ptr).to_string_lossy().into_owned()
    }
}

fn parse_difficulty(s: &str) -> Result<AIDifficulty, String> {
    match s {
        "basic" | "easy" => Ok(AIDifficulty::Basic),
        "medium" => Ok(AIDifficulty::Medium),
        "hard" => Ok(AIDifficulty::Hard),
        _ => Err(format!("Unknown difficulty: {s}")),
    }
}

// ── Memory management ───────────────────────────────────────────────

/// Free a string returned by any `cribbage_*` function.
#[no_mangle]
pub extern "C" fn cribbage_string_free(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            drop(CString::from_raw(ptr));
        }
    }
}

/// Free an engine handle.
#[no_mangle]
pub extern "C" fn cribbage_engine_free(ptr: *mut GameEngine) {
    if !ptr.is_null() {
        unsafe {
            drop(Box::from_raw(ptr));
        }
    }
}

/// Get the last error message. Returns null if no error.
/// Caller must free the returned string with `cribbage_string_free`.
#[no_mangle]
pub extern "C" fn cribbage_last_error() -> *mut c_char {
    LAST_ERROR.with(|e| match e.borrow().as_ref() {
        Some(msg) => to_c_string(msg),
        None => std::ptr::null_mut(),
    })
}

// ── Game Engine ─────────────────────────────────────────────────────

/// Create a new game engine. Returns null on error.
#[no_mangle]
pub extern "C" fn cribbage_engine_new(
    game_id: *const c_char,
    p1_id: *const c_char,
    p1_name: *const c_char,
    p2_id: *const c_char,
    p2_name: *const c_char,
) -> *mut GameEngine {
    clear_error();
    let game_id = unsafe { from_c_str(game_id) };
    let p1_id = unsafe { from_c_str(p1_id) };
    let p1_name = unsafe { from_c_str(p1_name) };
    let p2_id = unsafe { from_c_str(p2_id) };
    let p2_name = unsafe { from_c_str(p2_name) };

    let players = vec![Player::new(p1_id, p1_name), Player::new(p2_id, p2_name)];

    match GameEngine::new(game_id, players, None) {
        Ok(engine) => Box::into_raw(Box::new(engine)),
        Err(e) => {
            set_error(e.to_string());
            std::ptr::null_mut()
        }
    }
}

/// Create a new game engine with a seeded deck. Returns null on error.
#[no_mangle]
pub extern "C" fn cribbage_engine_new_seeded(
    game_id: *const c_char,
    p1_id: *const c_char,
    p1_name: *const c_char,
    p2_id: *const c_char,
    p2_name: *const c_char,
    seed: u64,
) -> *mut GameEngine {
    clear_error();
    let game_id = unsafe { from_c_str(game_id) };
    let p1_id = unsafe { from_c_str(p1_id) };
    let p1_name = unsafe { from_c_str(p1_name) };
    let p2_id = unsafe { from_c_str(p2_id) };
    let p2_name = unsafe { from_c_str(p2_name) };

    let players = vec![Player::new(p1_id, p1_name), Player::new(p2_id, p2_name)];
    let deck = Some(Deck::with_seed(seed));

    match GameEngine::new(game_id, players, deck) {
        Ok(engine) => Box::into_raw(Box::new(engine)),
        Err(e) => {
            set_error(e.to_string());
            std::ptr::null_mut()
        }
    }
}

/// Restore a game engine from a GameState JSON string. Returns null on error.
#[no_mangle]
pub extern "C" fn cribbage_engine_restore(state_json: *const c_char) -> *mut GameEngine {
    clear_error();
    let json = unsafe { from_c_str(state_json) };

    let state: GameState = match serde_json::from_str(&json) {
        Ok(s) => s,
        Err(e) => {
            set_error(format!("JSON parse error: {e}"));
            return std::ptr::null_mut();
        }
    };

    match GameEngine::restore(state) {
        Ok(engine) => Box::into_raw(Box::new(engine)),
        Err(e) => {
            set_error(e.to_string());
            std::ptr::null_mut()
        }
    }
}

/// Get current game state as JSON. Returns null on error.
/// Caller must free with `cribbage_string_free`.
#[no_mangle]
pub extern "C" fn cribbage_engine_state_json(engine: *const GameEngine) -> *mut c_char {
    clear_error();
    if engine.is_null() {
        set_error("Null engine pointer".into());
        return std::ptr::null_mut();
    }
    let engine = unsafe { &*engine };
    match serde_json::to_string(&engine.current_state()) {
        Ok(json) => to_c_string(&json),
        Err(e) => {
            set_error(e.to_string());
            std::ptr::null_mut()
        }
    }
}

/// Apply an action (JSON) and return the new state as JSON.
/// Returns null on error. Caller must free with `cribbage_string_free`.
#[no_mangle]
pub extern "C" fn cribbage_engine_apply_action(
    engine: *mut GameEngine,
    action_json: *const c_char,
) -> *mut c_char {
    clear_error();
    if engine.is_null() {
        set_error("Null engine pointer".into());
        return std::ptr::null_mut();
    }
    let engine = unsafe { &mut *engine };
    let json = unsafe { from_c_str(action_json) };

    let action: GameAction = match serde_json::from_str(&json) {
        Ok(a) => a,
        Err(e) => {
            set_error(format!("JSON parse error: {e}"));
            return std::ptr::null_mut();
        }
    };

    match engine.apply_action(action) {
        Ok(state) => match serde_json::to_string(&state) {
            Ok(json) => to_c_string(&json),
            Err(e) => {
                set_error(e.to_string());
                std::ptr::null_mut()
            }
        },
        Err(e) => {
            set_error(e.to_string());
            std::ptr::null_mut()
        }
    }
}

/// Process AI actions and return the new state as JSON.
/// Returns null on error. Caller must free with `cribbage_string_free`.
#[no_mangle]
pub extern "C" fn cribbage_engine_process_ai(
    engine: *mut GameEngine,
    ai_player_id: *const c_char,
    difficulty: *const c_char,
    max_iterations: u32,
) -> *mut c_char {
    clear_error();
    if engine.is_null() {
        set_error("Null engine pointer".into());
        return std::ptr::null_mut();
    }
    let engine = unsafe { &mut *engine };
    let ai_id = unsafe { from_c_str(ai_player_id) };
    let diff_str = unsafe { from_c_str(difficulty) };

    let diff = match parse_difficulty(&diff_str) {
        Ok(d) => d,
        Err(e) => {
            set_error(e);
            return std::ptr::null_mut();
        }
    };

    match ai_player::process_ai_actions(engine, &ai_id, diff, max_iterations as usize) {
        Ok(state) => match serde_json::to_string(&state) {
            Ok(json) => to_c_string(&json),
            Err(e) => {
                set_error(e.to_string());
                std::ptr::null_mut()
            }
        },
        Err(e) => {
            set_error(e.to_string());
            std::ptr::null_mut()
        }
    }
}

/// DEV ONLY: Set a player's score. Returns 0 on success, -1 on error.
#[no_mangle]
pub extern "C" fn cribbage_engine_dev_set_score(
    engine: *mut GameEngine,
    player_id: *const c_char,
    score: i32,
) -> i32 {
    clear_error();
    if engine.is_null() {
        set_error("Null engine pointer".into());
        return -1;
    }
    let engine = unsafe { &mut *engine };
    let player_id = unsafe { from_c_str(player_id) };

    match engine.dev_set_score(&player_id, score) {
        Ok(()) => 0,
        Err(e) => {
            set_error(e.to_string());
            -1
        }
    }
}

/// DEV ONLY: Set next hands (JSON map of player_id -> cards).
/// Returns 0 on success, -1 on error.
#[no_mangle]
pub extern "C" fn cribbage_engine_dev_set_next_hands(
    engine: *mut GameEngine,
    hands_json: *const c_char,
) -> i32 {
    clear_error();
    if engine.is_null() {
        set_error("Null engine pointer".into());
        return -1;
    }
    let engine = unsafe { &mut *engine };
    let json = unsafe { from_c_str(hands_json) };

    let hands: HashMap<String, Vec<Card>> = match serde_json::from_str(&json) {
        Ok(h) => h,
        Err(e) => {
            set_error(format!("JSON parse error: {e}"));
            return -1;
        }
    };

    engine.dev_set_next_hands(hands);
    0
}

// ── Scoring ─────────────────────────────────────────────────────────

/// Calculate hand score from JSON cards. Returns score, or -1 on error.
#[no_mangle]
pub extern "C" fn cribbage_calculate_hand_score(
    hand_json: *const c_char,
    cut_card_json: *const c_char,
    is_crib: bool,
) -> i32 {
    clear_error();
    let hand_str = unsafe { from_c_str(hand_json) };
    let cut_str = unsafe { from_c_str(cut_card_json) };

    let hand: Vec<Card> = match serde_json::from_str(&hand_str) {
        Ok(h) => h,
        Err(e) => {
            set_error(format!("JSON parse error: {e}"));
            return -1;
        }
    };
    let cut_card: Card = match serde_json::from_str(&cut_str) {
        Ok(c) => c,
        Err(e) => {
            set_error(format!("JSON parse error: {e}"));
            return -1;
        }
    };

    scoring::calculate_hand_score(&hand, cut_card, is_crib)
}

// ── Analysis ────────────────────────────────────────────────────────

/// Analyze all discard options. Returns JSON array.
/// Returns null on error. Caller must free with `cribbage_string_free`.
#[no_mangle]
pub extern "C" fn cribbage_analyze_discards(
    hand_json: *const c_char,
    is_dealer: bool,
) -> *mut c_char {
    clear_error();
    let hand_str = unsafe { from_c_str(hand_json) };

    let hand: Vec<Card> = match serde_json::from_str(&hand_str) {
        Ok(h) => h,
        Err(e) => {
            set_error(format!("JSON parse error: {e}"));
            return std::ptr::null_mut();
        }
    };

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

    match serde_json::to_string(&serializable) {
        Ok(json) => to_c_string(&json),
        Err(e) => {
            set_error(e.to_string());
            std::ptr::null_mut()
        }
    }
}

/// Calculate new Glicko-2 rating. Returns JSON result.
/// Caller must free with `cribbage_string_free`.
#[no_mangle]
pub extern "C" fn cribbage_glicko2_calculate(
    player_rating: f64,
    player_deviation: f64,
    player_volatility: f64,
    opponent_rating: f64,
    opponent_deviation: f64,
    opponent_volatility: f64,
    score: f64,
) -> *mut c_char {
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
    to_c_string(
        &serde_json::json!({
            "newRating": result.new_rating,
            "newDeviation": result.new_deviation,
            "newVolatility": result.new_volatility,
        })
        .to_string(),
    )
}
