use std::fmt;

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum EngineError {
    WrongStage {
        expected: String,
        actual: String,
    },
    NotPlayersTurn {
        expected: String,
        actual: String,
    },
    PlayerNotFound {
        player_id: String,
    },
    CardNotInHand {
        card: String,
    },
    ExceedsThirtyOne {
        card_value: u8,
        current_count: i32,
    },
    InvalidPlayerCount {
        count: usize,
    },
    EmptyDeck,
    NoHandToCount,
}

impl fmt::Display for EngineError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            EngineError::WrongStage { expected, actual } => {
                write!(f, "Wrong stage: expected {expected}, got {actual}")
            }
            EngineError::NotPlayersTurn { expected, actual } => {
                write!(f, "Not player's turn: expected {expected}, got {actual}")
            }
            EngineError::PlayerNotFound { player_id } => {
                write!(f, "Player not found: {player_id}")
            }
            EngineError::CardNotInHand { card } => {
                write!(f, "Card not in hand: {card}")
            }
            EngineError::ExceedsThirtyOne {
                card_value,
                current_count,
            } => {
                write!(
                    f,
                    "Card value {card_value} would exceed 31 (current count: {current_count})"
                )
            }
            EngineError::InvalidPlayerCount { count } => {
                write!(f, "Invalid player count: {count} (expected 2)")
            }
            EngineError::EmptyDeck => write!(f, "Deck is empty"),
            EngineError::NoHandToCount => write!(f, "No hand available to count"),
        }
    }
}

impl std::error::Error for EngineError {}
