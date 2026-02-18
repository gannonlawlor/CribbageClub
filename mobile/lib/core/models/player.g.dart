// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerImpl _$$PlayerImplFromJson(Map<String, dynamic> json) => _$PlayerImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  hand:
      (json['hand'] as List<dynamic>?)
          ?.map((e) => PlayingCard.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  score: (json['score'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$PlayerImplToJson(_$PlayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'hand': instance.hand,
      'score': instance.score,
    };
