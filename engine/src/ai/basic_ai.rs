use crate::card::Card;
use crate::game_action::GameAction;
use crate::game_stage::GameStage;
use crate::game_state::GameState;

use super::ai_player::{is_dealer, AIPlayer};
use super::ai_utils::{self, combinations};

pub struct BasicAI {
    id: String,
}

impl BasicAI {
    pub fn new(id: impl Into<String>) -> Self {
        BasicAI { id: id.into() }
    }
}

impl AIPlayer for BasicAI {
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
            GameStage::Counting => Some(GameAction::CountHand {
                player_id: self.id.clone(),
            }),
            _ => None,
        }
    }

    fn choose_cards_to_discard(&self, hand: &[Card], is_dealer: bool) -> Vec<Card> {
        if hand.len() < 2 {
            return hand.to_vec();
        }
        if is_dealer {
            choose_dealer_discards(hand)
        } else {
            choose_non_dealer_discards(hand)
        }
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

        // Try 31
        if let Some(&c) = playable
            .iter()
            .find(|c| current_count + c.pegging_value() as i32 == 31)
        {
            return Some(c);
        }

        // Try 15
        if let Some(&c) = playable
            .iter()
            .find(|c| current_count + c.pegging_value() as i32 == 15)
        {
            return Some(c);
        }

        // Try pair
        if let Some(last) = played_cards.last() {
            if let Some(&c) = playable.iter().find(|c| c.rank == last.rank) {
                return Some(c);
            }
        }

        // Try run continuation
        if played_cards.len() >= 2 {
            if let Some(c) = ai_utils::find_run_continuation(&playable, played_cards) {
                return Some(c);
            }
        }

        // Avoid dangerous counts
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

        // Play lowest
        playable.iter().min_by_key(|c| c.pegging_value()).copied()
    }
}

fn choose_dealer_discards(hand: &[Card]) -> Vec<Card> {
    let mut sorted = hand.to_vec();
    sorted.sort_by_key(|c| c.pegging_value());

    // Keep pairs - discard non-pair cards
    let mut rank_groups: std::collections::HashMap<crate::card::Rank, Vec<Card>> =
        std::collections::HashMap::new();
    for &card in hand {
        rank_groups.entry(card.rank).or_default().push(card);
    }
    let has_pair = rank_groups.values().any(|v| v.len() >= 2);
    if has_pair {
        let pair_cards: std::collections::HashSet<Card> = rank_groups
            .values()
            .filter(|v| v.len() >= 2)
            .flatten()
            .copied()
            .collect();
        let non_pair: Vec<Card> = hand.iter().filter(|c| !pair_cards.contains(c)).copied().collect();
        if non_pair.len() >= 2 {
            return non_pair[..2].to_vec();
        }
    }

    // Keep 15-combos
    let fifteen_combos = find_fifteen_combinations(hand);
    if !fifteen_combos.is_empty() {
        let keep_set: std::collections::HashSet<Card> =
            fifteen_combos[0].iter().copied().collect();
        let discards: Vec<Card> = hand.iter().filter(|c| !keep_set.contains(c)).copied().collect();
        if discards.len() >= 2 {
            return discards[..2].to_vec();
        }
    }

    // Default: discard two lowest
    sorted[..2].to_vec()
}

fn choose_non_dealer_discards(hand: &[Card]) -> Vec<Card> {
    let mut sorted = hand.to_vec();
    sorted.sort_by_key(|c| std::cmp::Reverse(c.pegging_value()));

    let mut candidates: Vec<Card> = Vec::new();
    for &card in &sorted {
        if candidates.len() >= 2 {
            break;
        }
        let would_make_pair = candidates.iter().any(|c| c.rank == card.rank);
        let would_make_fifteen = candidates
            .iter()
            .any(|c| c.pegging_value() + card.pegging_value() == 15);
        if !would_make_pair && !would_make_fifteen {
            candidates.push(card);
        }
    }

    if candidates.len() >= 2 {
        candidates[..2].to_vec()
    } else {
        sorted[..2].to_vec()
    }
}

fn find_fifteen_combinations(cards: &[Card]) -> Vec<Vec<Card>> {
    let mut result = Vec::new();
    for size in 2..=cards.len().min(5) {
        for combo in combinations(cards, size) {
            let sum: u8 = combo.iter().map(|c| c.pegging_value()).sum();
            if sum == 15 {
                result.push(combo);
            }
        }
    }
    result
}
