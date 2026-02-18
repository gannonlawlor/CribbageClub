// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_messages.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameActionMessageImpl _$$GameActionMessageImplFromJson(
  Map<String, dynamic> json,
) => _$GameActionMessageImpl(
  gameId: json['gameId'] as String,
  action: GameAction.fromJson(json['action'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$GameActionMessageImplToJson(
  _$GameActionMessageImpl instance,
) => <String, dynamic>{'gameId': instance.gameId, 'action': instance.action};

_$GameStateUpdateMessageImpl _$$GameStateUpdateMessageImplFromJson(
  Map<String, dynamic> json,
) => _$GameStateUpdateMessageImpl(
  gameId: json['gameId'] as String,
  gameState: GameState.fromJson(json['gameState'] as Map<String, dynamic>),
  turnStartedAt: json['turnStartedAt'] as String?,
  turnTimeLimitMs: (json['turnTimeLimitMs'] as num?)?.toInt() ?? 30000,
  player1TimeBankMs: (json['player1TimeBankMs'] as num?)?.toInt() ?? 120000,
  player2TimeBankMs: (json['player2TimeBankMs'] as num?)?.toInt() ?? 120000,
  isTimed: json['isTimed'] as bool? ?? false,
  timestamp: (json['timestamp'] as num?)?.toInt(),
);

Map<String, dynamic> _$$GameStateUpdateMessageImplToJson(
  _$GameStateUpdateMessageImpl instance,
) => <String, dynamic>{
  'gameId': instance.gameId,
  'gameState': instance.gameState,
  'turnStartedAt': instance.turnStartedAt,
  'turnTimeLimitMs': instance.turnTimeLimitMs,
  'player1TimeBankMs': instance.player1TimeBankMs,
  'player2TimeBankMs': instance.player2TimeBankMs,
  'isTimed': instance.isTimed,
  'timestamp': instance.timestamp,
};

_$GameErrorMessageImpl _$$GameErrorMessageImplFromJson(
  Map<String, dynamic> json,
) => _$GameErrorMessageImpl(
  gameId: json['gameId'] as String,
  error: json['error'] as String,
  timestamp: (json['timestamp'] as num?)?.toInt(),
);

Map<String, dynamic> _$$GameErrorMessageImplToJson(
  _$GameErrorMessageImpl instance,
) => <String, dynamic>{
  'gameId': instance.gameId,
  'error': instance.error,
  'timestamp': instance.timestamp,
};

_$JoinGameMessageImpl _$$JoinGameMessageImplFromJson(
  Map<String, dynamic> json,
) => _$JoinGameMessageImpl(gameId: json['gameId'] as String);

Map<String, dynamic> _$$JoinGameMessageImplToJson(
  _$JoinGameMessageImpl instance,
) => <String, dynamic>{'gameId': instance.gameId};
