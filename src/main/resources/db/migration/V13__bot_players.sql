-- Bot fallback matchmaking: a persistent pool of human-looking bot accounts
-- that join quick-match lobbies when no human shows up (see BotMatchmakingService).
--
-- Bots are ordinary users with a server-only is_bot flag: UUID ids (not "ai_"),
-- human usernames, and real player_stats rows so their profiles look normal and
-- their Glicko-2 ratings drift with results. bot_difficulty is fixed per persona —
-- deriving it from the live rating would silently change a bot's strength.

ALTER TABLE users ADD COLUMN is_bot BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD COLUMN bot_difficulty VARCHAR(20);

ALTER TABLE games ADD COLUMN bot_player_id VARCHAR(255);
ALTER TABLE games ADD COLUMN bot_difficulty VARCHAR(20);

-- Discriminator so bots only ever fill quick-match lobbies, never user-created
-- public lobbies (matching on the lobby name would be fragile).
ALTER TABLE lobbies ADD COLUMN is_quick_match BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX idx_users_is_bot ON users (is_bot) WHERE is_bot;
CREATE INDEX idx_lobbies_quick_match_wait ON lobbies (status, is_quick_match, created_at);

-- Seed the 16 bot personas. password_hash stays NULL so they can never log in.
-- ON CONFLICT (username) DO NOTHING survives collisions with real prod usernames;
-- a skipped persona just shrinks the pool.
INSERT INTO users (id, username, password_hash, display_name, is_guest, created_at, last_login_at, avatar_index, is_bot, bot_difficulty) VALUES
    ('b0a1c2d3-1111-4a01-9b01-000000000001', 'mollyq',         NULL, 'Molly Quinn',      FALSE, '2025-09-14T18:22:00Z', '2026-07-28T21:04:00Z', 2, TRUE, 'basic'),
    ('b0a1c2d3-1111-4a01-9b01-000000000002', 'tom_59',         NULL, 'Tom',              FALSE, '2025-10-02T14:47:00Z', '2026-07-30T19:31:00Z', 5, TRUE, 'basic'),
    ('b0a1c2d3-1111-4a01-9b01-000000000003', 'lindad',         NULL, 'Linda D.',         FALSE, '2025-11-19T09:03:00Z', '2026-07-25T16:12:00Z', 1, TRUE, 'basic'),
    ('b0a1c2d3-1111-4a01-9b01-000000000004', 'pegs_n_pints',   NULL, 'Pegs & Pints',     FALSE, '2025-12-05T20:15:00Z', '2026-08-01T22:40:00Z', 7, TRUE, 'basic'),
    ('b0a1c2d3-1111-4a01-9b01-000000000005', 'jbeckett',       NULL, 'J. Beckett',       FALSE, '2026-01-11T11:38:00Z', '2026-07-29T18:55:00Z', 3, TRUE, 'basic'),
    ('b0a1c2d3-1111-4a01-9b01-000000000006', 'sarahjk',        NULL, 'Sarah',            FALSE, '2025-09-27T16:54:00Z', '2026-07-31T20:17:00Z', 6, TRUE, 'medium'),
    ('b0a1c2d3-1111-4a01-9b01-000000000007', 'mikepegs',       NULL, 'Mike',             FALSE, '2025-10-21T19:26:00Z', '2026-07-27T21:48:00Z', 0, TRUE, 'medium'),
    ('b0a1c2d3-1111-4a01-9b01-000000000008', 'anniemac',       NULL, 'Annie MacDonald',  FALSE, '2025-11-08T13:41:00Z', '2026-08-02T17:29:00Z', 4, TRUE, 'medium'),
    ('b0a1c2d3-1111-4a01-9b01-000000000009', 'dbl_run_dan',    NULL, 'Dan',              FALSE, '2025-12-16T21:07:00Z', '2026-07-26T20:03:00Z', 2, TRUE, 'medium'),
    ('b0a1c2d3-1111-4a01-9b01-000000000010', 'heatherb77',     NULL, 'Heather B.',       FALSE, '2026-01-29T10:19:00Z', '2026-07-30T22:14:00Z', 5, TRUE, 'medium'),
    ('b0a1c2d3-1111-4a01-9b01-000000000011', 'kwhitfield',     NULL, 'K. Whitfield',     FALSE, '2026-02-14T15:33:00Z', '2026-08-01T19:46:00Z', 1, TRUE, 'medium'),
    ('b0a1c2d3-1111-4a01-9b01-000000000012', 'gcormier',       NULL, 'G. Cormier',       FALSE, '2025-10-09T17:12:00Z', '2026-07-28T20:38:00Z', 6, TRUE, 'hard'),
    ('b0a1c2d3-1111-4a01-9b01-000000000013', 'skunk_line_sam', NULL, 'Sam',              FALSE, '2025-11-24T12:58:00Z', '2026-07-31T21:22:00Z', 3, TRUE, 'hard'),
    ('b0a1c2d3-1111-4a01-9b01-000000000014', 'vpatel88',       NULL, 'V. Patel',         FALSE, '2025-12-30T18:44:00Z', '2026-08-02T18:09:00Z', 7, TRUE, 'hard'),
    ('b0a1c2d3-1111-4a01-9b01-000000000015', 'muggins_marie',  NULL, 'Marie',            FALSE, '2026-01-18T14:26:00Z', '2026-07-29T19:52:00Z', 0, TRUE, 'hard'),
    ('b0a1c2d3-1111-4a01-9b01-000000000016', 'the_cut_card',   NULL, 'The Cut Card',     FALSE, '2026-02-08T20:36:00Z', '2026-08-01T21:58:00Z', 4, TRUE, 'hard')
ON CONFLICT (username) DO NOTHING;

-- Seeded stats: ratings per tier (basic 1160-1340, medium 1410-1600, hard 1660-1940)
-- with deviation 200 (stable but able to drift) and modest game counts so a bot's
-- profile doesn't read "0 games, rating 1780" — the most obvious tell.
-- Split columns mirror totals as human games; ai_* stay 0.
INSERT INTO player_stats (player_id, games_played, games_won, games_lost, total_points_scored, total_points_against, highest_game_score, current_win_streak, longest_win_streak, rating, rating_deviation, rating_volatility, created_at, updated_at, human_games_played, human_games_won, human_games_lost, human_total_points_scored, human_total_points_against) VALUES
    ('b0a1c2d3-1111-4a01-9b01-000000000001', 24, 10, 14, 2305, 2410, 121, 0, 3, 1160, 200, 0.06, '2025-09-14T18:22:00Z', '2026-07-28T21:04:00Z', 24, 10, 14, 2305, 2410),
    ('b0a1c2d3-1111-4a01-9b01-000000000002', 37, 16, 21, 3540, 3705, 121, 1, 3, 1210, 200, 0.06, '2025-10-02T14:47:00Z', '2026-07-30T19:31:00Z', 37, 16, 21, 3540, 3705),
    ('b0a1c2d3-1111-4a01-9b01-000000000003', 19,  8, 11, 1820, 1905, 121, 0, 2, 1250, 200, 0.06, '2025-11-19T09:03:00Z', '2026-07-25T16:12:00Z', 19,  8, 11, 1820, 1905),
    ('b0a1c2d3-1111-4a01-9b01-000000000004', 45, 21, 24, 4330, 4470, 121, 0, 4, 1300, 200, 0.06, '2025-12-05T20:15:00Z', '2026-08-01T22:40:00Z', 45, 21, 24, 4330, 4470),
    ('b0a1c2d3-1111-4a01-9b01-000000000005', 28, 13, 15, 2690, 2755, 121, 2, 3, 1340, 200, 0.06, '2026-01-11T11:38:00Z', '2026-07-29T18:55:00Z', 28, 13, 15, 2690, 2755),
    ('b0a1c2d3-1111-4a01-9b01-000000000006', 33, 16, 17, 3175, 3210, 121, 0, 4, 1410, 200, 0.06, '2025-09-27T16:54:00Z', '2026-07-31T20:17:00Z', 33, 16, 17, 3175, 3210),
    ('b0a1c2d3-1111-4a01-9b01-000000000007', 51, 26, 25, 4925, 4930, 121, 1, 5, 1460, 200, 0.06, '2025-10-21T19:26:00Z', '2026-07-27T21:48:00Z', 51, 26, 25, 4925, 4930),
    ('b0a1c2d3-1111-4a01-9b01-000000000008', 26, 13, 13, 2520, 2510, 121, 0, 3, 1500, 200, 0.06, '2025-11-08T13:41:00Z', '2026-08-02T17:29:00Z', 26, 13, 13, 2520, 2510),
    ('b0a1c2d3-1111-4a01-9b01-000000000009', 40, 21, 19, 3890, 3835, 121, 2, 4, 1550, 200, 0.06, '2025-12-16T21:07:00Z', '2026-07-26T20:03:00Z', 40, 21, 19, 3890, 3835),
    ('b0a1c2d3-1111-4a01-9b01-000000000010', 22, 12, 10, 2145, 2090, 121, 1, 3, 1590, 200, 0.06, '2026-01-29T10:19:00Z', '2026-07-30T22:14:00Z', 22, 12, 10, 2145, 2090),
    ('b0a1c2d3-1111-4a01-9b01-000000000011', 35, 19, 16, 3400, 3320, 121, 0, 5, 1600, 200, 0.06, '2026-02-14T15:33:00Z', '2026-08-01T19:46:00Z', 35, 19, 16, 3400, 3320),
    ('b0a1c2d3-1111-4a01-9b01-000000000012', 48, 27, 21, 4680, 4530, 121, 1, 5, 1660, 200, 0.06, '2025-10-09T17:12:00Z', '2026-07-28T20:38:00Z', 48, 27, 21, 4680, 4530),
    ('b0a1c2d3-1111-4a01-9b01-000000000013', 31, 18, 13, 3035, 2905, 121, 3, 5, 1730, 200, 0.06, '2025-11-24T12:58:00Z', '2026-07-31T21:22:00Z', 31, 18, 13, 3035, 2905),
    ('b0a1c2d3-1111-4a01-9b01-000000000014', 42, 25, 17, 4120, 3925, 121, 0, 6, 1800, 200, 0.06, '2025-12-30T18:44:00Z', '2026-08-02T18:09:00Z', 42, 25, 17, 4120, 3925),
    ('b0a1c2d3-1111-4a01-9b01-000000000015', 27, 17, 10, 2665, 2480, 121, 2, 6, 1870, 200, 0.06, '2026-01-18T14:26:00Z', '2026-07-29T19:52:00Z', 27, 17, 10, 2665, 2480),
    ('b0a1c2d3-1111-4a01-9b01-000000000016', 56, 36, 20, 5510, 5115, 121, 4, 8, 1940, 200, 0.06, '2026-02-08T20:36:00Z', '2026-08-01T21:58:00Z', 56, 36, 20, 5510, 5115)
ON CONFLICT (player_id) DO NOTHING;
