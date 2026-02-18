use cribbage_engine::card::{Card, Rank, Suit};
use cribbage_engine::scoring::*;
use cribbage_engine::score_breakdown;

fn c(rank: Rank, suit: Suit) -> Card {
    Card::new(rank, suit)
}

// ── count_15s ──────────────────────────────────────────────

#[test]
fn test_fifteen_two_cards() {
    // 5 + 10 = 15 → 2 pts
    let cards = vec![
        c(Rank::Five, Suit::Hearts),
        c(Rank::Ten, Suit::Spades),
    ];
    assert_eq!(count_15s(&cards), 2);
}

#[test]
fn test_fifteen_three_cards() {
    // 5 + 5 + 5 = 15 → 2 pts
    let cards = vec![
        c(Rank::Five, Suit::Hearts),
        c(Rank::Five, Suit::Diamonds),
        c(Rank::Five, Suit::Clubs),
    ];
    assert_eq!(count_15s(&cards), 2);
}

#[test]
fn test_fifteen_multiple_combos() {
    // 5H + 5D + 5C + 5S + JH
    // Four 5+J=15 combos = 8, plus 5+5+5=15 x 4 ways (C(4,3))= 4 → total 8+8 = 16
    let cards = vec![
        c(Rank::Five, Suit::Hearts),
        c(Rank::Five, Suit::Diamonds),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Five, Suit::Spades),
        c(Rank::Jack, Suit::Hearts),
    ];
    assert_eq!(count_15s(&cards), 16);
}

#[test]
fn test_no_fifteens() {
    let cards = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Two, Suit::Spades),
        c(Rank::Three, Suit::Clubs),
    ];
    assert_eq!(count_15s(&cards), 0);
}

// ── count_pairs ────────────────────────────────────────────

#[test]
fn test_one_pair() {
    let cards = vec![
        c(Rank::Five, Suit::Hearts),
        c(Rank::Five, Suit::Diamonds),
        c(Rank::Ten, Suit::Clubs),
    ];
    assert_eq!(count_pairs(&cards), 2);
}

#[test]
fn test_three_of_a_kind() {
    // 3 of a kind = 3*2 = 6 pts
    let cards = vec![
        c(Rank::Five, Suit::Hearts),
        c(Rank::Five, Suit::Diamonds),
        c(Rank::Five, Suit::Clubs),
    ];
    assert_eq!(count_pairs(&cards), 6);
}

#[test]
fn test_four_of_a_kind() {
    // 4 of a kind = 4*3 = 12 pts
    let cards = vec![
        c(Rank::Five, Suit::Hearts),
        c(Rank::Five, Suit::Diamonds),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Five, Suit::Spades),
    ];
    assert_eq!(count_pairs(&cards), 12);
}

#[test]
fn test_two_pairs() {
    let cards = vec![
        c(Rank::Five, Suit::Hearts),
        c(Rank::Five, Suit::Diamonds),
        c(Rank::Ten, Suit::Clubs),
        c(Rank::Ten, Suit::Spades),
    ];
    assert_eq!(count_pairs(&cards), 4);
}

#[test]
fn test_no_pairs() {
    let cards = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Two, Suit::Spades),
        c(Rank::Three, Suit::Clubs),
    ];
    assert_eq!(count_pairs(&cards), 0);
}

// ── count_runs ─────────────────────────────────────────────

#[test]
fn test_run_of_three() {
    let cards = vec![
        c(Rank::Three, Suit::Hearts),
        c(Rank::Four, Suit::Diamonds),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Nine, Suit::Spades),
        c(Rank::King, Suit::Hearts),
    ];
    assert_eq!(count_runs(&cards), 3);
}

#[test]
fn test_run_of_four() {
    let cards = vec![
        c(Rank::Three, Suit::Hearts),
        c(Rank::Four, Suit::Diamonds),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Six, Suit::Spades),
        c(Rank::King, Suit::Hearts),
    ];
    assert_eq!(count_runs(&cards), 4);
}

#[test]
fn test_run_of_five() {
    let cards = vec![
        c(Rank::Three, Suit::Hearts),
        c(Rank::Four, Suit::Diamonds),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Six, Suit::Spades),
        c(Rank::Seven, Suit::Hearts),
    ];
    assert_eq!(count_runs(&cards), 5);
}

#[test]
fn test_double_run() {
    // 3-4-5-5 → run of 3 × 2 = 6
    let cards = vec![
        c(Rank::Three, Suit::Hearts),
        c(Rank::Four, Suit::Diamonds),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Five, Suit::Spades),
        c(Rank::King, Suit::Hearts),
    ];
    assert_eq!(count_runs(&cards), 6);
}

#[test]
fn test_triple_run() {
    // 3-4-5-5-5 → run of 3 × 3 = 9
    let cards = vec![
        c(Rank::Three, Suit::Hearts),
        c(Rank::Four, Suit::Diamonds),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Five, Suit::Spades),
        c(Rank::Five, Suit::Hearts),
    ];
    assert_eq!(count_runs(&cards), 9);
}

#[test]
fn test_double_double_run() {
    // 3-3-4-5-5 → run of 3 × 2 × 2 = 12
    let cards = vec![
        c(Rank::Three, Suit::Hearts),
        c(Rank::Three, Suit::Diamonds),
        c(Rank::Four, Suit::Clubs),
        c(Rank::Five, Suit::Spades),
        c(Rank::Five, Suit::Hearts),
    ];
    assert_eq!(count_runs(&cards), 12);
}

#[test]
fn test_no_runs() {
    let cards = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Three, Suit::Diamonds),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Seven, Suit::Spades),
        c(Rank::Nine, Suit::Hearts),
    ];
    assert_eq!(count_runs(&cards), 0);
}

#[test]
fn test_run_too_short() {
    // Only 2 consecutive → no run
    let cards = vec![
        c(Rank::Three, Suit::Hearts),
        c(Rank::Four, Suit::Diamonds),
        c(Rank::Nine, Suit::Clubs),
    ];
    assert_eq!(count_runs(&cards), 0);
}

// ── count_flushes ──────────────────────────────────────────

#[test]
fn test_five_card_flush() {
    let hand = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Three, Suit::Hearts),
        c(Rank::Five, Suit::Hearts),
        c(Rank::Seven, Suit::Hearts),
    ];
    let cut = c(Rank::Nine, Suit::Hearts);
    assert_eq!(count_flushes(&hand, cut, false), 5);
}

#[test]
fn test_four_card_flush() {
    let hand = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Three, Suit::Hearts),
        c(Rank::Five, Suit::Hearts),
        c(Rank::Seven, Suit::Hearts),
    ];
    let cut = c(Rank::Nine, Suit::Spades);
    assert_eq!(count_flushes(&hand, cut, false), 4);
}

#[test]
fn test_crib_flush_requires_five() {
    // In crib, 4-card flush doesn't count
    let hand = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Three, Suit::Hearts),
        c(Rank::Five, Suit::Hearts),
        c(Rank::Seven, Suit::Hearts),
    ];
    let cut = c(Rank::Nine, Suit::Spades);
    assert_eq!(count_flushes(&hand, cut, true), 0);
}

#[test]
fn test_crib_five_card_flush() {
    let hand = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Three, Suit::Hearts),
        c(Rank::Five, Suit::Hearts),
        c(Rank::Seven, Suit::Hearts),
    ];
    let cut = c(Rank::Nine, Suit::Hearts);
    assert_eq!(count_flushes(&hand, cut, true), 5);
}

#[test]
fn test_no_flush() {
    let hand = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Three, Suit::Spades),
        c(Rank::Five, Suit::Hearts),
        c(Rank::Seven, Suit::Hearts),
    ];
    let cut = c(Rank::Nine, Suit::Hearts);
    assert_eq!(count_flushes(&hand, cut, false), 0);
}

// ── count_nobs ─────────────────────────────────────────────

#[test]
fn test_nobs_present() {
    let hand = vec![
        c(Rank::Jack, Suit::Hearts),
        c(Rank::Three, Suit::Spades),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Seven, Suit::Diamonds),
    ];
    let cut = c(Rank::Nine, Suit::Hearts);
    assert_eq!(count_nobs(&hand, cut), 1);
}

#[test]
fn test_nobs_absent_wrong_suit() {
    let hand = vec![
        c(Rank::Jack, Suit::Spades),
        c(Rank::Three, Suit::Spades),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Seven, Suit::Diamonds),
    ];
    let cut = c(Rank::Nine, Suit::Hearts);
    assert_eq!(count_nobs(&hand, cut), 0);
}

#[test]
fn test_nobs_absent_no_jack() {
    let hand = vec![
        c(Rank::Queen, Suit::Hearts),
        c(Rank::Three, Suit::Spades),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Seven, Suit::Diamonds),
    ];
    let cut = c(Rank::Nine, Suit::Hearts);
    assert_eq!(count_nobs(&hand, cut), 0);
}

// ── calculate_hand_score (integration) ─────────────────────

#[test]
fn test_perfect_29_hand() {
    // 5H 5D 5C JH, cut 5S → 29 points
    // 15s: 16, pairs: 12, nobs: 1
    let hand = vec![
        c(Rank::Five, Suit::Hearts),
        c(Rank::Five, Suit::Diamonds),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Jack, Suit::Spades),
    ];
    let cut = c(Rank::Five, Suit::Spades);
    assert_eq!(calculate_hand_score(&hand, cut, false), 29);
}

#[test]
fn test_zero_hand() {
    // A♥ 2♠ 8♣ K♦, cut 9♣ → no 15s, no pairs, no runs, no flush, no nobs = 0
    let hand = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Two, Suit::Spades),
        c(Rank::Eight, Suit::Clubs),
        c(Rank::King, Suit::Diamonds),
    ];
    let cut = c(Rank::Nine, Suit::Clubs);
    assert_eq!(calculate_hand_score(&hand, cut, false), 0);
}

#[test]
fn test_hand_with_flush_and_fifteens() {
    // 2H 3H 5H 10H, cut KS
    // 15s: 5+10=15, 5+K=15, 2+3+10=15, 2+3+K=15 → 8
    // Runs: 2-3 only (length 2), no run
    // Flush: 4 (hand only)
    // Total: 8 + 4 = 12
    let hand = vec![
        c(Rank::Two, Suit::Hearts),
        c(Rank::Three, Suit::Hearts),
        c(Rank::Five, Suit::Hearts),
        c(Rank::Ten, Suit::Hearts),
    ];
    let cut = c(Rank::King, Suit::Spades);
    assert_eq!(calculate_hand_score(&hand, cut, false), 12);
}

#[test]
fn test_run_with_nobs() {
    // JH 10S QD AH, cut KH
    // 15s: none
    // Runs: 10-J-Q-K = 4
    // Nobs: JH matches cut suit H → 1
    // Total: 5
    let hand = vec![
        c(Rank::Jack, Suit::Hearts),
        c(Rank::Ten, Suit::Spades),
        c(Rank::Queen, Suit::Diamonds),
        c(Rank::Ace, Suit::Hearts),
    ];
    let cut = c(Rank::King, Suit::Hearts);
    assert_eq!(calculate_hand_score(&hand, cut, false), 5);
}

// ── score_breakdown ────────────────────────────────────────

#[test]
fn test_breakdown_perfect_29() {
    let hand = vec![
        c(Rank::Five, Suit::Hearts),
        c(Rank::Five, Suit::Diamonds),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Jack, Suit::Spades),
    ];
    let cut = c(Rank::Five, Suit::Spades);
    let bd = score_breakdown::calculate(&hand, cut, false);
    assert_eq!(bd.fifteens, 16);
    assert_eq!(bd.pairs, 12);
    assert_eq!(bd.runs, 0);
    assert_eq!(bd.flushes, 0);
    assert_eq!(bd.nobs, 1);
    assert_eq!(bd.total(), 29);
}

#[test]
fn test_breakdown_flush_hand() {
    // A♥ 3♥ 5♥ 7♥, cut 9♥
    // 15s: 1+5+9=15, 3+5+7=15 → 4
    // Flush: 5 (all hearts)
    // Total: 9
    let hand = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Three, Suit::Hearts),
        c(Rank::Five, Suit::Hearts),
        c(Rank::Seven, Suit::Hearts),
    ];
    let cut = c(Rank::Nine, Suit::Hearts);
    let bd = score_breakdown::calculate(&hand, cut, false);
    assert_eq!(bd.fifteens, 4);
    assert_eq!(bd.pairs, 0);
    assert_eq!(bd.runs, 0);
    assert_eq!(bd.flushes, 5);
    assert_eq!(bd.nobs, 0);
    assert_eq!(bd.total(), 9);
}

// ── additional hand scoring tests ──────────────────────────

#[test]
fn test_double_run_with_fifteens() {
    // 4C 5H 5D 6S, cut 9C
    // Runs: 4-5-6 × 2 = 6
    // Pairs: 5-5 = 2
    // 15s: 5+6+4=15 (×2 for each 5) = 4, 6+9=15 = 2 → 6
    // Total: 6 + 2 + 6 = 14
    let hand = vec![
        c(Rank::Four, Suit::Clubs),
        c(Rank::Five, Suit::Hearts),
        c(Rank::Five, Suit::Diamonds),
        c(Rank::Six, Suit::Spades),
    ];
    let cut = c(Rank::Nine, Suit::Clubs);
    assert_eq!(calculate_hand_score(&hand, cut, false), 14);
}

#[test]
fn test_fifteen_with_face_cards() {
    // 5H KD QS 10C, cut 5S
    // 15s: 5+10=15, 5+Q=15, 5+K=15, 5S+10=15, 5S+Q=15, 5S+K=15 = 12
    // Pairs: 5-5 = 2
    // No runs (10-Q-K is not consecutive because J is missing)
    // Total: 14
    let hand = vec![
        c(Rank::Five, Suit::Hearts),
        c(Rank::King, Suit::Diamonds),
        c(Rank::Queen, Suit::Spades),
        c(Rank::Ten, Suit::Clubs),
    ];
    let cut = c(Rank::Five, Suit::Spades);
    assert_eq!(calculate_hand_score(&hand, cut, false), 14);
}
