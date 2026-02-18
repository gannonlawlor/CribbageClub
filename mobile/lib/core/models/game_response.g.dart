// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameResponseImpl _$$GameResponseImplFromJson(Map<String, dynamic> json) =>
    _$GameResponseImpl(
      gameState: GameState.fromJson(json['gameState'] as Map<String, dynamic>),
      turnStartedAt: json['turnStartedAt'] as String?,
      turnTimeLimitMs: (json['turnTimeLimitMs'] as num?)?.toInt() ?? 30000,
      myTimeBankMs: (json['myTimeBankMs'] as num?)?.toInt() ?? 120000,
      opponentTimeBankMs:
          (json['opponentTimeBankMs'] as num?)?.toInt() ?? 120000,
      isTimed: json['isTimed'] as bool? ?? false,
    );

Map<String, dynamic> _$$GameResponseImplToJson(_$GameResponseImpl instance) =>
    <String, dynamic>{
      'gameState': instance.gameState,
      'turnStartedAt': instance.turnStartedAt,
      'turnTimeLimitMs': instance.turnTimeLimitMs,
      'myTimeBankMs': instance.myTimeBankMs,
      'opponentTimeBankMs': instance.opponentTimeBankMs,
      'isTimed': instance.isTimed,
    };
