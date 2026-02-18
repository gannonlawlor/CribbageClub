CREATE TABLE friendships (
    id              VARCHAR(255) PRIMARY KEY,
    requester_id    VARCHAR(255) NOT NULL REFERENCES users(id),
    addressee_id    VARCHAR(255) NOT NULL REFERENCES users(id),
    status          VARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL,
    version         BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT uq_friendship_pair UNIQUE (requester_id, addressee_id),
    CONSTRAINT chk_no_self_friend CHECK (requester_id <> addressee_id)
);

ALTER TABLE lobbies ADD COLUMN challenged_user_id VARCHAR(255);
