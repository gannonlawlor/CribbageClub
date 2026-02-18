// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DiscardToCribImpl _$$DiscardToCribImplFromJson(Map<String, dynamic> json) =>
    _$DiscardToCribImpl(
      playerId: json['playerId'] as String,
      card: PlayingCard.fromJson(json['card'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$DiscardToCribImplToJson(_$DiscardToCribImpl instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'card': instance.card,
      'type': instance.$type,
    };

_$PlayCardImpl _$$PlayCardImplFromJson(Map<String, dynamic> json) =>
    _$PlayCardImpl(
      playerId: json['playerId'] as String,
      card: PlayingCard.fromJson(json['card'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$PlayCardImplToJson(_$PlayCardImpl instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'card': instance.card,
      'type': instance.$type,
    };

_$CutDeckImpl _$$CutDeckImplFromJson(Map<String, dynamic> json) =>
    _$CutDeckImpl(
      playerId: json['playerId'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$CutDeckImplToJson(_$CutDeckImpl instance) =>
    <String, dynamic>{'playerId': instance.playerId, 'type': instance.$type};

_$GoImpl _$$GoImplFromJson(Map<String, dynamic> json) => _$GoImpl(
  playerId: json['playerId'] as String,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$$GoImplToJson(_$GoImpl instance) => <String, dynamic>{
  'playerId': instance.playerId,
  'type': instance.$type,
};

_$CountHandImpl _$$CountHandImplFromJson(Map<String, dynamic> json) =>
    _$CountHandImpl(
      playerId: json['playerId'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$CountHandImplToJson(_$CountHandImpl instance) =>
    <String, dynamic>{'playerId': instance.playerId, 'type': instance.$type};

_$ForfeitActionImpl _$$ForfeitActionImplFromJson(Map<String, dynamic> json) =>
    _$ForfeitActionImpl(
      playerId: json['playerId'] as String,
      reason: json['reason'] as String? ?? 'RESIGN',
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$ForfeitActionImplToJson(_$ForfeitActionImpl instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'reason': instance.reason,
      'type': instance.$type,
    };
