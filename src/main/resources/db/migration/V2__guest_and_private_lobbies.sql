-- Support guest users (nullable password) and private lobbies (invite codes)

ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;
ALTER TABLE users ADD COLUMN is_guest BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE lobbies ADD COLUMN is_private BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE lobbies ADD COLUMN invite_code VARCHAR(20) UNIQUE;
