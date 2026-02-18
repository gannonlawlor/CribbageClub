use serde::{Deserialize, Serialize};

use crate::card::Card;

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum GameAction {
    #[serde(rename_all = "camelCase")]
    DiscardToCrib {
        player_id: String,
        card: Card,
    },
    #[serde(rename_all = "camelCase")]
    PlayCard {
        player_id: String,
        card: Card,
    },
    #[serde(rename_all = "camelCase")]
    CutDeck {
        player_id: String,
    },
    #[serde(rename_all = "camelCase")]
    Go {
        player_id: String,
    },
    #[serde(rename_all = "camelCase")]
    CountHand {
        player_id: String,
    },
}

impl GameAction {
    pub fn player_id(&self) -> &str {
        match self {
            GameAction::DiscardToCrib { player_id, .. } => player_id,
            GameAction::PlayCard { player_id, .. } => player_id,
            GameAction::CutDeck { player_id } => player_id,
            GameAction::Go { player_id } => player_id,
            GameAction::CountHand { player_id } => player_id,
        }
    }
}
