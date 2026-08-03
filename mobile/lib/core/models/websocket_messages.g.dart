// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_messages.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
  view: json['view'] as String?,
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
  'view': instance.view,
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
