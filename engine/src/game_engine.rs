use std::collections::HashMap;

use crate::card::{Card, Rank};
use crate::deck::Deck;
use crate::error::EngineError;
use crate::game_action::GameAction;
use crate::game_history::GameHistoryEvent;
use crate::game_stage::GameStage;
use crate::game_state::GameState;
use crate::player::Player;
use crate::score_breakdown;
use crate::scoring;

const CARDS_PER_HAND: usize = 6;
const KEEP_CARDS: usize = 4;
const WIN_SCORE: i32 = 121;

pub struct GameEngine {
    #[allow(dead_code)]
    id: String,
    deck: Deck,
    history: Vec<GameHistoryEvent>,
    state: GameState,
    current_round: u32,
    dev_next_hands: Option<HashMap<String, Vec<Card>>>,
}

impl GameEngine {
    /// Create a new game with the given players and optional deck.
    pub fn new(
        id: impl Into<String>,
        players: Vec<Player>,
        deck: Option<Deck>,
    ) -> Result<Self, EngineError> {
        if players.len() != 2 {
            return Err(EngineError::InvalidPlayerCount {
                count: players.len(),
            });
        }

        let id = id.into();
        let mut engine = GameEngine {
            id: id.clone(),
            deck: deck.unwrap_or_default(),
            history: Vec::new(),
            state: GameState::new(&id, players),
            current_round: 1,
            dev_next_hands: None,
        };

        engine.deal_cards()?;
        Ok(engine)
    }

    /// Restore a game from a persisted GameState.
    pub fn restore(state: GameState) -> Result<Self, EngineError> {
        let deck = Deck::from_cards(state.remaining_deck.clone());
        let history: Vec<GameHistoryEvent> = state.history.clone();
        let current_round = history
            .iter()
            .filter(|e| matches!(e, GameHistoryEvent::RoundStarted { .. }))
            .count()
            .max(1) as u32;

        let restored_state = GameState {
            history: Vec::new(),
            remaining_deck: Vec::new(),
            ..state
        };

        Ok(GameEngine {
            id: restored_state.game_id.clone(),
            deck,
            history,
            state: restored_state,
            current_round,
            dev_next_hands: None,
        })
    }

    /// Get the current game state (includes history and remaining deck).
    pub fn current_state(&self) -> GameState {
        let mut state = self.state.clone();
        state.history = self.history.clone();
        state.remaining_deck = self.deck.remaining_cards().to_vec();
        state
    }

    /// Apply a game action and return the new state.
    pub fn apply_action(&mut self, action: GameAction) -> Result<GameState, EngineError> {
        match action {
            GameAction::DiscardToCrib { player_id, card } => {
                self.discard_to_crib(&player_id, card)?;
            }
            GameAction::CutDeck { player_id } => {
                self.cut_deck(&player_id)?;
            }
            GameAction::PlayCard { player_id, card } => {
                self.play_card(&player_id, card)?;
            }
            GameAction::Go { player_id } => {
                self.announce_go(&player_id)?;
            }
            GameAction::CountHand { player_id } => {
                self.count_hand(&player_id)?;
            }
            GameAction::CountCrib { player_id } => {
                self.count_crib_action(&player_id)?;
            }
        }
        Ok(self.current_state())
    }

    /// DEV ONLY: Override a player's score.
    pub fn dev_set_score(&mut self, player_id: &str, score: i32) -> Result<(), EngineError> {
        let idx = self.player_index(player_id)?;
        self.state.players[idx].score = score;
        Ok(())
    }

    /// DEV ONLY: Store hand overrides for the next deal.
    pub fn dev_set_next_hands(&mut self, hands: HashMap<String, Vec<Card>>) {
        self.dev_next_hands = Some(hands);
    }

    // ── Deal ──────────────────────────────────────────────────────────────

    fn deal_cards(&mut self) -> Result<(), EngineError> {
        self.add_event(GameHistoryEvent::RoundStarted {
            round_number: self.current_round,
        });

        let dev_hands = self.dev_next_hands.take();

        self.state.stage = GameStage::Dealing;
        for i in 0..self.state.players.len() {
            let hand = if let Some(ref dh) = dev_hands {
                if let Some(h) = dh.get(&self.state.players[i].id) {
                    h.clone()
                } else {
                    self.deck.draw_n(CARDS_PER_HAND)?
                }
            } else {
                self.deck.draw_n(CARDS_PER_HAND)?
            };
            self.state.players[i].hand = hand;
        }
        self.state.current_player_id = Some(self.state.players[0].id.clone());

        let dealt_hands: HashMap<String, Vec<Card>> = self
            .state
            .players
            .iter()
            .map(|p| (p.id.clone(), p.hand.clone()))
            .collect();
        self.add_event(GameHistoryEvent::CardsDealt { dealt_hands });

        self.state.stage = GameStage::DiscardingToCrib;
        Ok(())
    }

    // ── Discard ───────────────────────────────────────────────────────────

    fn discard_to_crib(&mut self, player_id: &str, card: Card) -> Result<(), EngineError> {
        if self.state.stage != GameStage::DiscardingToCrib {
            return Err(EngineError::WrongStage {
                expected: "DiscardingToCrib".into(),
                actual: format!("{:?}", self.state.stage),
            });
        }

        let player_index = self.player_index(player_id)?;
        let player = &self.state.players[player_index];

        let card_pos = player.hand.iter().position(|c| *c == card).ok_or_else(|| {
            EngineError::CardNotInHand {
                card: format!("{}", card),
            }
        })?;

        self.state.players[player_index].hand.remove(card_pos);
        self.state.crib.push(card);

        // If this player has finished discarding, switch to the other player
        if self.state.players[player_index].hand.len() == KEEP_CARDS {
            let other_index = (player_index + 1) % self.state.players.len();
            if self.state.players[other_index].hand.len() > KEEP_CARDS {
                self.state.current_player_id = Some(self.state.players[other_index].id.clone());
            }
        }

        if self.state.crib.len() == self.state.players.len() * 2 {
            self.transition_to_cutting();
        }

        Ok(())
    }

    fn transition_to_cutting(&mut self) {
        let non_dealer_index = self.non_dealer_index();
        self.state.stage = GameStage::Cutting;
        self.state.current_player_id = Some(self.state.players[non_dealer_index].id.clone());
    }

    // ── Cut ───────────────────────────────────────────────────────────────

    fn cut_deck(&mut self, player_id: &str) -> Result<(), EngineError> {
        if self.state.stage != GameStage::Cutting {
            return Err(EngineError::WrongStage {
                expected: "Cutting".into(),
                actual: format!("{:?}", self.state.stage),
            });
        }
        self.require_current_player(player_id)?;

        let cut_card = self.deck.cut()?;
        let hands_for_counting: HashMap<String, Vec<Card>> = self
            .state
            .players
            .iter()
            .map(|p| (p.id.clone(), p.hand.clone()))
            .collect();

        let dealer_scored_nobs = cut_card.rank == Rank::Jack;

        self.state.cut_card = Some(cut_card);
        self.state.stage = GameStage::Pegging;
        self.state.current_player_id = Some(player_id.to_string());
        self.state.hands_for_counting = hands_for_counting;

        if dealer_scored_nobs {
            let dealer_idx = self.dealer_index();
            self.state.players[dealer_idx].score += 2;
        }

        self.add_event(GameHistoryEvent::DeckCut {
            cut_card,
            cutting_player_id: player_id.to_string(),
            dealer_scored_nobs,
        });

        if dealer_scored_nobs {
            let dealer_id = self.state.players[self.dealer_index()].id.clone();
            self.check_win(&dealer_id);
        }

        Ok(())
    }

    // ── Pegging ───────────────────────────────────────────────────────────

    fn play_card(&mut self, player_id: &str, card: Card) -> Result<(), EngineError> {
        if self.state.stage != GameStage::Pegging {
            return Err(EngineError::WrongStage {
                expected: "Pegging".into(),
                actual: format!("{:?}", self.state.stage),
            });
        }
        self.require_current_player(player_id)?;

        let player_index = self.player_index(player_id)?;
        let player = &self.state.players[player_index];

        let card_pos = player.hand.iter().position(|c| *c == card).ok_or_else(|| {
            EngineError::CardNotInHand {
                card: format!("{}", card),
            }
        })?;

        let new_count = self.state.pegging_count + card.pegging_value() as i32;
        if new_count > 31 {
            return Err(EngineError::ExceedsThirtyOne {
                card_value: card.pegging_value(),
                current_count: self.state.pegging_count,
            });
        }

        // Remove card from hand and add to played cards
        self.state.players[player_index].hand.remove(card_pos);
        self.state.played_cards.push(card);

        // Calculate pegging score
        let score_earned = calculate_pegging_score(&self.state.played_cards, new_count);
        self.state.players[player_index].score += score_earned;

        // Build scoring reason
        let scoring_reason =
            build_scoring_reason(&self.state.played_cards, new_count, score_earned);

        // Move to next player
        let next_player_index = (player_index + 1) % self.state.players.len();
        self.state.pegging_count = new_count;
        self.state.current_player_id = Some(self.state.players[next_player_index].id.clone());
        self.state.last_play_was_go = false;

        self.add_event(GameHistoryEvent::CardPlayed {
            player_id: player_id.to_string(),
            card,
            new_count,
            points_scored: score_earned,
            scoring_reason,
        });

        if self.check_win(player_id) {
            return Ok(());
        }

        // Check if pegging round is over (all hands empty)
        if self.state.players.iter().all(|p| p.hand.is_empty()) {
            self.add_event(GameHistoryEvent::PeggingEnded);
            self.transition_to_hand_counting();
        }

        Ok(())
    }

    fn announce_go(&mut self, player_id: &str) -> Result<(), EngineError> {
        if self.state.stage != GameStage::Pegging {
            return Err(EngineError::WrongStage {
                expected: "Pegging".into(),
                actual: format!("{:?}", self.state.stage),
            });
        }
        self.require_current_player(player_id)?;

        let player_index = self.player_index(player_id)?;
        let next_player_index = (player_index + 1) % self.state.players.len();
        let next_player_id = self.state.players[next_player_index].id.clone();

        if self.state.last_play_was_go {
            // Second consecutive Go: award 1 point and reset
            self.state.players[player_index].score += 1;
            self.state.pegging_count = 0;
            self.state.played_cards.clear();
            self.state.current_player_id = Some(next_player_id);
            self.state.last_play_was_go = false;

            self.add_event(GameHistoryEvent::GoAnnounced {
                player_id: player_id.to_string(),
                points_scored: 1,
            });

            if self.check_win(player_id) {
                return Ok(());
            }

            if self.state.players.iter().all(|p| p.hand.is_empty()) {
                self.add_event(GameHistoryEvent::PeggingEnded);
                self.transition_to_hand_counting();
            }
        } else {
            self.state.current_player_id = Some(next_player_id);
            self.state.last_play_was_go = true;

            self.add_event(GameHistoryEvent::GoAnnounced {
                player_id: player_id.to_string(),
                points_scored: 0,
            });
        }

        Ok(())
    }

    fn transition_to_hand_counting(&mut self) {
        let non_dealer_index = self.non_dealer_index();
        self.state.stage = GameStage::Counting;
        self.state.current_player_id = Some(self.state.players[non_dealer_index].id.clone());
        self.state.pegging_count = 0;
        self.state.played_cards.clear();
    }

    // ── Counting ──────────────────────────────────────────────────────────

    fn count_hand(&mut self, player_id: &str) -> Result<(), EngineError> {
        if self.state.stage != GameStage::Counting {
            return Err(EngineError::WrongStage {
                expected: "Counting".into(),
                actual: format!("{:?}", self.state.stage),
            });
        }
        self.require_current_player(player_id)?;

        // The dealer's crib is its own action; once their hand is counted the
        // only counting left for them is CountCrib.
        if self.crib_pending() {
            return Err(EngineError::WrongStage {
                expected: "CountCrib".into(),
                actual: "CountHand".into(),
            });
        }

        let player_index = self.player_index(player_id)?;
        let hand_to_count = self
            .state
            .hands_for_counting
            .get(player_id)
            .cloned()
            .unwrap_or_default();

        if hand_to_count.is_empty() {
            return Err(EngineError::NoHandToCount);
        }

        let cut_card = self.state.cut_card.unwrap();
        let hand_score = scoring::calculate_hand_score(&hand_to_count, cut_card, false);
        let breakdown = score_breakdown::calculate(&hand_to_count, cut_card, false);

        self.state.players[player_index].score += hand_score;

        self.add_event(GameHistoryEvent::HandCounted {
            player_id: player_id.to_string(),
            hand: hand_to_count,
            total_points: hand_score,
            score_breakdown: breakdown,
        });

        // Check for win after hand counting
        if self.state.players[player_index].score >= WIN_SCORE {
            self.state.stage = GameStage::GameOver;
            self.add_event(GameHistoryEvent::GameEnded {
                winner_player_id: player_id.to_string(),
                final_score: self.state.players[player_index].score,
            });
            return Ok(());
        }

        if player_index == self.dealer_index() {
            // Dealer's hand is counted; the crib is a separate action and it
            // stays the dealer's turn to take it.
        } else {
            // Non-dealer counted, now dealer counts
            let dealer_idx = self.dealer_index();
            self.state.current_player_id = Some(self.state.players[dealer_idx].id.clone());
        }

        Ok(())
    }

    /// True once the dealer has counted their hand this round but the crib
    /// hasn't been counted yet — the window where CountCrib is the valid move.
    fn crib_pending(&self) -> bool {
        let dealer_id = &self.state.players[self.dealer_index()].id;
        for event in self.history.iter().rev() {
            match event {
                GameHistoryEvent::RoundStarted { .. } => return false,
                GameHistoryEvent::CribCounted { .. } => return false,
                GameHistoryEvent::HandCounted { player_id, .. } if player_id == dealer_id => {
                    return true
                }
                _ => {}
            }
        }
        false
    }

    /// Score the crib. Only the dealer, once their hand is counted, may take
    /// it — the non-dealer never has a crib to count.
    fn count_crib_action(&mut self, player_id: &str) -> Result<(), EngineError> {
        if self.state.stage != GameStage::Counting {
            return Err(EngineError::WrongStage {
                expected: "Counting".into(),
                actual: format!("{:?}", self.state.stage),
            });
        }
        self.require_current_player(player_id)?;
        if self.player_index(player_id)? != self.dealer_index() || !self.crib_pending() {
            return Err(EngineError::WrongStage {
                expected: "CountHand".into(),
                actual: "CountCrib".into(),
            });
        }
        self.count_crib()
    }

    fn count_crib(&mut self) -> Result<(), EngineError> {
        let dealer_index = self.dealer_index();
        let cut_card = self.state.cut_card.unwrap();
        let crib = self.state.crib.clone();
        let crib_score = scoring::calculate_hand_score(&crib, cut_card, true);
        let crib_breakdown = score_breakdown::calculate(&crib, cut_card, true);

        self.state.players[dealer_index].score += crib_score;
        let dealer_id = self.state.players[dealer_index].id.clone();

        self.add_event(GameHistoryEvent::CribCounted {
            dealer_player_id: dealer_id.clone(),
            total_points: crib_score,
            score_breakdown: crib_breakdown,
            crib_cards: crib,
        });

        // Check for win after crib counting
        if self.state.players[dealer_index].score >= WIN_SCORE {
            self.state.stage = GameStage::GameOver;
            self.add_event(GameHistoryEvent::GameEnded {
                winner_player_id: dealer_id,
                final_score: self.state.players[dealer_index].score,
            });
            return Ok(());
        }

        // Start new round
        self.start_new_round()?;
        Ok(())
    }

    fn start_new_round(&mut self) -> Result<(), EngineError> {
        self.deck.reset();
        self.current_round += 1;

        let new_dealer_index = (self.state.dealer_index + 1) % self.state.players.len() as i32;
        self.state.dealer_index = new_dealer_index;
        self.state.crib.clear();
        self.state.cut_card = None;
        self.state.current_player_id = Some(self.state.players[0].id.clone());
        self.state.stage = GameStage::Dealing;
        self.state.played_cards.clear();
        self.state.pegging_count = 0;
        self.state.last_play_was_go = false;
        self.state.hands_for_counting.clear();

        self.deal_cards()?;
        Ok(())
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    /// Returns true if the player has won.
    fn check_win(&mut self, player_id: &str) -> bool {
        let idx = self
            .state
            .players
            .iter()
            .position(|p| p.id == player_id)
            .unwrap();
        if self.state.players[idx].score >= WIN_SCORE {
            self.state.stage = GameStage::GameOver;
            self.add_event(GameHistoryEvent::GameEnded {
                winner_player_id: player_id.to_string(),
                final_score: self.state.players[idx].score,
            });
            true
        } else {
            false
        }
    }

    fn player_index(&self, player_id: &str) -> Result<usize, EngineError> {
        self.state
            .players
            .iter()
            .position(|p| p.id == player_id)
            .ok_or_else(|| EngineError::PlayerNotFound {
                player_id: player_id.to_string(),
            })
    }

    fn require_current_player(&self, player_id: &str) -> Result<(), EngineError> {
        if self.state.current_player_id.as_deref() != Some(player_id) {
            return Err(EngineError::NotPlayersTurn {
                expected: self.state.current_player_id.clone().unwrap_or_default(),
                actual: player_id.to_string(),
            });
        }
        Ok(())
    }

    fn dealer_index(&self) -> usize {
        self.state.dealer_index as usize
    }

    fn non_dealer_index(&self) -> usize {
        ((self.state.dealer_index + 1) % self.state.players.len() as i32) as usize
    }

    fn add_event(&mut self, event: GameHistoryEvent) {
        self.history.push(event);
    }
}

// ── Free functions for pegging scoring ─────────────────────────────────

fn calculate_pegging_score(played_cards: &[Card], count: i32) -> i32 {
    let mut score = 0;

    // Check for 15 or 31
    if count == 15 || count == 31 {
        score += 2;
    }

    // Check for pairs, trips, quads
    if let Some(last_card) = played_cards.last() {
        let same_face_count = played_cards
            .iter()
            .rev()
            .take_while(|c| c.rank == last_card.rank)
            .count();
        match same_face_count {
            2 => score += 2,  // Pair
            3 => score += 6,  // Trips
            4 => score += 12, // Quads
            _ => {}
        }
    }

    // Check for runs (longest first)
    for run_length in (3..=7).rev() {
        if played_cards.len() >= run_length
            && is_run(&played_cards[played_cards.len() - run_length..])
        {
            score += run_length as i32;
            break;
        }
    }

    score
}

fn is_run(cards: &[Card]) -> bool {
    if cards.len() < 3 {
        return false;
    }
    let mut ranks: Vec<u8> = cards.iter().map(|c| c.rank.ordinal()).collect();
    ranks.sort();
    ranks.windows(2).all(|w| w[1] == w[0] + 1)
}

fn build_scoring_reason(
    played_cards: &[Card],
    new_count: i32,
    score_earned: i32,
) -> Option<String> {
    if new_count == 31 {
        return Some("Thirty-one".to_string());
    }
    if new_count == 15 {
        return Some("Fifteen".to_string());
    }
    if score_earned > 0 && played_cards.len() >= 2 {
        if let Some(last_card) = played_cards.last() {
            let same_face_count = played_cards
                .iter()
                .rev()
                .take_while(|c| c.rank == last_card.rank)
                .count();
            match same_face_count {
                2 => return Some("Pair".to_string()),
                3 => return Some("Three of a kind".to_string()),
                4 => return Some("Four of a kind".to_string()),
                _ => {
                    // Check for run
                    for run_length in (3..=7).rev() {
                        if played_cards.len() >= run_length
                            && is_run(&played_cards[played_cards.len() - run_length..])
                        {
                            return Some(format!("Run of {}", run_length));
                        }
                    }
                }
            }
        }
    }
    None
}
