// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FriendInfoImpl _$$FriendInfoImplFromJson(Map<String, dynamic> json) =>
    _$FriendInfoImpl(
      friendshipId: json['friendshipId'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      since: json['since'] as String,
    );

Map<String, dynamic> _$$FriendInfoImplToJson(_$FriendInfoImpl instance) =>
    <String, dynamic>{
      'friendshipId': instance.friendshipId,
      'userId': instance.userId,
      'username': instance.username,
      'displayName': instance.displayName,
      'isOnline': instance.isOnline,
      'since': instance.since,
    };

_$FriendRequestInfoImpl _$$FriendRequestInfoImplFromJson(
  Map<String, dynamic> json,
) => _$FriendRequestInfoImpl(
  friendshipId: json['friendshipId'] as String,
  fromUserId: json['fromUserId'] as String,
  fromUsername: json['fromUsername'] as String,
  fromDisplayName: json['fromDisplayName'] as String?,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$$FriendRequestInfoImplToJson(
  _$FriendRequestInfoImpl instance,
) => <String, dynamic>{
  'friendshipId': instance.friendshipId,
  'fromUserId': instance.fromUserId,
  'fromUsername': instance.fromUsername,
  'fromDisplayName': instance.fromDisplayName,
  'createdAt': instance.createdAt,
};

_$UserSearchResultImpl _$$UserSearchResultImplFromJson(
  Map<String, dynamic> json,
) => _$UserSearchResultImpl(
  userId: json['userId'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String?,
  relationshipStatus: json['relationshipStatus'] as String?,
);

Map<String, dynamic> _$$UserSearchResultImplToJson(
  _$UserSearchResultImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'username': instance.username,
  'displayName': instance.displayName,
  'relationshipStatus': instance.relationshipStatus,
};

_$NotificationCountImpl _$$NotificationCountImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationCountImpl(
  friendRequests: (json['friendRequests'] as num?)?.toInt() ?? 0,
  challenges: (json['challenges'] as num?)?.toInt() ?? 0,
  total: (json['total'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$NotificationCountImplToJson(
  _$NotificationCountImpl instance,
) => <String, dynamic>{
  'friendRequests': instance.friendRequests,
  'challenges': instance.challenges,
  'total': instance.total,
};
