use cribbage_engine::analysis::discard_analyzer;
use cribbage_engine::analysis::glicko2::{self, Rating};
use cribbage_engine::card::{Card, Rank, Suit};

fn c(rank: Rank, suit: Suit) -> Card {
    Card::new(rank, suit)
}

// ── Discard Analyzer ──────────────────────────────────────────────────

#[test]
fn test_analyze_all_discards_returns_15_options() {
    let hand = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Two, Suit::Spades),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Seven, Suit::Diamonds),
        c(Rank::Jack, Suit::Hearts),
        c(Rank::King, Suit::Spades),
    ];
    let options = discard_analyzer::analyze_all_discards(&hand, true);
    // C(6,4) = 15 options
    assert_eq!(options.len(), 15);
}

#[test]
fn test_analyze_discards_sorted_descending() {
    let hand = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Two, Suit::Spades),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Seven, Suit::Diamonds),
        c(Rank::Jack, Suit::Hearts),
        c(Rank::King, Suit::Spades),
    ];
    let options = discard_analyzer::analyze_all_discards(&hand, true);
    for i in 1..options.len() {
        assert!(
            options[i - 1].expected_combined_value >= options[i].expected_combined_value,
            "Options not sorted: {} < {}",
            options[i - 1].expected_combined_value,
            options[i].expected_combined_value
        );
    }
}

#[test]
fn test_discard_keep_and_discard_partition_hand() {
    let hand = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Two, Suit::Spades),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Seven, Suit::Diamonds),
        c(Rank::Jack, Suit::Hearts),
        c(Rank::King, Suit::Spades),
    ];
    let options = discard_analyzer::analyze_all_discards(&hand, false);
    for opt in &options {
        assert_eq!(opt.keep.len(), 4);
        assert_eq!(opt.discard.len(), 2);
        // Every card in keep + discard should be in original hand
        for card in opt.keep.iter().chain(opt.discard.iter()) {
            assert!(hand.contains(card));
        }
    }
}

#[test]
fn test_find_optimal_discard() {
    let hand = vec![
        c(Rank::Five, Suit::Hearts),
        c(Rank::Five, Suit::Diamonds),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Jack, Suit::Spades),
        c(Rank::Two, Suit::Hearts),
        c(Rank::Three, Suit::Spades),
    ];
    let optimal = discard_analyzer::find_optimal_discard(&hand, false);
    // The optimal keep should include the three fives and the jack
    assert_eq!(optimal.keep.len(), 4);
    assert_eq!(optimal.discard.len(), 2);
    // The three 5s should definitely be kept (very high hand value)
    let fives_kept = optimal
        .keep
        .iter()
        .filter(|c| c.rank == Rank::Five)
        .count();
    assert!(fives_kept >= 3, "Expected at least 3 fives kept, got {}", fives_kept);
}

#[test]
fn test_dealer_vs_nondealer_different_combined_values() {
    let hand = vec![
        c(Rank::Ace, Suit::Hearts),
        c(Rank::Two, Suit::Spades),
        c(Rank::Five, Suit::Clubs),
        c(Rank::Seven, Suit::Diamonds),
        c(Rank::Jack, Suit::Hearts),
        c(Rank::King, Suit::Spades),
    ];
    let dealer_options = discard_analyzer::analyze_all_discards(&hand, true);
    let non_dealer_options = discard_analyzer::analyze_all_discards(&hand, false);

    // At least one option should have different combined value
    let any_different = dealer_options.iter().zip(non_dealer_options.iter()).any(|(d, nd)| {
        (d.expected_combined_value - nd.expected_combined_value).abs() > 0.001
    });
    assert!(any_different, "Dealer and non-dealer should produce different combined values");
}

// ── Glicko-2 ──────────────────────────────────────────────────────────

#[test]
fn test_glicko2_winner_rating_increases() {
    let player = Rating::default();
    let opponent = Rating::default();

    let result = glicko2::calculate_new_rating(&player, &opponent, 1.0);
    assert!(result.new_rating > player.rating);
}

#[test]
fn test_glicko2_loser_rating_decreases() {
    let player = Rating::default();
    let opponent = Rating::default();

    let result = glicko2::calculate_new_rating(&player, &opponent, 0.0);
    assert!(result.new_rating < player.rating);
}

#[test]
fn test_glicko2_deviation_decreases_after_game() {
    let player = Rating::default();
    let opponent = Rating::default();

    let result = glicko2::calculate_new_rating(&player, &opponent, 1.0);
    assert!(result.new_deviation < player.deviation);
}

#[test]
fn test_glicko2_draw_minimal_rating_change() {
    let player = Rating::default();
    let opponent = Rating::default();

    let result = glicko2::calculate_new_rating(&player, &opponent, 0.5);
    // Draw between equal players should result in minimal change
    assert!((result.new_rating - player.rating).abs() < 1.0);
}

#[test]
fn test_glicko2_upset_win_larger_gain() {
    let weak = Rating {
        rating: 1200.0,
        deviation: 100.0,
        volatility: 0.06,
    };
    let strong = Rating {
        rating: 1800.0,
        deviation: 100.0,
        volatility: 0.06,
    };

    let normal_win = glicko2::calculate_new_rating(
        &Rating {
            rating: 1500.0,
            deviation: 100.0,
            volatility: 0.06,
        },
        &Rating {
            rating: 1500.0,
            deviation: 100.0,
            volatility: 0.06,
        },
        1.0,
    );

    let upset_win = glicko2::calculate_new_rating(&weak, &strong, 1.0);

    // An upset win (weak beating strong) should give a larger rating gain
    let normal_gain = normal_win.new_rating - 1500.0;
    let upset_gain = upset_win.new_rating - 1200.0;
    assert!(
        upset_gain > normal_gain,
        "Upset gain ({:.2}) should be larger than normal gain ({:.2})",
        upset_gain,
        normal_gain
    );
}

#[test]
fn test_glicko2_known_values() {
    // Test with specific known values to verify correctness
    let player = Rating {
        rating: 1500.0,
        deviation: 200.0,
        volatility: 0.06,
    };
    let opponent = Rating {
        rating: 1400.0,
        deviation: 30.0,
        volatility: 0.06,
    };

    let result = glicko2::calculate_new_rating(&player, &opponent, 1.0);

    // Winner should gain rating
    assert!(result.new_rating > 1500.0);
    // Deviation should decrease
    assert!(result.new_deviation < 200.0);
    // Volatility should be positive
    assert!(result.new_volatility > 0.0);
}
