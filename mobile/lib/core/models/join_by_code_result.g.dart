// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_by_code_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JoinByCodeResultImpl _$$JoinByCodeResultImplFromJson(
  Map<String, dynamic> json,
) => _$JoinByCodeResultImpl(
  lobby: Lobby.fromJson(json['lobby'] as Map<String, dynamic>),
  gameState: json['gameState'] == null
      ? null
      : GameState.fromJson(json['gameState'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$JoinByCodeResultImplToJson(
  _$JoinByCodeResultImpl instance,
) => <String, dynamic>{
  'lobby': instance.lobby,
  'gameState': instance.gameState,
};
