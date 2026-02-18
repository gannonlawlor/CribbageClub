CREATE TABLE game_analyses (
    game_id       VARCHAR(255) PRIMARY KEY REFERENCES games(id),
    analysis_json TEXT NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
