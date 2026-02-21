import 'package:freezed_annotation/freezed_annotation.dart';

part 'head_to_head_response.freezed.dart';
part 'head_to_head_response.g.dart';

@freezed
class HeadToHeadResponse with _$HeadToHeadResponse {
  const factory HeadToHeadResponse({
    @Default(0) int gamesPlayed,
    @Default(0) int viewerWins,
    @Default(0) int opponentWins,
    @Default([]) List<HeadToHeadGame> recentGames,
  }) = _HeadToHeadResponse;

  factory HeadToHeadResponse.fromJson(Map<String, dynamic> json) =>
      _$HeadToHeadResponseFromJson(json);
}

@freezed
class HeadToHeadGame with _$HeadToHeadGame {
  const factory HeadToHeadGame({
    required String gameId,
    @Default(0) int viewerScore,
    @Default(0) int opponentScore,
    @Default(false) bool viewerWon,
    required String completedAt,
  }) = _HeadToHeadGame;

  factory HeadToHeadGame.fromJson(Map<String, dynamic> json) =>
      _$HeadToHeadGameFromJson(json);
}
