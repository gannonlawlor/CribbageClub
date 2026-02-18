use serde::{Deserialize, Serialize};

#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum GameStage {
    Dealing,
    DiscardingToCrib,
    Cutting,
    Pegging,
    Counting,
    GameOver,
}
