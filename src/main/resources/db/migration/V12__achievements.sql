-- Achievements: unlock rows plus post-launch progress counters.
-- The catalog itself lives in code (Achievement enum) — adding an
-- achievement is a deploy, not a migration.

CREATE TABLE player_achievements (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id),
    achievement_key VARCHAR(64) NOT NULL,
    unlocked_at TIMESTAMP WITH TIME ZONE NOT NULL,
    game_id VARCHAR(255),
    CONSTRAINT uq_user_achievement UNIQUE (user_id, achievement_key)
);
CREATE INDEX idx_player_achievements_user ON player_achievements(user_id);

-- Counters start at zero at feature launch (fresh-start decision): lifetime
-- player_stats would silently hand veterans WINS_100 on day one.
CREATE TABLE achievement_progress (
    user_id VARCHAR(255) PRIMARY KEY REFERENCES users(id),
    wins INT NOT NULL DEFAULT 0,
    current_win_streak INT NOT NULL DEFAULT 0,
    optimal_puzzle_solves INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    version BIGINT NOT NULL DEFAULT 0
);
