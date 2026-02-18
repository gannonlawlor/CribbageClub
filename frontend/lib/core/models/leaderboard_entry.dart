import 'package:freezed_annotation/freezed_annotation.dart';

part 'leaderboard_entry.freezed.dart';
part 'leaderboard_entry.g.dart';

@freezed
class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required String playerId,
    required String displayName,
    @Default(0) int gamesPlayed,
    @Default(0) int gamesWon,
    @Default(0) int gamesLost,
    @Default(0.0) double winRate,
    @Default(0.0) double averageScore,
    @Default(0) int highestGameScore,
    @Default(0) int currentWinStreak,
    @Default(0) int longestWinStreak,
    @Default(1500.0) double rating,
  }) = _LeaderboardEntry;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);
}
