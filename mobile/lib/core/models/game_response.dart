import 'package:freezed_annotation/freezed_annotation.dart';
import 'game_state.dart';

part 'game_response.freezed.dart';
part 'game_response.g.dart';

@freezed
class GameResponse with _$GameResponse {
  const factory GameResponse({
    required GameState gameState,
    String? turnStartedAt,
    @Default(30000) int turnTimeLimitMs,
    @Default(120000) int myTimeBankMs,
    @Default(120000) int opponentTimeBankMs,
    @Default(false) bool isTimed,
  }) = _GameResponse;

  factory GameResponse.fromJson(Map<String, dynamic> json) =>
      _$GameResponseFromJson(json);
}
