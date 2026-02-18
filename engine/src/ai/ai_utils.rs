use crate::card::Card;

/// Generate all k-combinations from a slice.
pub fn combinations<T: Clone>(list: &[T], k: usize) -> Vec<Vec<T>> {
    if k == 0 {
        return vec![vec![]];
    }
    if list.is_empty() {
        return vec![];
    }
    let head = &list[0];
    let tail = &list[1..];

    let mut result: Vec<Vec<T>> = combinations(tail, k - 1)
        .into_iter()
        .map(|mut combo| {
            combo.insert(0, head.clone());
            combo
        })
        .collect();

    result.extend(combinations(tail, k));
    result
}

/// Find a card that continues a run from the recently played cards.
pub fn find_run_continuation(playable_cards: &[Card], played_cards: &[Card]) -> Option<Card> {
    let recent: &[Card] = if played_cards.len() > 3 {
        &played_cards[played_cards.len() - 3..]
    } else {
        played_cards
    };

    if recent.len() < 2 {
        return None;
    }

    let mut recent_ranks: Vec<u8> = recent.iter().map(|c| c.rank.ordinal()).collect();
    recent_ranks.sort();

    // Check if recent cards are consecutive
    let is_consecutive = recent_ranks.windows(2).all(|w| w[1] == w[0] + 1);

    if is_consecutive {
        let min_rank = recent_ranks[0];
        let max_rank = recent_ranks[recent_ranks.len() - 1];

        for card in playable_cards {
            let rank = card.rank.ordinal();
            if (min_rank > 0 && rank == min_rank - 1) || rank == max_rank + 1 {
                return Some(*card);
            }
        }
    }
    None
}
