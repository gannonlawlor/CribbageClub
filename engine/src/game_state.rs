use std::collections::HashMap;

use serde::{Deserialize, Serialize};

use crate::card::Card;
use crate::game_history::GameHistoryEvent;
use crate::game_stage::GameStage;
use crate::player::Player;

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GameState {
    pub game_id: String,
    pub players: Vec<Player>,
    pub crib: Vec<Card>,
    pub cut_card: Option<Card>,
    pub current_player_id: Option<String>,
    pub stage: GameStage,
    pub played_cards: Vec<Card>,
    pub pegging_count: i32,
    pub last_play_was_go: bool,
    pub hands_for_counting: HashMap<String, Vec<Card>>,
    pub history: Vec<GameHistoryEvent>,
    pub dealer_index: i32,
    pub remaining_deck: Vec<Card>,
}

impl GameState {
    pub fn new(game_id: impl Into<String>, players: Vec<Player>) -> Self {
        GameState {
            game_id: game_id.into(),
            players,
            crib: Vec::new(),
            cut_card: None,
            current_player_id: None,
            stage: GameStage::Dealing,
            played_cards: Vec::new(),
            pegging_count: 0,
            last_play_was_go: false,
            hands_for_counting: HashMap::new(),
            history: Vec::new(),
            dealer_index: 0,
            remaining_deck: Vec::new(),
        }
    }
}
