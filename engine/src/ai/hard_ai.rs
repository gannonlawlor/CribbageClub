use std::collections::HashMap;

use crate::card::{Card, Rank, Suit};
use crate::game_action::GameAction;
use crate::game_stage::GameStage;
use crate::game_state::GameState;
use crate::scoring;

use super::ai_player::{crib_pending, is_dealer, AIPlayer};
use super::ai_utils::combinations;

pub struct HardAI {
    id: String,
}

impl HardAI {
    pub fn new(id: impl Into<String>) -> Self {
        HardAI { id: id.into() }
    }
}

impl AIPlayer for HardAI {
    fn player_id(&self) -> &str {
        &self.id
    }

    fn get_next_action(&self, game_state: &GameState) -> Option<GameAction> {
        if game_state.current_player_id.as_deref() != Some(&self.id) {
            return None;
        }
        let player = game_state.players.iter().find(|p| p.id == self.id)?;

        match game_state.stage {
            GameStage::DiscardingToCrib => {
                if player.hand.len() > 4 {
                    let to_discard =
                        self.choose_cards_to_discard(&player.hand, is_dealer(game_state, &self.id));
                    to_discard.first().map(|&card| GameAction::DiscardToCrib {
                        player_id: self.id.clone(),
                        card,
                    })
                } else {
                    None
                }
            }
            GameStage::Cutting => Some(GameAction::CutDeck {
                player_id: self.id.clone(),
            }),
            GameStage::Pegging => {
                let card = self.choose_card_to_play(
                    &player.hand,
                    &game_state.played_cards,
                    game_state.pegging_count,
                );
                Some(match card {
                    Some(c) => GameAction::PlayCard {
                        player_id: self.id.clone(),
                        card: c,
                    },
                    None => GameAction::Go {
                        player_id: self.id.clone(),
                    },
                })
            }
            GameStage::Counting => Some(
                if is_dealer(game_state, &self.id) && crib_pending(game_state) {
                    GameAction::CountCrib {
                        player_id: self.id.clone(),
                    }
                } else {
                    GameAction::CountHand {
                        player_id: self.id.clone(),
                    }
                },
            ),
            _ => None,
        }
    }

    fn choose_cards_to_discard(&self, hand: &[Card], is_dealer: bool) -> Vec<Card> {
        if hand.len() <= 4 {
            return vec![];
        }

        let mut best_discard: Vec<Card> = hand[..2].to_vec();
        let mut best_net_score: f64 = f64::MIN;

        for keep in combinations(hand, 4) {
            let keep_set: std::collections::HashSet<Card> = keep.iter().copied().collect();
            let discard: Vec<Card> = hand
                .iter()
                .filter(|c| !keep_set.contains(c))
                .copied()
                .collect();
            let hand_avg = average_hand_score(&keep);
            let crib_avg = average_crib_score(&discard);

            let net_score = if is_dealer {
                hand_avg + crib_avg
            } else {
                hand_avg - crib_avg
            };

            if net_score > best_net_score {
                best_net_score = net_score;
                best_discard = discard;
            }
        }

        best_discard
    }

    fn choose_card_to_play(
        &self,
        hand: &[Card],
        played_cards: &[Card],
        current_count: i32,
    ) -> Option<Card> {
        let playable: Vec<Card> = hand
            .iter()
            .filter(|c| current_count + c.pegging_value() as i32 <= 31)
            .copied()
            .collect();

        if playable.is_empty() {
            return None;
        }

        let mut best: Option<Card> = None;
        let mut best_score = f64::MIN;

        for &card in &playable {
            let score = evaluate_pegging_play(card, &playable, played_cards, current_count);
            if score > best_score {
                best_score = score;
                best = Some(card);
            }
        }

        best
    }
}

fn evaluate_pegging_play(
    card: Card,
    all_playable: &[Card],
    played_cards: &[Card],
    current_count: i32,
) -> f64 {
    let new_count = current_count + card.pegging_value() as i32;
    let mut score = 0.0;

    // Immediate scoring
    if new_count == 31 {
        score += 20.0;
    }
    if new_count == 15 {
        score += 20.0;
    }

    // Pair scoring
    if let Some(last) = played_cards.last() {
        if last.rank == card.rank {
            let we_have_another = all_playable.iter().filter(|c| c.rank == card.rank).count() >= 2;
            if we_have_another {
                score += 15.0; // Pair now, trips next turn
            } else {
                score += 10.0; // Just the pair
            }
        }
    }

    // Run scoring
    if played_cards.len() >= 2 {
        let run_length = check_run_length(played_cards, card);
        if run_length >= 3 {
            score += run_length as f64 * 4.0;
        }
    }

    // Trap play: pair in hand, bait for trips
    let mut rank_counts: HashMap<Rank, usize> = HashMap::new();
    for c in all_playable {
        *rank_counts.entry(c.rank).or_insert(0) += 1;
    }
    if rank_counts.get(&card.rank).copied().unwrap_or(0) >= 2 && played_cards.is_empty() {
        score += 3.0;
    }

    // Defensive penalties
    if new_count == 5 {
        score -= 8.0;
    }
    if new_count == 21 {
        score -= 6.0;
    }
    if new_count == 16 {
        score -= 3.0;
    }

    // Prefer leaving count at hard-to-score values
    if (22..=27).contains(&new_count) {
        score += 1.0;
    }

    // Slight preference for higher cards early
    if current_count < 10 {
        score += card.pegging_value() as f64 * 0.1;
    }

    score
}

fn check_run_length(played_cards: &[Card], new_card: Card) -> usize {
    let mut cards: Vec<Card> = played_cards.to_vec();
    cards.push(new_card);
    let max_check = cards.len().min(7);
    for length in (3..=max_check).rev() {
        let recent = &cards[cards.len() - length..];
        let mut ranks: Vec<u8> = recent.iter().map(|c| c.rank.ordinal()).collect();
        ranks.sort();
        if ranks.windows(2).all(|w| w[1] == w[0] + 1) {
            return length;
        }
    }
    0
}

fn average_hand_score(keep: &[Card]) -> f64 {
    let mut total_score: i32 = 0;
    let mut cut_count: i32 = 0;

    for &rank in &Rank::ALL {
        for &suit in &Suit::ALL {
            let cut_card = Card::new(rank, suit);
            if keep.contains(&cut_card) {
                continue;
            }
            total_score += scoring::calculate_hand_score(keep, cut_card, false);
            cut_count += 1;
        }
    }

    if cut_count > 0 {
        total_score as f64 / cut_count as f64
    } else {
        0.0
    }
}

/// Simplified crib estimation: score the 2 discard cards + each possible cut card
/// for 15s and pairs (ignoring unknown opponent discards).
fn average_crib_score(discard: &[Card]) -> f64 {
    if discard.len() != 2 {
        return 0.0;
    }

    let mut total_score: i32 = 0;
    let mut count: i32 = 0;

    for &rank in &Rank::ALL {
        for &suit in &Suit::ALL {
            let cut_card = Card::new(rank, suit);
            if discard.contains(&cut_card) {
                continue;
            }

            let all_cards = [discard[0], discard[1], cut_card];
            let mut score = 0;

            // 15s from our discards + cut
            let values: Vec<u8> = all_cards.iter().map(|c| c.pegging_value()).collect();
            let n = all_cards.len();
            for i in 1..(1u32 << n) {
                let mut sum: u32 = 0;
                for (j, &val) in values.iter().enumerate() {
                    if (i >> j) & 1 == 1 {
                        sum += val as u32;
                    }
                }
                if sum == 15 {
                    score += 2;
                }
            }

            // Pair between discards
            if discard[0].rank == discard[1].rank {
                score += 2;
            }

            total_score += score;
            count += 1;
        }
    }

    if count > 0 {
        total_score as f64 / count as f64
    } else {
        0.0
    }
}
