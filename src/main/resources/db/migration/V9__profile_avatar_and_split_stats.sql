ALTER TABLE users ADD COLUMN avatar_index INT;

ALTER TABLE player_stats ADD COLUMN ai_games_played INT NOT NULL DEFAULT 0;
ALTER TABLE player_stats ADD COLUMN ai_games_won INT NOT NULL DEFAULT 0;
ALTER TABLE player_stats ADD COLUMN ai_games_lost INT NOT NULL DEFAULT 0;
ALTER TABLE player_stats ADD COLUMN ai_total_points_scored BIGINT NOT NULL DEFAULT 0;
ALTER TABLE player_stats ADD COLUMN ai_total_points_against BIGINT NOT NULL DEFAULT 0;
ALTER TABLE player_stats ADD COLUMN human_games_played INT NOT NULL DEFAULT 0;
ALTER TABLE player_stats ADD COLUMN human_games_won INT NOT NULL DEFAULT 0;
ALTER TABLE player_stats ADD COLUMN human_games_lost INT NOT NULL DEFAULT 0;
ALTER TABLE player_stats ADD COLUMN human_total_points_scored BIGINT NOT NULL DEFAULT 0;
ALTER TABLE player_stats ADD COLUMN human_total_points_against BIGINT NOT NULL DEFAULT 0;
