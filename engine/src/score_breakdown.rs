use crate::card::Card;
use crate::game_history::ScoreBreakdown;
use crate::scoring;

/// Calculate a detailed breakdown of hand/crib scoring.
pub fn calculate(hand: &[Card], cut_card: Card, is_crib: bool) -> ScoreBreakdown {
    let all_cards: Vec<Card> = hand.iter().copied().chain(std::iter::once(cut_card)).collect();
    let fifteens = scoring::count_15s(&all_cards);
    let pairs = scoring::count_pairs(&all_cards);
    let runs = scoring::count_runs(&all_cards);
    let flushes = scoring::count_flushes(hand, cut_card, is_crib);
    let nobs = scoring::count_nobs(hand, cut_card);
    ScoreBreakdown {
        fifteens,
        pairs,
        runs,
        flushes,
        nobs,
        total_score: fifteens + pairs + runs + flushes + nobs,
    }
}
