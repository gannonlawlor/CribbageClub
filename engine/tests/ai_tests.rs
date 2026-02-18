use cribbage_engine::ai::ai_player::{create_ai, process_ai_actions, AIDifficulty};
use cribbage_engine::card::{Card, Rank, Suit};
use cribbage_engine::deck::Deck;
use cribbage_engine::game_engine::GameEngine;
use cribbage_engine::game_stage::GameStage;
use cribbage_engine::player::Player;

fn c(rank: Rank, suit: Suit) -> Card {
    Card::new(rank, suit)
}

fn two_players_with_ai() -> Vec<Player> {
    vec![
        Player::new("human", "Human"),
        Player::new("ai", "AI"),
    ]
}

// ── AI creates valid actions at every stage ───────────────────────────

fn run_full_ai_game(difficulty: AIDifficulty) {
    let deck = Deck::with_seed(123);
    let mut engine = GameEngine::new("game1", two_players_with_ai(), Some(deck)).unwrap();

    // Play a complete game with both players using AI
    let ai_human = create_ai("human", difficulty);
    let ai_bot = create_ai("ai", difficulty);

    for _ in 0..500 {
        // Safety limit for iterations
        let state = engine.current_state();
        if state.stage == GameStage::GameOver {
            break;
        }

        let current_id = state.current_player_id.clone().unwrap();
        let action = if current_id == "human" {
            ai_human.get_next_action(&state)
        } else {
            ai_bot.get_next_action(&state)
        };

        if let Some(action) = action {
            engine.apply_action(action).unwrap();
        } else {
            panic!(
                "AI returned None for player {} in stage {:?}",
                current_id, state.stage
            );
        }
    }

    let state = engine.current_state();
    assert_eq!(state.stage, GameStage::GameOver);
    assert!(
        state.players[0].score >= 121 || state.players[1].score >= 121,
        "Expected a winner with score >= 121, got {} and {}",
        state.players[0].score,
        state.players[1].score
    );
}

#[test]
fn test_basic_ai_full_game() {
    run_full_ai_game(AIDifficulty::Basic);
}

#[test]
fn test_medium_ai_full_game() {
    run_full_ai_game(AIDifficulty::Medium);
}

#[test]
fn test_hard_ai_full_game() {
    run_full_ai_game(AIDifficulty::Hard);
}

// ── process_ai_actions convenience function ──────────────────────────

#[test]
fn test_process_ai_actions() {
    let deck = Deck::with_seed(42);
    let mut engine = GameEngine::new("game1", two_players_with_ai(), Some(deck)).unwrap();

    // Have AI process its actions (it's p1's turn first since human is first player)
    let state = engine.current_state();
    assert_eq!(state.stage, GameStage::DiscardingToCrib);

    let state =
        process_ai_actions(&mut engine, "human", AIDifficulty::Basic, 10).unwrap();
    // After discarding 2 cards, p1 should have 4 cards
    let human = state.players.iter().find(|p| p.id == "human").unwrap();
    assert_eq!(human.hand.len(), 4);
}

// ── AI discard decisions ─────────────────────────────────────────────

#[test]
fn test_basic_ai_discard_returns_cards() {
    let ai = create_ai("p1", AIDifficulty::Basic);
    let hand = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Two, Suit::Spades),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Seven, Suit::Diamonds),
        c(Rank::Jack, Suit::Hearts),
        c(Rank::King, Suit::Spades),
    ];
    let discards = ai.choose_cards_to_discard(&hand, false);
    assert!(discards.len() >= 1);
    // All discards should be from the hand
    for card in &discards {
        assert!(hand.contains(card));
    }
}

#[test]
fn test_medium_ai_discard_returns_cards() {
    let ai = create_ai("p1", AIDifficulty::Medium);
    let hand = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Two, Suit::Spades),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Seven, Suit::Diamonds),
        c(Rank::Jack, Suit::Hearts),
        c(Rank::King, Suit::Spades),
    ];
    let discards = ai.choose_cards_to_discard(&hand, true);
    assert_eq!(discards.len(), 2);
    for card in &discards {
        assert!(hand.contains(card));
    }
}

#[test]
fn test_hard_ai_discard_returns_cards() {
    let ai = create_ai("p1", AIDifficulty::Hard);
    let hand = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Two, Suit::Spades),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Seven, Suit::Diamonds),
        c(Rank::Jack, Suit::Hearts),
        c(Rank::King, Suit::Spades),
    ];
    let discards = ai.choose_cards_to_discard(&hand, false);
    assert_eq!(discards.len(), 2);
    for card in &discards {
        assert!(hand.contains(card));
    }
}

// ── AI pegging decisions ─────────────────────────────────────────────

#[test]
fn test_ai_pegging_plays_valid_card() {
    let ai = create_ai("p1", AIDifficulty::Basic);
    let hand = vec![
        c(Rank::Five, Suit::Hearts),
        c(Rank::Seven, Suit::Diamonds),
        c(Rank::Jack, Suit::Clubs),
        c(Rank::King, Suit::Spades),
    ];
    let card = ai.choose_card_to_play(&hand, &[], 0);
    assert!(card.is_some());
    let played = card.unwrap();
    assert!(hand.contains(&played));
    assert!(played.pegging_value() as i32 <= 31);
}

#[test]
fn test_ai_pegging_returns_none_when_no_playable() {
    let ai = create_ai("p1", AIDifficulty::Basic);
    let hand = vec![
        c(Rank::King, Suit::Hearts),
        c(Rank::Queen, Suit::Diamonds),
    ];
    // Count is 25, so no 10-value card can be played
    let card = ai.choose_card_to_play(&hand, &[], 25);
    assert!(card.is_none());
}

#[test]
fn test_ai_pegging_prefers_15() {
    let ai = create_ai("p1", AIDifficulty::Basic);
    let hand = vec![
        c(Rank::Two, Suit::Hearts),
        c(Rank::Five, Suit::Diamonds),
        c(Rank::Seven, Suit::Clubs),
    ];
    // Count is 10, playing 5 would make 15
    let card = ai.choose_card_to_play(&hand, &[], 10);
    assert_eq!(card, Some(c(Rank::Five, Suit::Diamonds)));
}

#[test]
fn test_ai_pegging_prefers_31() {
    let ai = create_ai("p1", AIDifficulty::Basic);
    let hand = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Five, Suit::Diamonds),
    ];
    // Count is 26, playing 5 would make 31
    let card = ai.choose_card_to_play(&hand, &[], 26);
    assert_eq!(card, Some(c(Rank::Five, Suit::Diamonds)));
}

// ── Multiple seeds produce different games ───────────────────────────

#[test]
fn test_different_seeds_different_hands() {
    let engine1 = GameEngine::new("g1", two_players_with_ai(), Some(Deck::with_seed(1))).unwrap();
    let engine2 = GameEngine::new("g2", two_players_with_ai(), Some(Deck::with_seed(2))).unwrap();

    let s1 = engine1.current_state();
    let s2 = engine2.current_state();

    // Very unlikely to be the same hand with different seeds
    assert_ne!(s1.players[0].hand, s2.players[0].hand);
}
