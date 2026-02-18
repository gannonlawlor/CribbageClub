use std::collections::HashSet;

use rand::seq::SliceRandom;
use rand::rngs::StdRng;
use rand::SeedableRng;
use serde::Serialize;

use crate::ai::ai_utils::combinations;
use crate::card::{Card, Rank, Suit};
use crate::scoring;

#[derive(Clone, Debug)]
pub struct DiscardOption {
    pub keep: Vec<Card>,
    pub discard: Vec<Card>,
    pub expected_hand_value: f64,
    pub expected_crib_value: f64,
    pub expected_combined_value: f64,
}

/// All 52 cards in the deck.
fn all_cards() -> Vec<Card> {
    let mut cards = Vec::with_capacity(52);
    for &rank in &Rank::ALL {
        for &suit in &Suit::ALL {
            cards.push(Card::new(rank, suit));
        }
    }
    cards
}

/// Analyze all 15 possible discard options from a 6-card hand.
/// Returns options sorted by expected_combined_value descending.
pub fn analyze_all_discards(hand: &[Card], is_dealer: bool) -> Vec<DiscardOption> {
    assert!(hand.len() == 6, "Hand must have exactly 6 cards");

    let hand_set: HashSet<Card> = hand.iter().copied().collect();

    let mut options: Vec<DiscardOption> = combinations(hand, 4)
        .into_iter()
        .map(|keep| {
            let keep_set: HashSet<Card> = keep.iter().copied().collect();
            let discard: Vec<Card> = hand.iter().filter(|c| !keep_set.contains(c)).copied().collect();
            let expected_hand = expected_hand_value(&keep, &hand_set);
            let expected_crib = expected_crib_value(&discard, &hand_set);
            let combined = if is_dealer {
                expected_hand + expected_crib
            } else {
                expected_hand - expected_crib
            };

            DiscardOption {
                keep,
                discard,
                expected_hand_value: expected_hand,
                expected_crib_value: expected_crib,
                expected_combined_value: combined,
            }
        })
        .collect();

    options.sort_by(|a, b| {
        b.expected_combined_value
            .partial_cmp(&a.expected_combined_value)
            .unwrap()
    });

    options
}

/// Returns the optimal discard option (highest expected_combined_value).
pub fn find_optimal_discard(hand: &[Card], is_dealer: bool) -> DiscardOption {
    analyze_all_discards(hand, is_dealer)
        .into_iter()
        .next()
        .unwrap()
}

/// Expected hand score across all possible cut cards (46 remaining).
fn expected_hand_value(keep: &[Card], known_cards: &HashSet<Card>) -> f64 {
    let mut total_score: i32 = 0;
    let mut cut_count: i32 = 0;

    for card in all_cards() {
        if known_cards.contains(&card) {
            continue;
        }
        total_score += scoring::calculate_hand_score(keep, card, false);
        cut_count += 1;
    }

    if cut_count > 0 {
        total_score as f64 / cut_count as f64
    } else {
        0.0
    }
}

/// Maximum number of opponent discard pairs to sample for crib estimation.
/// Full enumeration uses C(46,2) = 1035 pairs × 44 cuts = 45,540 evaluations
/// per discard option. With 15 options per hand, that's ~684K evaluations —
/// too slow for main-thread WASM. Sampling 100 pairs gives ~4,400 evaluations
/// per option (~66K total) with sufficient accuracy for ranking.
const MAX_CRIB_PAIR_SAMPLES: usize = 100;

/// Expected crib value via sampled enumeration.
/// For the 2 discarded cards, sample up to MAX_CRIB_PAIR_SAMPLES opponent
/// discard pairs from the remaining deck, then for each of the remaining
/// cut cards, score the 4-card crib.
fn expected_crib_value(discard: &[Card], known_cards: &HashSet<Card>) -> f64 {
    let remaining: Vec<Card> = all_cards()
        .into_iter()
        .filter(|c| !known_cards.contains(c))
        .collect();

    // Build all possible opponent pair indices
    let mut pairs: Vec<(usize, usize)> = Vec::new();
    for i in 0..remaining.len() {
        for j in (i + 1)..remaining.len() {
            pairs.push((i, j));
        }
    }

    // Sample a subset for performance. Use a deterministic seed derived from
    // the discard cards so results are reproducible for the same hand.
    if pairs.len() > MAX_CRIB_PAIR_SAMPLES {
        let seed = discard[0].rank.ordinal() as u64 * 1000
            + suit_ordinal(discard[0].suit) as u64 * 100
            + discard[1].rank.ordinal() as u64 * 10
            + suit_ordinal(discard[1].suit) as u64;
        let mut rng = StdRng::seed_from_u64(seed);
        pairs.shuffle(&mut rng);
        pairs.truncate(MAX_CRIB_PAIR_SAMPLES);
    }

    let mut total_score: i64 = 0;
    let mut count: i64 = 0;

    for (i, j) in &pairs {
        let crib = [discard[0], discard[1], remaining[*i], remaining[*j]];
        for (k, &cut_card) in remaining.iter().enumerate() {
            if k == *i || k == *j {
                continue;
            }
            total_score +=
                scoring::calculate_hand_score(&crib, cut_card, true) as i64;
            count += 1;
        }
    }

    if count > 0 {
        total_score as f64 / count as f64
    } else {
        0.0
    }
}

fn suit_ordinal(suit: Suit) -> u8 {
    match suit {
        Suit::Clubs => 0,
        Suit::Diamonds => 1,
        Suit::Hearts => 2,
        Suit::Spades => 3,
    }
}

// ── Explain Keep ──────────────────────────────────────────────────────

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct KeepExplanation {
    pub guaranteed_points: HandPatterns,
    pub cut_scores: Vec<CutScore>,
    pub average_hand_score: f64,
    pub average_crib_score: f64,
    pub is_dealer: bool,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct HandPatterns {
    pub fifteens: i32,
    pub pairs: i32,
    pub runs: i32,
    pub flush: bool,
    pub total: i32,
}

#[derive(Clone, Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CutScore {
    pub card: Card,
    pub total_score: i32,
}

/// Explain why a particular keep is good/bad by breaking down guaranteed
/// hand patterns, per-cut scores, and crib impact.
pub fn explain_keep(hand: &[Card], keep: &[Card], is_dealer: bool) -> KeepExplanation {
    assert!(hand.len() == 6, "Hand must have exactly 6 cards");
    assert!(keep.len() == 4, "Keep must have exactly 4 cards");

    // Guaranteed points: score the 4 kept cards alone (no cut)
    let fifteens = scoring::count_15s(keep);
    let pairs = scoring::count_pairs(keep);
    let runs = scoring::count_runs(keep);
    let flush = keep.iter().all(|c| c.suit == keep[0].suit);
    let flush_pts = if flush { 4 } else { 0 };
    let total = fifteens + pairs + runs + flush_pts;

    let guaranteed_points = HandPatterns {
        fifteens,
        pairs,
        runs,
        flush,
        total,
    };

    // Per-cut scores and average
    let hand_set: HashSet<Card> = hand.iter().copied().collect();
    let mut cut_scores = Vec::new();
    let mut hand_total: i32 = 0;

    for card in all_cards() {
        if hand_set.contains(&card) {
            continue;
        }
        let score = scoring::calculate_hand_score(keep, card, false);
        cut_scores.push(CutScore {
            card,
            total_score: score,
        });
        hand_total += score;
    }

    cut_scores.sort_by(|a, b| b.total_score.cmp(&a.total_score));

    let cut_count = cut_scores.len() as f64;
    let average_hand_score = if cut_count > 0.0 {
        hand_total as f64 / cut_count
    } else {
        0.0
    };

    // Crib average
    let keep_set: HashSet<Card> = keep.iter().copied().collect();
    let discard: Vec<Card> = hand.iter().filter(|c| !keep_set.contains(c)).copied().collect();
    let average_crib_score = expected_crib_value(&discard, &hand_set);

    KeepExplanation {
        guaranteed_points,
        cut_scores,
        average_hand_score,
        average_crib_score,
        is_dealer,
    }
}
