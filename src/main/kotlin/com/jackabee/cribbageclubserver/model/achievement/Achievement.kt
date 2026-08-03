package com.jackabee.cribbageclubserver.model.achievement

enum class AchievementTier { BRONZE, SILVER, GOLD }

/**
 * The achievement catalog. Ordinal is the display sort order; the enum name is
 * the stable key stored in player_achievements and used by clients, so never
 * rename an entry once it has shipped.
 *
 * [target] marks a counter achievement whose progress (from
 * achievement_progress, post-launch only) is shown while locked.
 */
enum class Achievement(
    val displayName: String,
    val description: String,
    val tier: AchievementTier,
    val target: Int? = null
) {
    FIRST_GAME("Welcome to the Club", "Finish a game", AchievementTier.BRONZE),
    FIRST_WIN("On the Board", "Win a game", AchievementTier.BRONZE),
    WINS_10("Regular", "Win 10 games", AchievementTier.BRONZE, target = 10),
    WINS_50("Club Veteran", "Win 50 games", AchievementTier.SILVER, target = 50),
    WINS_100("Centurion", "Win 100 games", AchievementTier.GOLD, target = 100),
    STREAK_5("Hot Streak", "Win 5 games in a row", AchievementTier.SILVER, target = 5),
    STREAK_10("Unstoppable", "Win 10 games in a row", AchievementTier.GOLD, target = 10),
    BEAT_AI_MEDIUM("Worthy Opponent", "Beat the medium bot", AchievementTier.BRONZE),
    BEAT_AI_HARD("Machine Breaker", "Beat the hard bot", AchievementTier.SILVER),
    SKUNK("Skunked!", "Win before your opponent reaches 91", AchievementTier.SILVER),
    DOUBLE_SKUNK("Double Skunk", "Win before your opponent reaches 61", AchievementTier.GOLD),
    SKUNK_AI_HARD("Humbled the Machine", "Skunk the hard bot", AchievementTier.GOLD),
    COMEBACK("The Comeback", "Win after trailing by 30 or more", AchievementTier.GOLD),
    HAND_20("Twenty Club", "Count a hand worth 20 or more", AchievementTier.SILVER),
    HAND_24("Twenty-Four Karat", "Count a hand worth 24 or more", AchievementTier.GOLD),
    HAND_29("The Perfect Hand", "Count the perfect 29 hand", AchievementTier.GOLD),
    CRIB_12("Golden Crib", "Count a crib worth 12 or more", AchievementTier.SILVER),
    HIS_HEELS("His Heels", "As dealer, score two for a cut jack", AchievementTier.BRONZE),
    PEG_31("Thirty-One", "Bring the count to exactly 31", AchievementTier.BRONZE),
    PEG_12_ROUND("Pegging Machine", "Peg 12 or more points in one round", AchievementTier.GOLD),
    FIRST_ONLINE_WIN("People Person", "Win against another person", AchievementTier.BRONZE),
    RATING_1600("Sixteen Hundred", "Reach a rating of 1600", AchievementTier.GOLD),
    FRIEND_ADDED("Making Friends", "Make a friend in the club", AchievementTier.BRONZE),
    PUZZLE_FIRST("Daily Habit", "Solve a daily puzzle", AchievementTier.BRONZE),
    PUZZLE_OPTIMAL_10("Optimizer", "Find the optimal discard on 10 daily puzzles", AchievementTier.SILVER, target = 10),
}
