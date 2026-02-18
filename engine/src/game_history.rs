use std::collections::HashMap;

use serde::{Deserialize, Serialize};

use crate::card::Card;

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ScoreBreakdown {
    pub fifteens: i32,
    pub pairs: i32,
    pub runs: i32,
    pub flushes: i32,
    pub nobs: i32,
    pub total_score: i32,
}

impl ScoreBreakdown {
    pub fn total(&self) -> i32 {
        self.fifteens + self.pairs + self.runs + self.flushes + self.nobs
    }
}

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum GameHistoryEvent {
    #[serde(rename_all = "camelCase")]
    RoundStarted {
        round_number: u32,
    },
    #[serde(rename_all = "camelCase")]
    CardsDealt {
        dealt_hands: HashMap<String, Vec<Card>>,
    },
    #[serde(rename_all = "camelCase")]
    DeckCut {
        cut_card: Card,
        cutting_player_id: String,
        dealer_scored_nobs: bool,
    },
    #[serde(rename_all = "camelCase")]
    CardPlayed {
        player_id: String,
        card: Card,
        new_count: i32,
        points_scored: i32,
        scoring_reason: Option<String>,
    },
    #[serde(rename_all = "camelCase")]
    GoAnnounced {
        player_id: String,
        points_scored: i32,
    },
    PeggingEnded,
    #[serde(rename_all = "camelCase")]
    HandCounted {
        player_id: String,
        hand: Vec<Card>,
        total_points: i32,
        score_breakdown: ScoreBreakdown,
    },
    #[serde(rename_all = "camelCase")]
    CribCounted {
        dealer_player_id: String,
        total_points: i32,
        score_breakdown: ScoreBreakdown,
        crib_cards: Vec<Card>,
    },
    #[serde(rename_all = "camelCase")]
    GameEnded {
        winner_player_id: String,
        final_score: i32,
    },
}
