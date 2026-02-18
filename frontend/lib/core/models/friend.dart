import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend.freezed.dart';
part 'friend.g.dart';

@freezed
class FriendInfo with _$FriendInfo {
  const factory FriendInfo({
    required String friendshipId,
    required String userId,
    required String username,
    String? displayName,
    @Default(false) bool isOnline,
    required String since,
  }) = _FriendInfo;

  factory FriendInfo.fromJson(Map<String, dynamic> json) =>
      _$FriendInfoFromJson(json);
}

@freezed
class FriendRequestInfo with _$FriendRequestInfo {
  const factory FriendRequestInfo({
    required String friendshipId,
    required String fromUserId,
    required String fromUsername,
    String? fromDisplayName,
    required String createdAt,
  }) = _FriendRequestInfo;

  factory FriendRequestInfo.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestInfoFromJson(json);
}

@freezed
class UserSearchResult with _$UserSearchResult {
  const factory UserSearchResult({
    required String userId,
    required String username,
    String? displayName,
    String? relationshipStatus,
  }) = _UserSearchResult;

  factory UserSearchResult.fromJson(Map<String, dynamic> json) =>
      _$UserSearchResultFromJson(json);
}

@freezed
class NotificationCount with _$NotificationCount {
  const factory NotificationCount({
    @Default(0) int friendRequests,
    @Default(0) int challenges,
    @Default(0) int total,
  }) = _NotificationCount;

  factory NotificationCount.fromJson(Map<String, dynamic> json) =>
      _$NotificationCountFromJson(json);
}
