CREATE TABLE puzzles (
    id                    VARCHAR(255) PRIMARY KEY,
    hand_json             TEXT NOT NULL,
    is_dealer             BOOLEAN NOT NULL,
    optimal_discard_json  TEXT NOT NULL,
    optimal_ev            DOUBLE PRECISION NOT NULL,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL,
    puzzle_date           DATE NOT NULL UNIQUE
);

CREATE TABLE puzzle_solves (
    id                  VARCHAR(255) PRIMARY KEY,
    puzzle_id           VARCHAR(255) NOT NULL REFERENCES puzzles(id),
    user_id             VARCHAR(255) NOT NULL REFERENCES users(id),
    chosen_discard_json TEXT NOT NULL,
    is_optimal          BOOLEAN NOT NULL,
    ev_diff             DOUBLE PRECISION NOT NULL,
    solved_at           TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uq_puzzle_user UNIQUE (puzzle_id, user_id)
);
