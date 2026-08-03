import 'package:freezed_annotation/freezed_annotation.dart';
import 'game_state.dart';

part 'websocket_messages.freezed.dart';
part 'websocket_messages.g.dart';

@freezed
class GameStateUpdateMessage with _$GameStateUpdateMessage {
  const factory GameStateUpdateMessage({
    required String gameId,
    required GameState gameState,
    String? turnStartedAt,
    @Default(30000) int turnTimeLimitMs,
    @Default(120000) int player1TimeBankMs,
    @Default(120000) int player2TimeBankMs,
    @Default(false) bool isTimed,
    int? timestamp,
  }) = _GameStateUpdateMessage;

  factory GameStateUpdateMessage.fromJson(Map<String, dynamic> json) =>
      _$GameStateUpdateMessageFromJson(json);
}

@freezed
class GameErrorMessage with _$GameErrorMessage {
  const factory GameErrorMessage({
    required String gameId,
    required String error,
    int? timestamp,
  }) = _GameErrorMessage;

  factory GameErrorMessage.fromJson(Map<String, dynamic> json) =>
      _$GameErrorMessageFromJson(json);
}
