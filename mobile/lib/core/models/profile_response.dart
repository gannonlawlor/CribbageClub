import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_response.freezed.dart';
part 'profile_response.g.dart';

@freezed
class ProfileResponse with _$ProfileResponse {
  const factory ProfileResponse({
    required String userId,
    required String username,
    String? displayName,
    int? avatarIndex,
    required String createdAt,
    String? relationshipStatus,
    @Default(1500.0) double rating,
    @Default(350.0) double ratingDeviation,
    @Default(0) int highestGameScore,
    @Default(0) int currentWinStreak,
    @Default(0) int longestWinStreak,
    required CategoryStats overallStats,
    required CategoryStats aiStats,
    required CategoryStats humanStats,
  }) = _ProfileResponse;

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseFromJson(json);
}

@freezed
class CategoryStats with _$CategoryStats {
  const factory CategoryStats({
    @Default(0) int gamesPlayed,
    @Default(0) int gamesWon,
    @Default(0) int gamesLost,
    @Default(0.0) double winRate,
    @Default(0.0) double averageScore,
  }) = _CategoryStats;

  factory CategoryStats.fromJson(Map<String, dynamic> json) =>
      _$CategoryStatsFromJson(json);
}
