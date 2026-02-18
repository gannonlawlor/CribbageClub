ALTER TABLE games ADD COLUMN original_local_game_id VARCHAR(255);
CREATE INDEX idx_games_original_local_game_id ON games(original_local_game_id);
