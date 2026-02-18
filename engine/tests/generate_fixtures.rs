//! Fixture generator for cross-platform parity tests.
//!
//! Run with: cargo test --test generate_fixtures -- --nocapture
//! to regenerate the fixtures file.

use cribbage_engine::card::Card;
use cribbage_engine::deck::Deck;
use cribbage_engine::game_action::GameAction;
use cribbage_engine::game_engine::GameEngine;
use cribbage_engine::game_stage::GameStage;
use cribbage_engine::player::Player;

use std::fs;

fn two_players() -> Vec<Player> {
    vec![
        Player::new("p1", "Player 1"),
        Player::new("p2", "Player 2"),
    ]
}

/// Plays through pegging automatically: current player plays lowest legal card, or says Go.
/// Returns the actions that were applied (for reproducibility).
fn play_pegging(engine: &mut GameEngine) -> Vec<serde_json::Value> {
    let mut actions = Vec::new();
    for _ in 0..20 {
        let state = engine.current_state();
        if state.stage != GameStage::Pegging {
            break;
        }

        let current_id = state.current_player_id.clone().unwrap();
        let player = state.players.iter().find(|p| p.id == current_id).unwrap();

        let playable: Option<Card> = player
            .hand
            .iter()
            .filter(|c| state.pegging_count + c.pegging_value() as i32 <= 31)
            .min_by_key(|c| c.pegging_value())
            .copied();

        if let Some(card) = playable {
            let action = GameAction::PlayCard {
                player_id: current_id,
                card,
            };
            actions.push(serde_json::to_value(&action).unwrap());
            engine.apply_action(action).unwrap();
        } else {
            let action = GameAction::Go {
                player_id: current_id,
            };
            actions.push(serde_json::to_value(&action).unwrap());
            engine.apply_action(action).unwrap();
        }
    }
    actions
}

#[test]
fn generate_parity_fixtures() {
    let seed: u64 = 42;
    let deck = Deck::with_seed(seed);
    let mut engine = GameEngine::new("parity_test_1", two_players(), Some(deck)).unwrap();

    let mut snapshots = serde_json::Map::new();

    // Snapshot: After deal
    let state = engine.current_state();
    snapshots.insert(
        "after_deal".into(),
        serde_json::to_value(&state).unwrap(),
    );

    // Discard: each player discards their first two cards
    let p1_discards: Vec<Card> = state.players[0].hand[..2].to_vec();
    let p2_discards: Vec<Card> = state.players[1].hand[..2].to_vec();

    for card in &p1_discards {
        engine
            .apply_action(GameAction::DiscardToCrib {
                player_id: "p1".into(),
                card: *card,
            })
            .unwrap();
    }
    for card in &p2_discards {
        engine
            .apply_action(GameAction::DiscardToCrib {
                player_id: "p2".into(),
                card: *card,
            })
            .unwrap();
    }

    // Snapshot: After all discards
    snapshots.insert(
        "after_discard".into(),
        serde_json::to_value(&engine.current_state()).unwrap(),
    );

    // Cut
    let cutter = engine.current_state().current_player_id.clone().unwrap();
    engine
        .apply_action(GameAction::CutDeck {
            player_id: cutter,
        })
        .unwrap();

    // Snapshot: After cut (includes nobs scoring if applicable)
    snapshots.insert(
        "after_cut".into(),
        serde_json::to_value(&engine.current_state()).unwrap(),
    );

    // Pegging (automated — plays lowest legal card, or Go)
    play_pegging(&mut engine);

    // Snapshot: After pegging (pegging scores applied, all cards played)
    snapshots.insert(
        "after_pegging".into(),
        serde_json::to_value(&engine.current_state()).unwrap(),
    );

    // Counting — non-dealer counts first, then dealer, then crib auto-counted
    for _ in 0..3 {
        let state = engine.current_state();
        if state.stage != GameStage::Counting {
            break;
        }
        let counter = state.current_player_id.clone().unwrap();
        engine
            .apply_action(GameAction::CountHand {
                player_id: counter,
            })
            .unwrap();
    }

    // Snapshot: After counting — scores finalized for this round.
    // NOTE: a new round may have started with a non-deterministic reshuffle,
    // so we only verify scores and history, not new hand contents.
    let final_state = engine.current_state();
    snapshots.insert(
        "after_counting".into(),
        serde_json::json!({
            "p1_score": final_state.players[0].score,
            "p2_score": final_state.players[1].score,
            "history_event_count": final_state.history.len(),
        }),
    );

    // Build fixture JSON
    let fixture = serde_json::json!({
        "scenarios": [
            {
                "name": "seed_42_full_round",
                "seed": seed,
                "players": [
                    {"id": "p1", "name": "Player 1"},
                    {"id": "p2", "name": "Player 2"}
                ],
                "snapshots": snapshots
            }
        ]
    });

    let fixture_path = concat!(
        env!("CARGO_MANIFEST_DIR"),
        "/tests/fixtures/game_scenarios.json"
    );
    let json_str = serde_json::to_string_pretty(&fixture).unwrap();
    fs::write(fixture_path, &json_str).unwrap();
    println!("Fixture written to {fixture_path}");
}
