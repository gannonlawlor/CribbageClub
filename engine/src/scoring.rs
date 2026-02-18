use std::collections::HashMap;

use crate::card::{Card, Rank};

/// Calculate the total hand score (15s + pairs + runs + flushes + nobs).
pub fn calculate_hand_score(hand: &[Card], cut_card: Card, is_crib: bool) -> i32 {
    let all_cards: Vec<Card> = hand.iter().copied().chain(std::iter::once(cut_card)).collect();
    let mut score = 0;
    score += count_15s(&all_cards);
    score += count_pairs(&all_cards);
    score += count_runs(&all_cards);
    score += count_flushes(hand, cut_card, is_crib);
    score += count_nobs(hand, cut_card);
    score
}

/// Count 15s using bitmask subset enumeration. Each combination summing to 15 scores 2 points.
pub fn count_15s(cards: &[Card]) -> i32 {
    let values: Vec<u8> = cards.iter().map(|c| c.pegging_value()).collect();
    let n = cards.len();
    let mut count: i32 = 0;
    for i in 1..(1u32 << n) {
        let mut sum: u32 = 0;
        for (j, &val) in values.iter().enumerate() {
            if (i >> j) & 1 == 1 {
                sum += val as u32;
            }
        }
        if sum == 15 {
            count += 1;
        }
    }
    count * 2
}

/// Count pairs. Each pair of same-rank cards scores 2 points.
/// n cards of same rank = n*(n-1) points.
pub fn count_pairs(cards: &[Card]) -> i32 {
    let mut rank_counts: HashMap<Rank, i32> = HashMap::new();
    for card in cards {
        *rank_counts.entry(card.rank).or_insert(0) += 1;
    }
    let mut score = 0;
    for &count in rank_counts.values() {
        if count >= 2 {
            score += count * (count - 1); // n choose 2 pairs, each worth 2
        }
    }
    score
}

/// Count runs. Finds the longest consecutive rank sequence (>= 3),
/// multiplied by the product of duplicate counts within the run.
pub fn count_runs(cards: &[Card]) -> i32 {
    let mut rank_counts: HashMap<Rank, i32> = HashMap::new();
    for card in cards {
        *rank_counts.entry(card.rank).or_insert(0) += 1;
    }

    let mut sorted_ranks: Vec<Rank> = rank_counts.keys().copied().collect();
    sorted_ranks.sort_by_key(|r| r.ordinal());

    if sorted_ranks.len() < 3 {
        return 0;
    }

    let mut longest_run_length: usize = 1;
    let mut current_run_length: usize = 1;
    let mut run_start: usize = 0;

    for i in 1..sorted_ranks.len() {
        if sorted_ranks[i].ordinal() == sorted_ranks[i - 1].ordinal() + 1 {
            current_run_length += 1;
        } else {
            if current_run_length > longest_run_length {
                longest_run_length = current_run_length;
                run_start = i - current_run_length;
            }
            current_run_length = 1;
        }
    }

    // Check final run
    if current_run_length > longest_run_length {
        longest_run_length = current_run_length;
        run_start = sorted_ranks.len() - current_run_length;
    }

    if longest_run_length >= 3 {
        let mut multiplier: i32 = 1;
        for i in run_start..run_start + longest_run_length {
            multiplier *= rank_counts[&sorted_ranks[i]];
        }
        (longest_run_length as i32) * multiplier
    } else {
        0
    }
}

/// Count flushes. 4-card hand flush = 4 pts (not in crib), 5-card flush = 5 pts.
pub fn count_flushes(hand: &[Card], cut_card: Card, is_crib: bool) -> i32 {
    if hand.is_empty() {
        return 0;
    }
    let hand_suit = hand[0].suit;
    let hand_flush = hand.iter().all(|c| c.suit == hand_suit);

    if hand_flush && cut_card.suit == hand_suit {
        5
    } else if hand_flush && !is_crib {
        4
    } else {
        0
    }
}

/// Count nobs: 1 point if hand contains the Jack of the cut card's suit.
pub fn count_nobs(hand: &[Card], cut_card: Card) -> i32 {
    if hand
        .iter()
        .any(|c| c.rank == Rank::Jack && c.suit == cut_card.suit)
    {
        1
    } else {
        0
    }
}
