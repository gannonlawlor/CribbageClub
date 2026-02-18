-- Initial schema matching existing Hibernate-generated tables

CREATE TABLE users (
    id          VARCHAR(255) NOT NULL PRIMARY KEY,
    username    VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    last_login_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE games (
    id              VARCHAR(255) NOT NULL PRIMARY KEY,
    player1_id      VARCHAR(255) NOT NULL,
    player1_name    VARCHAR(255) NOT NULL,
    player2_id      VARCHAR(255) NOT NULL,
    player2_name    VARCHAR(255) NOT NULL,
    player1_score   INTEGER NOT NULL DEFAULT 0,
    player2_score   INTEGER NOT NULL DEFAULT 0,
    stage           VARCHAR(255) NOT NULL DEFAULT 'DEALING',
    current_player_id VARCHAR(255),
    is_ai_game      BOOLEAN NOT NULL DEFAULT FALSE,
    ai_player_id    VARCHAR(255),
    ai_difficulty   VARCHAR(255),
    winner_id       VARCHAR(255),
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL,
    state_json      TEXT,
    version         BIGINT NOT NULL DEFAULT 0
);

CREATE TABLE lobbies (
    id          VARCHAR(255) NOT NULL PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    max_players INTEGER NOT NULL DEFAULT 2,
    status      VARCHAR(255) NOT NULL DEFAULT 'WAITING',
    game_id     VARCHAR(255),
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    players_json TEXT NOT NULL DEFAULT '[]',
    version     BIGINT NOT NULL DEFAULT 0
);

CREATE TABLE player_stats (
    player_id           VARCHAR(255) NOT NULL PRIMARY KEY,
    games_played        INTEGER NOT NULL DEFAULT 0,
    games_won           INTEGER NOT NULL DEFAULT 0,
    games_lost          INTEGER NOT NULL DEFAULT 0,
    total_points_scored BIGINT NOT NULL DEFAULT 0,
    total_points_against BIGINT NOT NULL DEFAULT 0,
    highest_game_score  INTEGER NOT NULL DEFAULT 0,
    current_win_streak  INTEGER NOT NULL DEFAULT 0,
    longest_win_streak  INTEGER NOT NULL DEFAULT 0,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL,
    version             BIGINT NOT NULL DEFAULT 0
);
