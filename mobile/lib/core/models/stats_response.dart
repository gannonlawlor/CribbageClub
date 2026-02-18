import 'package:freezed_annotation/freezed_annotation.dart';

part 'stats_response.freezed.dart';
part 'stats_response.g.dart';

@freezed
class StatsResponse with _$StatsResponse {
  const factory StatsResponse({
    required String playerId,
    @Default(0) int gamesPlayed,
    @Default(0) int gamesWon,
    @Default(0) int gamesLost,
    @Default(0.0) double winRate,
    @Default(0.0) double averageScore,
    @Default(0) int highestGameScore,
    @Default(0) int currentWinStreak,
    @Default(0) int longestWinStreak,
    @Default(1500.0) double rating,
    @Default(350.0) double ratingDeviation,
  }) = _StatsResponse;

  factory StatsResponse.fromJson(Map<String, dynamic> json) =>
      _$StatsResponseFromJson(json);
}
