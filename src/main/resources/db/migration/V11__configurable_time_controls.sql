-- Configurable time controls: games and lobbies carry a named preset, and games
-- freeze the resolved per-turn limit so config changes never alter a live game.

ALTER TABLE games ADD COLUMN time_control VARCHAR(20) NOT NULL DEFAULT 'RAPID';
ALTER TABLE games ADD COLUMN turn_time_limit_ms BIGINT NOT NULL DEFAULT 30000;

ALTER TABLE lobbies ADD COLUMN time_control VARCHAR(20) NOT NULL DEFAULT 'RAPID';

-- AI games have always been untimed; make that explicit rather than implied by is_ai_game.
UPDATE games SET time_control = 'UNLIMITED', turn_time_limit_ms = 0 WHERE is_ai_game = TRUE;

-- Timeout sweep reads these on every tick.
CREATE INDEX idx_games_active_timed ON games (winner_id, time_control, turn_started_at);
