import 'package:freezed_annotation/freezed_annotation.dart';
import 'game_action.dart';
import 'game_state.dart';

part 'websocket_messages.freezed.dart';
part 'websocket_messages.g.dart';

@freezed
class GameActionMessage with _$GameActionMessage {
  const factory GameActionMessage({
    required String gameId,
    required GameAction action,
  }) = _GameActionMessage;

  factory GameActionMessage.fromJson(Map<String, dynamic> json) =>
      _$GameActionMessageFromJson(json);
}

@freezed
class GameStateUpdateMessage with _$GameStateUpdateMessage {
  const factory GameStateUpdateMessage({
    required String gameId,
    required GameState gameState,
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

@freezed
class JoinGameMessage with _$JoinGameMessage {
  const factory JoinGameMessage({required String gameId}) = _JoinGameMessage;

  factory JoinGameMessage.fromJson(Map<String, dynamic> json) =>
      _$JoinGameMessageFromJson(json);
}
