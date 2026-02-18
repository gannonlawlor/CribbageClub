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

_$LoginRequestImpl _$$LoginRequestImplFromJson(Map<String, dynamic> json) =>
    _$LoginRequestImpl(
      username: json['username'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$$LoginRequestImplToJson(_$LoginRequestImpl instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };

_$RegisterRequestImpl _$$RegisterRequestImplFromJson(
  Map<String, dynamic> json,
) => _$RegisterRequestImpl(
  username: json['username'] as String,
  password: json['password'] as String,
  displayName: json['displayName'] as String?,
);

Map<String, dynamic> _$$RegisterRequestImplToJson(
  _$RegisterRequestImpl instance,
) => <String, dynamic>{
  'username': instance.username,
  'password': instance.password,
  'displayName': instance.displayName,
};

_$UpgradeRequestImpl _$$UpgradeRequestImplFromJson(Map<String, dynamic> json) =>
    _$UpgradeRequestImpl(
      username: json['username'] as String,
      password: json['password'] as String,
      displayName: json['displayName'] as String?,
    );

Map<String, dynamic> _$$UpgradeRequestImplToJson(
  _$UpgradeRequestImpl instance,
) => <String, dynamic>{
  'username': instance.username,
  'password': instance.password,
  'displayName': instance.displayName,
};
