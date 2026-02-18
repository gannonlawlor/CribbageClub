use serde::{Deserialize, Serialize};

use crate::card::Card;
use crate::error::EngineError;
use crate::game_action::GameAction;
use crate::game_engine::GameEngine;
use crate::game_stage::GameStage;
use crate::game_state::GameState;

use super::basic_ai::BasicAI;
use super::hard_ai::HardAI;
use super::medium_ai::MediumAI;

#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum AIDifficulty {
    Basic,
    Medium,
    Hard,
}

/// Trait for AI decision-making.
pub trait AIPlayer {
    fn player_id(&self) -> &str;

    fn get_next_action(&self, game_state: &GameState) -> Option<GameAction>;

    fn choose_cards_to_discard(&self, hand: &[Card], is_dealer: bool) -> Vec<Card>;

    fn choose_card_to_play(
        &self,
        hand: &[Card],
        played_cards: &[Card],
        current_count: i32,
    ) -> Option<Card>;
}

/// Create an AI player of the given difficulty.
pub fn create_ai(
    player_id: impl Into<String>,
    difficulty: AIDifficulty,
) -> Box<dyn AIPlayer> {
    let id = player_id.into();
    match difficulty {
        AIDifficulty::Basic => Box::new(BasicAI::new(id)),
        AIDifficulty::Medium => Box::new(MediumAI::new(id)),
        AIDifficulty::Hard => Box::new(HardAI::new(id)),
    }
}

/// Convenience function for FFI: process all AI actions in a loop until
/// it's no longer the AI's turn, up to max_iterations.
pub fn process_ai_actions(
    engine: &mut GameEngine,
    ai_player_id: &str,
    difficulty: AIDifficulty,
    max_iterations: usize,
) -> Result<GameState, EngineError> {
    let ai = create_ai(ai_player_id, difficulty);
    let mut state = engine.current_state();

    for _ in 0..max_iterations {
        if state.stage == GameStage::GameOver {
            break;
        }
        if let Some(action) = ai.get_next_action(&state) {
            state = engine.apply_action(action)?;
        } else {
            break;
        }
    }

    Ok(state)
}

/// Helper: check if the AI is the dealer in the given game state.
pub(crate) fn is_dealer(game_state: &GameState, player_id: &str) -> bool {
    let idx = game_state.dealer_index as usize;
    idx < game_state.players.len() && game_state.players[idx].id == player_id
}
