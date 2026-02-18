import 'package:freezed_annotation/freezed_annotation.dart';
import 'game_state.dart';
import 'lobby.dart';

part 'join_by_code_result.freezed.dart';
part 'join_by_code_result.g.dart';

@freezed
class JoinByCodeResult with _$JoinByCodeResult {
  const factory JoinByCodeResult({
    required Lobby lobby,
    GameState? gameState,
  }) = _JoinByCodeResult;

  factory JoinByCodeResult.fromJson(Map<String, dynamic> json) =>
      _$JoinByCodeResultFromJson(json);
}
