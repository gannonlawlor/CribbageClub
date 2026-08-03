import 'package:freezed_annotation/freezed_annotation.dart';
import 'achievement.dart';
import 'card.dart';
import 'game_analysis.dart';

part 'puzzle.freezed.dart';
part 'puzzle.g.dart';

@freezed
class PuzzleResponse with _$PuzzleResponse {
  const factory PuzzleResponse({
    required String id,
    required List<PlayingCard> hand,
    required bool isDealer,
    required String puzzleDate,
    @Default(false) bool alreadySolved,
  }) = _PuzzleResponse;

  factory PuzzleResponse.fromJson(Map<String, dynamic> json) =>
      _$PuzzleResponseFromJson(json);
}

@freezed
class PuzzleSolveResponse with _$PuzzleSolveResponse {
  const factory PuzzleSolveResponse({
    required bool isOptimal,
    required double evDifference,
    required DiscardOption yourOption,
    required DiscardOption optimalOption,
    required List<DiscardOption> allOptions,
    @Default([]) List<AchievementStatus> unlockedAchievements,
  }) = _PuzzleSolveResponse;

  factory PuzzleSolveResponse.fromJson(Map<String, dynamic> json) =>
      _$PuzzleSolveResponseFromJson(json);
}
