use serde::{Deserialize, Serialize};

use crate::card::Card;

#[derive(Clone, Debug, PartialEq, Serialize, Deserialize)]
pub struct Player {
    pub id: String,
    pub name: String,
    pub hand: Vec<Card>,
    pub score: i32,
}

impl Player {
    pub fn new(id: impl Into<String>, name: impl Into<String>) -> Self {
        Player {
            id: id.into(),
            name: name.into(),
            hand: Vec::new(),
            score: 0,
        }
    }
}
