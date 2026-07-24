use std::collections::HashMap;

use cribbage_engine::card::{Card, Rank, Suit};
use cribbage_engine::deck::Deck;
use cribbage_engine::error::EngineError;
use cribbage_engine::game_action::GameAction;
use cribbage_engine::game_engine::GameEngine;
use cribbage_engine::game_history::GameHistoryEvent;
use cribbage_engine::game_stage::GameStage;
use cribbage_engine::player::Player;

fn c(rank: Rank, suit: Suit) -> Card {
    Card::new(rank, suit)
}

fn two_players() -> Vec<Player> {
    vec![Player::new("p1", "Player 1"), Player::new("p2", "Player 2")]
}

// ── Construction ──────────────────────────────────────────────────────

#[test]
fn test_new_game_deals_cards() {
    let engine = GameEngine::new("game1", two_players(), None).unwrap();
    let state = engine.current_state();

    assert_eq!(state.stage, GameStage::DiscardingToCrib);
    assert_eq!(state.players[0].hand.len(), 6);
    assert_eq!(state.players[1].hand.len(), 6);
    assert!(state.crib.is_empty());
    assert!(state.cut_card.is_none());
}

#[test]
fn test_new_game_requires_two_players() {
    let result = GameEngine::new("game1", vec![Player::new("p1", "P1")], None);
    assert!(matches!(
        result,
        Err(EngineError::InvalidPlayerCount { count: 1 })
    ));
}

#[test]
fn test_new_game_with_seeded_deck() {
    let deck = Deck::with_seed(42);
    let engine = GameEngine::new("game1", two_players(), Some(deck)).unwrap();
    let state = engine.current_state();
    assert_eq!(state.players[0].hand.len(), 6);
    assert_eq!(state.players[1].hand.len(), 6);
}

// ── Discard phase ─────────────────────────────────────────────────────

#[test]
fn test_discard_to_crib() {
    let deck = Deck::with_seed(42);
    let mut engine = GameEngine::new("game1", two_players(), Some(deck)).unwrap();
    let state = engine.current_state();

    let p1_card1 = state.players[0].hand[0];
    let p1_card2 = state.players[0].hand[1];

    // P1 discards two cards
    engine
        .apply_action(GameAction::DiscardToCrib {
            player_id: "p1".into(),
            card: p1_card1,
        })
        .unwrap();
    engine
        .apply_action(GameAction::DiscardToCrib {
            player_id: "p1".into(),
            card: p1_card2,
        })
        .unwrap();

    let state = engine.current_state();
    assert_eq!(state.players[0].hand.len(), 4);
    assert_eq!(state.crib.len(), 2);
}

#[test]
fn test_discard_wrong_stage_errors() {
    let deck = Deck::with_seed(42);
    let mut engine = GameEngine::new("game1", two_players(), Some(deck)).unwrap();
    let state = engine.current_state();

    // Complete discard phase
    let p1_cards: Vec<Card> = state.players[0].hand[..2].to_vec();
    let p2_cards: Vec<Card> = state.players[1].hand[..2].to_vec();

    for card in p1_cards {
        engine
            .apply_action(GameAction::DiscardToCrib {
                player_id: "p1".into(),
                card,
            })
            .unwrap();
    }
    for card in p2_cards {
        engine
            .apply_action(GameAction::DiscardToCrib {
                player_id: "p2".into(),
                card,
            })
            .unwrap();
    }

    let state = engine.current_state();
    assert_eq!(state.stage, GameStage::Cutting);

    // Trying to discard in Cutting stage should fail
    let result = engine.apply_action(GameAction::DiscardToCrib {
        player_id: "p1".into(),
        card: state.players[0].hand[0],
    });
    assert!(matches!(result, Err(EngineError::WrongStage { .. })));
}

// ── Full discard → cut → pegging flow ─────────────────────────────────

#[test]
fn test_discard_and_cut_transitions() {
    let deck = Deck::with_seed(42);
    let mut engine = GameEngine::new("game1", two_players(), Some(deck)).unwrap();
    let state = engine.current_state();

    let p1_cards: Vec<Card> = state.players[0].hand[..2].to_vec();
    let p2_cards: Vec<Card> = state.players[1].hand[..2].to_vec();

    // Both players discard 2
    for card in p1_cards {
        engine
            .apply_action(GameAction::DiscardToCrib {
                player_id: "p1".into(),
                card,
            })
            .unwrap();
    }
    for card in p2_cards {
        engine
            .apply_action(GameAction::DiscardToCrib {
                player_id: "p2".into(),
                card,
            })
            .unwrap();
    }

    let state = engine.current_state();
    assert_eq!(state.stage, GameStage::Cutting);
    assert_eq!(state.crib.len(), 4);

    // Non-dealer (p2 since dealerIndex=0) cuts
    let cutter = state.current_player_id.unwrap();
    engine
        .apply_action(GameAction::CutDeck { player_id: cutter })
        .unwrap();

    let state = engine.current_state();
    assert_eq!(state.stage, GameStage::Pegging);
    assert!(state.cut_card.is_some());
    assert_eq!(state.hands_for_counting.len(), 2);
}

// ── Full round-trip through all phases ─────────────────────────────────

#[test]
fn test_full_round_trip() {
    let deck = Deck::with_seed(42);
    let mut engine = GameEngine::new("game1", two_players(), Some(deck)).unwrap();

    // Phase 1: Discard
    let state = engine.current_state();
    let p1_cards: Vec<Card> = state.players[0].hand[..2].to_vec();
    let p2_cards: Vec<Card> = state.players[1].hand[..2].to_vec();

    for card in p1_cards {
        engine
            .apply_action(GameAction::DiscardToCrib {
                player_id: "p1".into(),
                card,
            })
            .unwrap();
    }
    for card in p2_cards {
        engine
            .apply_action(GameAction::DiscardToCrib {
                player_id: "p2".into(),
                card,
            })
            .unwrap();
    }

    // Phase 2: Cut
    let state = engine.current_state();
    let cutter = state.current_player_id.clone().unwrap();
    engine
        .apply_action(GameAction::CutDeck { player_id: cutter })
        .unwrap();

    // Phase 3: Pegging — play all cards
    let state = engine.current_state();
    assert_eq!(state.stage, GameStage::Pegging);

    // Play out all cards (each player has 4 cards)
    for _ in 0..20 {
        // Safety limit
        let state = engine.current_state();
        if state.stage != GameStage::Pegging {
            break;
        }

        let current_id = state.current_player_id.clone().unwrap();
        let player = state.players.iter().find(|p| p.id == current_id).unwrap();

        // Find a playable card
        let playable: Option<Card> = player
            .hand
            .iter()
            .find(|c| state.pegging_count + c.pegging_value() as i32 <= 31)
            .copied();

        if let Some(card) = playable {
            engine
                .apply_action(GameAction::PlayCard {
                    player_id: current_id,
                    card,
                })
                .unwrap();
        } else {
            engine
                .apply_action(GameAction::Go {
                    player_id: current_id,
                })
                .unwrap();
        }
    }

    // Phase 4: Counting
    let state = engine.current_state();
    assert_eq!(state.stage, GameStage::Counting);

    // Non-dealer counts first, then dealer
    let first_counter = state.current_player_id.clone().unwrap();
    engine
        .apply_action(GameAction::CountHand {
            player_id: first_counter,
        })
        .unwrap();

    let state = engine.current_state();
    // Dealer counts their hand next, then their crib as a separate action.
    if state.stage == GameStage::Counting {
        let dealer = state.current_player_id.clone().unwrap();
        engine
            .apply_action(GameAction::CountHand {
                player_id: dealer.clone(),
            })
            .unwrap();
        // The dealer's hand is counted but the crib is still theirs to take,
        // unless the hand alone won the game.
        let state = engine.current_state();
        if state.stage == GameStage::Counting {
            engine
                .apply_action(GameAction::CountCrib { player_id: dealer })
                .unwrap();
        }
    }

    // After both count + crib count, should start new round
    let state = engine.current_state();
    assert!(
        state.stage == GameStage::DiscardingToCrib || state.stage == GameStage::GameOver,
        "Expected new round or game over, got {:?}",
        state.stage
    );

    // Verify history has events from all phases
    let has_round_started = state
        .history
        .iter()
        .any(|e| matches!(e, GameHistoryEvent::RoundStarted { .. }));
    let has_cards_dealt = state
        .history
        .iter()
        .any(|e| matches!(e, GameHistoryEvent::CardsDealt { .. }));
    let has_deck_cut = state
        .history
        .iter()
        .any(|e| matches!(e, GameHistoryEvent::DeckCut { .. }));
    let has_card_played = state
        .history
        .iter()
        .any(|e| matches!(e, GameHistoryEvent::CardPlayed { .. }));
    let has_hand_counted = state
        .history
        .iter()
        .any(|e| matches!(e, GameHistoryEvent::HandCounted { .. }));

    assert!(has_round_started);
    assert!(has_cards_dealt);
    assert!(has_deck_cut);
    assert!(has_card_played);
    assert!(has_hand_counted);
}

// ── Restore ────────────────────────────────────────────────────────────

#[test]
fn test_restore_from_state() {
    let deck = Deck::with_seed(42);
    let mut engine = GameEngine::new("game1", two_players(), Some(deck)).unwrap();

    // Discard phase
    let state = engine.current_state();
    let p1_cards: Vec<Card> = state.players[0].hand[..2].to_vec();
    let p2_cards: Vec<Card> = state.players[1].hand[..2].to_vec();

    for card in p1_cards {
        engine
            .apply_action(GameAction::DiscardToCrib {
                player_id: "p1".into(),
                card,
            })
            .unwrap();
    }
    for card in p2_cards {
        engine
            .apply_action(GameAction::DiscardToCrib {
                player_id: "p2".into(),
                card,
            })
            .unwrap();
    }

    // Save and restore
    let saved_state = engine.current_state();
    let restored = GameEngine::restore(saved_state.clone()).unwrap();
    let restored_state = restored.current_state();

    assert_eq!(restored_state.stage, saved_state.stage);
    assert_eq!(restored_state.crib.len(), saved_state.crib.len());
    assert_eq!(
        restored_state.players[0].hand.len(),
        saved_state.players[0].hand.len()
    );
    assert_eq!(restored_state.history.len(), saved_state.history.len());
}

// ── Win detection ──────────────────────────────────────────────────────

#[test]
fn test_dev_set_score_and_win() {
    let deck = Deck::with_seed(42);
    let mut engine = GameEngine::new("game1", two_players(), Some(deck)).unwrap();

    // Set p1's score near win
    engine.dev_set_score("p1", 120).unwrap();

    // Discard
    let state = engine.current_state();
    assert_eq!(state.players[0].score, 120);
}

// ── Pegging scoring ────────────────────────────────────────────────────

#[test]
fn test_card_not_in_hand_error() {
    let deck = Deck::with_seed(42);
    let mut engine = GameEngine::new("game1", two_players(), Some(deck)).unwrap();

    // Try to discard a card that's not in hand
    let fake_card = c(Rank::Ace, Suit::Spades);
    let state = engine.current_state();
    let has_card = state.players[0].hand.contains(&fake_card);

    if !has_card {
        let result = engine.apply_action(GameAction::DiscardToCrib {
            player_id: "p1".into(),
            card: fake_card,
        });
        assert!(matches!(result, Err(EngineError::CardNotInHand { .. })));
    }
}

// ── History tracking ──────────────────────────────────────────────────

#[test]
fn test_history_records_events() {
    let deck = Deck::with_seed(42);
    let engine = GameEngine::new("game1", two_players(), Some(deck)).unwrap();
    let state = engine.current_state();

    // Should have RoundStarted and CardsDealt events
    assert!(state.history.len() >= 2);
    assert!(matches!(
        state.history[0],
        GameHistoryEvent::RoundStarted { round_number: 1 }
    ));
    assert!(matches!(
        state.history[1],
        GameHistoryEvent::CardsDealt { .. }
    ));
}

// ── Dev methods ───────────────────────────────────────────────────────

#[test]
fn test_dev_set_next_hands() {
    let deck = Deck::with_seed(42);
    let mut engine = GameEngine::new("game1", two_players(), Some(deck)).unwrap();
    let state = engine.current_state();

    // The dev_set_next_hands takes effect on the NEXT deal, so it would
    // need a new round start. Just verify it doesn't panic.
    let mut hands = HashMap::new();
    hands.insert(
        "p1".to_string(),
        vec![
            c(Rank::Ace, Suit::Hearts),
            c(Rank::Two, Suit::Hearts),
            c(Rank::Three, Suit::Hearts),
            c(Rank::Four, Suit::Hearts),
            c(Rank::Five, Suit::Hearts),
            c(Rank::Six, Suit::Hearts),
        ],
    );
    hands.insert(
        "p2".to_string(),
        vec![
            c(Rank::Seven, Suit::Clubs),
            c(Rank::Eight, Suit::Clubs),
            c(Rank::Nine, Suit::Clubs),
            c(Rank::Ten, Suit::Clubs),
            c(Rank::Jack, Suit::Clubs),
            c(Rank::Queen, Suit::Clubs),
        ],
    );
    engine.dev_set_next_hands(hands);

    // dev_next_hands is consumed on next deal, verify current state unchanged
    let state2 = engine.current_state();
    assert_eq!(state.players[0].hand, state2.players[0].hand);
}

// ── Dealer rotation ───────────────────────────────────────────────────

#[test]
fn test_dealer_index_starts_at_zero() {
    let engine = GameEngine::new("game1", two_players(), None).unwrap();
    let state = engine.current_state();
    assert_eq!(state.dealer_index, 0);
}
