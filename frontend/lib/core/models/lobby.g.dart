// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lobby.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LobbyPlayerImpl _$$LobbyPlayerImplFromJson(Map<String, dynamic> json) =>
    _$LobbyPlayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      joinedAt: json['joinedAt'] as String,
    );

Map<String, dynamic> _$$LobbyPlayerImplToJson(_$LobbyPlayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'joinedAt': instance.joinedAt,
    };

_$LobbyImpl _$$LobbyImplFromJson(Map<String, dynamic> json) => _$LobbyImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  players:
      (json['players'] as List<dynamic>?)
          ?.map((e) => LobbyPlayer.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 2,
  status:
      $enumDecodeNullable(_$LobbyStatusEnumMap, json['status']) ??
      LobbyStatus.waiting,
  createdAt: json['createdAt'] as String,
  gameId: json['gameId'] as String?,
);

Map<String, dynamic> _$$LobbyImplToJson(_$LobbyImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'players': instance.players,
      'maxPlayers': instance.maxPlayers,
      'status': _$LobbyStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt,
      'gameId': instance.gameId,
    };

const _$LobbyStatusEnumMap = {
  LobbyStatus.waiting: 'WAITING',
  LobbyStatus.inGame: 'IN_GAME',
  LobbyStatus.completed: 'COMPLETED',
};
