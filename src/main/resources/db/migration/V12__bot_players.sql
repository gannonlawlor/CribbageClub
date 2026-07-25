-- Bot fallback matchmaking: a pool of human-looking bot accounts that join
-- quick-match lobbies when no human opponent shows up.
--
-- Bots are ordinary users (UUID ids, no ai_/guest_ prefix) so the existing
-- rating path treats their games as rated human games. is_bot is server-only
-- and must never be exposed in any DTO.

ALTER TABLE users ADD COLUMN is_bot BOOLEAN NOT NULL DEFAULT FALSE;
-- Fixed engine strength per persona ('basic' | 'medium' | 'hard'). Deliberately
-- not derived from the live rating: a bot's rating drifts with results, but its
-- play strength must stay stable.
ALTER TABLE users ADD COLUMN bot_difficulty VARCHAR(20);

-- Separate from ai_player_id/ai_difficulty on purpose: those drive the legacy
-- synchronous "AI Opponent" path (untimed, unrated). Bot games are timed and
-- rated (is_ai_game = FALSE) and are driven asynchronously with delays.
ALTER TABLE games ADD COLUMN bot_player_id VARCHAR(255);
ALTER TABLE games ADD COLUMN bot_difficulty VARCHAR(20);

-- Discriminates quick-match lobbies from user-created public lobbies; bots
-- only ever fill quick-match lobbies.
ALTER TABLE lobbies ADD COLUMN is_quick_match BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX idx_users_is_bot ON users (is_bot) WHERE is_bot;
CREATE INDEX idx_lobbies_quick_match_waiting ON lobbies (status, is_quick_match, created_at);
CREATE INDEX idx_games_active_bot ON games (bot_player_id) WHERE bot_player_id IS NOT NULL;

-- Seed the persona pool: 5 basic / 6 medium / 5 hard, ratings spread across
-- each tier's band. ON CONFLICT guards against username collisions with real
-- accounts; a colliding persona is simply skipped.
INSERT INTO users (id, username, password_hash, display_name, is_guest, is_bot, bot_difficulty, avatar_index, created_at, last_login_at) VALUES
    ('7ce95b3a-44cf-4e40-80a9-68d098a56c39', 'mollyq',         NULL, 'Molly Q.',     FALSE, TRUE, 'basic',  2, '2025-11-14T16:22:09Z', '2026-07-19T02:11:40Z'),
    ('78464a33-7846-4dd2-befb-6b9c7d3ddd77', 'tom_59',         NULL, 'Tom',          FALSE, TRUE, 'basic',  7, '2026-01-08T21:03:55Z', '2026-07-21T13:45:12Z'),
    ('88f1fad7-2322-4af1-81a8-084dfc678443', 'lindad',         NULL, 'Linda D.',     FALSE, TRUE, 'basic',  4, '2025-12-02T11:47:31Z', '2026-07-20T19:30:08Z'),
    ('dcceedcd-e528-4d93-bcfd-42fa2b4435b4', 'pegs_n_pints',   NULL, 'Charlie',      FALSE, TRUE, 'basic',  1, '2026-02-17T08:15:26Z', '2026-07-22T07:58:33Z'),
    ('5927ff8c-0448-490d-b9f1-16cf1d18e24a', 'jbeckett',       NULL, 'Jess Beckett', FALSE, TRUE, 'basic',  9, '2025-10-27T19:38:44Z', '2026-07-18T22:14:57Z'),
    ('4bc8a778-3489-46b7-961e-e6a8f5d585d9', 'sarahjk',        NULL, 'Sarah',        FALSE, TRUE, 'medium', 5, '2025-11-30T14:52:18Z', '2026-07-21T20:41:25Z'),
    ('59fcb7e3-6cbc-4785-bacb-1a5ca35aa564', 'mikepegs',       NULL, 'Mike P.',      FALSE, TRUE, 'medium', 0, '2026-03-05T17:26:50Z', '2026-07-22T15:03:19Z'),
    ('ae6be75b-fcfc-435d-9a76-34dbc1586cf3', 'anniemac',       NULL, 'Annie Mac',    FALSE, TRUE, 'medium', 8, '2025-12-19T09:34:02Z', '2026-07-20T11:27:46Z'),
    ('0a24e28e-df85-4f55-9a02-0810cf1d9501', 'dbl_run_dan',    NULL, 'Dan',          FALSE, TRUE, 'medium', 3, '2026-01-23T22:41:37Z', '2026-07-23T04:19:52Z'),
    ('d4c0ec37-e6fc-42b1-9c64-496fc793fc85', 'heatherb77',     NULL, 'Heather B.',   FALSE, TRUE, 'medium', 6, '2025-11-06T12:09:23Z', '2026-07-19T17:36:04Z'),
    ('b703a7cf-7907-4c71-a7aa-178cc1cb44d1', 'kwhitfield',     NULL, 'K. Whitfield', FALSE, TRUE, 'medium', 2, '2026-02-01T15:58:11Z', '2026-07-22T23:50:38Z'),
    ('ce84b710-8367-4d14-ab8d-2a3a6606b3a3', 'gcormier',       NULL, 'G. Cormier',   FALSE, TRUE, 'hard',   7, '2025-10-15T20:17:49Z', '2026-07-21T09:12:21Z'),
    ('694a3be8-c0ab-4b35-a71a-8e2d0a6747e9', 'skunk_line_sam', NULL, 'Sam',          FALSE, TRUE, 'hard',   1, '2026-01-11T13:44:56Z', '2026-07-23T18:28:43Z'),
    ('90bbb7f2-3c79-4a6a-8506-bcc63c848a9a', 'vpatel88',       NULL, 'V. Patel',     FALSE, TRUE, 'hard',   5, '2025-12-08T18:29:14Z', '2026-07-20T21:55:16Z'),
    ('79a85d4e-8a95-4b64-b3ae-8237977a8c88', 'muggins_marie',  NULL, 'Marie',        FALSE, TRUE, 'hard',   9, '2026-02-26T10:06:39Z', '2026-07-22T12:33:59Z'),
    ('e7dc0c9c-506e-416b-aaf5-6fd23de7af38', 'the_cut_card',   NULL, 'Alex R.',      FALSE, TRUE, 'hard',   4, '2025-11-21T23:51:07Z', '2026-07-23T08:47:30Z')
ON CONFLICT (username) DO NOTHING;

-- Matching stats rows. rating_deviation 200 (not the 350 default): settled
-- enough that early bot games don't whipsaw opponents' ratings, loose enough
-- to drift toward true strength. Seeded game counts give profiles a plausible
-- history instead of "0 games, rating 1780"; human_* mirrors overall because
-- bots only play humans; win/loss points average ~100/85 per game.
INSERT INTO player_stats (player_id, games_played, games_won, games_lost,
                          total_points_scored, total_points_against, highest_game_score,
                          current_win_streak, longest_win_streak,
                          rating, rating_deviation, rating_volatility,
                          human_games_played, human_games_won, human_games_lost,
                          human_total_points_scored, human_total_points_against,
                          created_at, updated_at)
SELECT u.id, s.gp, s.gw, s.gp - s.gw,
       s.pts_for, s.pts_against, 121,
       s.cur_streak, s.max_streak,
       s.rating, 200.0, 0.06,
       s.gp, s.gw, s.gp - s.gw,
       s.pts_for, s.pts_against,
       u.created_at, u.last_login_at
FROM (VALUES
    ('mollyq',         1160.0, 31, 12, 2998, 3355, 1, 2),
    ('tom_59',         1210.0, 24, 10, 2352, 2617, 0, 3),
    ('lindad',         1250.0, 45, 20, 4452, 4890, 2, 3),
    ('pegs_n_pints',   1300.0, 19,  9, 1902, 2043, 1, 3),
    ('jbeckett',       1340.0, 52, 25, 5230, 5567, 0, 4),
    ('sarahjk',        1410.0, 38, 19, 3857, 3985, 2, 4),
    ('mikepegs',       1460.0, 27, 14, 2764, 2801, 1, 4),
    ('anniemac',       1500.0, 61, 32, 6273, 6231, 0, 5),
    ('dbl_run_dan',    1550.0, 33, 18, 3421, 3319, 3, 5),
    ('heatherb77',     1590.0, 48, 27, 5007, 4791, 1, 5),
    ('kwhitfield',     1600.0, 22, 13, 2312, 2166, 2, 4),
    ('gcormier',       1660.0, 55, 34, 5852, 5423, 2, 6),
    ('skunk_line_sam', 1730.0, 29, 19, 3132, 2801, 4, 6),
    ('vpatel88',       1800.0, 67, 45, 7311, 6539, 1, 7),
    ('muggins_marie',  1870.0, 41, 29, 4529, 3936, 3, 7),
    ('the_cut_card',   1940.0, 74, 54, 8214, 7103, 5, 9)
) AS s(username, rating, gp, gw, pts_for, pts_against, cur_streak, max_streak)
JOIN users u ON u.username = s.username AND u.is_bot
ON CONFLICT (player_id) DO NOTHING;
