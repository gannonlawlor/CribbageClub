use rand::seq::SliceRandom;
use rand::rngs::StdRng;
use rand::SeedableRng;
use serde::{Deserialize, Serialize};

use crate::card::{Card, Rank, Suit};
use crate::error::EngineError;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Deck {
    cards: Vec<Card>,
}

impl Deck {
    /// Create a new shuffled 52-card deck using a random seed.
    pub fn new() -> Self {
        let mut cards = Self::full_deck();
        let mut rng = StdRng::from_entropy();
        cards.shuffle(&mut rng);
        Deck { cards }
    }

    /// Create a deterministic deck with a specific seed (for testing).
    pub fn with_seed(seed: u64) -> Self {
        let mut cards = Self::full_deck();
        let mut rng = StdRng::seed_from_u64(seed);
        cards.shuffle(&mut rng);
        Deck { cards }
    }

    /// Restore a deck from a specific list of cards (for game restoration).
    pub fn from_cards(cards: Vec<Card>) -> Self {
        Deck { cards }
    }


    /// Draw n cards from the top of the deck.
    pub fn draw_n(&mut self, n: usize) -> Result<Vec<Card>, EngineError> {
        if self.cards.len() < n {
            return Err(EngineError::EmptyDeck);
        }
        let drawn: Vec<Card> = self.cards.drain(..n).collect();
        Ok(drawn)
    }

    /// Cut the deck: remove and return the middle card.
    pub fn cut(&mut self) -> Result<Card, EngineError> {
        if self.cards.is_empty() {
            return Err(EngineError::EmptyDeck);
        }
        let mid = self.cards.len() / 2;
        Ok(self.cards.remove(mid))
    }

    /// Return a copy of remaining cards.
    pub fn remaining_cards(&self) -> &[Card] {
        &self.cards
    }

    /// Shuffle the deck in place.
    pub fn shuffle(&mut self) {
        let mut rng = StdRng::from_entropy();
        self.cards.shuffle(&mut rng);
    }

    /// Reset to a full shuffled 52-card deck.
    pub fn reset(&mut self) {
        self.cards = Self::full_deck();
        self.shuffle();
    }

    fn full_deck() -> Vec<Card> {
        let mut deck = Vec::with_capacity(52);
        for &suit in &Suit::ALL {
            for &rank in &Rank::ALL {
                deck.push(Card::new(rank, suit));
            }
        }
        deck
    }
}

impl Default for Deck {
    fn default() -> Self {
        Self::new()
    }
}
