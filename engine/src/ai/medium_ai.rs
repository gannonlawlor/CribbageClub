use crate::card::{Card, Rank, Suit};
use crate::game_action::GameAction;
use crate::game_stage::GameStage;
use crate::game_state::GameState;
use crate::scoring;

use super::ai_player::{crib_pending, is_dealer, AIPlayer};
use super::ai_utils::{self, combinations};

pub struct MediumAI {
    id: String,
}

impl MediumAI {
    pub fn new(id: impl Into<String>) -> Self {
        MediumAI { id: id.into() }
    }
}

impl AIPlayer for MediumAI {
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

    fn choose_cards_to_discard(&self, hand: &[Card], _is_dealer: bool) -> Vec<Card> {
        if hand.len() <= 4 {
            return vec![];
        }

        let mut best_discard: Vec<Card> = hand[..2].to_vec();
        let mut best_score: f64 = -1.0;

        for keep in combinations(hand, 4) {
            let avg = average_hand_score(&keep);
            if avg > best_score {
                best_score = avg;
                let keep_set: std::collections::HashSet<Card> = keep.into_iter().collect();
                best_discard = hand
                    .iter()
                    .filter(|c| !keep_set.contains(c))
                    .copied()
                    .collect();
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

        // Priority 1: Make 31
        if let Some(&c) = playable
            .iter()
            .find(|c| current_count + c.pegging_value() as i32 == 31)
        {
            return Some(c);
        }

        // Priority 2: Make 15
        if let Some(&c) = playable
            .iter()
            .find(|c| current_count + c.pegging_value() as i32 == 15)
        {
            return Some(c);
        }

        // Priority 3: Pair (with trips awareness)
        if let Some(last) = played_cards.last() {
            if let Some(&pair_card) = playable.iter().find(|c| c.rank == last.rank) {
                let we_have_trips = playable.iter().filter(|c| c.rank == last.rank).count() >= 2;
                let last_played_count = played_cards.iter().filter(|c| c.rank == last.rank).count();
                if we_have_trips || last_played_count == 1 {
                    return Some(pair_card);
                }
            }
        }

        // Priority 4: Run continuation
        if played_cards.len() >= 2 {
            if let Some(c) = ai_utils::find_run_continuation(&playable, played_cards) {
                return Some(c);
            }
        }

        // Priority 5: Safe play
        let safe: Vec<Card> = playable
            .iter()
            .filter(|c| {
                let nc = current_count + c.pegging_value() as i32;
                nc != 5 && nc != 16 && nc != 21
            })
            .copied()
            .collect();

        if !safe.is_empty() {
            return safe.iter().max_by_key(|c| c.pegging_value()).copied();
        }

        playable.iter().min_by_key(|c| c.pegging_value()).copied()
    }
}

/// Average hand score across all 46 possible cut cards.
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
