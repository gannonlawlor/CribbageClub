// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthResponseImpl _$$AuthResponseImplFromJson(Map<String, dynamic> json) =>
    _$AuthResponseImpl(
      token: json['token'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      isGuest: json['isGuest'] as bool? ?? false,
    );

Map<String, dynamic> _$$AuthResponseImplToJson(_$AuthResponseImpl instance) =>
    <String, dynamic>{
      'token': instance.token,
      'userId': instance.userId,
      'username': instance.username,
      'displayName': instance.displayName,
      'isGuest': instance.isGuest,
    };
