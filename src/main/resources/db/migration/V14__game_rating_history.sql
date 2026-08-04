-- Per-game rating outcomes, so history can show each player's rating change
-- and the opponent's rating without replaying the whole Glicko-2 sequence.
-- Null on unrated games (engine opponents, guests) and games predating this.

ALTER TABLE games ADD COLUMN player1_rating_after DOUBLE PRECISION;
ALTER TABLE games ADD COLUMN player1_rating_delta DOUBLE PRECISION;
ALTER TABLE games ADD COLUMN player2_rating_after DOUBLE PRECISION;
ALTER TABLE games ADD COLUMN player2_rating_delta DOUBLE PRECISION;
