// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friend.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FriendInfo _$FriendInfoFromJson(Map<String, dynamic> json) {
  return _FriendInfo.fromJson(json);
}

/// @nodoc
mixin _$FriendInfo {
  String get friendshipId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  bool get isOnline => throw _privateConstructorUsedError;
  String get since => throw _privateConstructorUsedError;

  /// Serializes this FriendInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FriendInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FriendInfoCopyWith<FriendInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FriendInfoCopyWith<$Res> {
  factory $FriendInfoCopyWith(
    FriendInfo value,
    $Res Function(FriendInfo) then,
  ) = _$FriendInfoCopyWithImpl<$Res, FriendInfo>;
  @useResult
  $Res call({
    String friendshipId,
    String userId,
    String username,
    String? displayName,
    bool isOnline,
    String since,
  });
}

/// @nodoc
class _$FriendInfoCopyWithImpl<$Res, $Val extends FriendInfo>
    implements $FriendInfoCopyWith<$Res> {
  _$FriendInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FriendInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? friendshipId = null,
    Object? userId = null,
    Object? username = null,
    Object? displayName = freezed,
    Object? isOnline = null,
    Object? since = null,
  }) {
    return _then(
      _value.copyWith(
            friendshipId: null == friendshipId
                ? _value.friendshipId
                : friendshipId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            username: null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: freezed == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String?,
            isOnline: null == isOnline
                ? _value.isOnline
                : isOnline // ignore: cast_nullable_to_non_nullable
                      as bool,
            since: null == since
                ? _value.since
                : since // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FriendInfoImplCopyWith<$Res>
    implements $FriendInfoCopyWith<$Res> {
  factory _$$FriendInfoImplCopyWith(
    _$FriendInfoImpl value,
    $Res Function(_$FriendInfoImpl) then,
  ) = __$$FriendInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String friendshipId,
    String userId,
    String username,
    String? displayName,
    bool isOnline,
    String since,
  });
}

/// @nodoc
class __$$FriendInfoImplCopyWithImpl<$Res>
    extends _$FriendInfoCopyWithImpl<$Res, _$FriendInfoImpl>
    implements _$$FriendInfoImplCopyWith<$Res> {
  __$$FriendInfoImplCopyWithImpl(
    _$FriendInfoImpl _value,
    $Res Function(_$FriendInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FriendInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? friendshipId = null,
    Object? userId = null,
    Object? username = null,
    Object? displayName = freezed,
    Object? isOnline = null,
    Object? since = null,
  }) {
    return _then(
      _$FriendInfoImpl(
        friendshipId: null == friendshipId
            ? _value.friendshipId
            : friendshipId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: freezed == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String?,
        isOnline: null == isOnline
            ? _value.isOnline
            : isOnline // ignore: cast_nullable_to_non_nullable
                  as bool,
        since: null == since
            ? _value.since
            : since // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FriendInfoImpl implements _FriendInfo {
  const _$FriendInfoImpl({
    required this.friendshipId,
    required this.userId,
    required this.username,
    this.displayName,
    this.isOnline = false,
    required this.since,
  });

  factory _$FriendInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$FriendInfoImplFromJson(json);

  @override
  final String friendshipId;
  @override
  final String userId;
  @override
  final String username;
  @override
  final String? displayName;
  @override
  @JsonKey()
  final bool isOnline;
  @override
  final String since;

  @override
  String toString() {
    return 'FriendInfo(friendshipId: $friendshipId, userId: $userId, username: $username, displayName: $displayName, isOnline: $isOnline, since: $since)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FriendInfoImpl &&
            (identical(other.friendshipId, friendshipId) ||
                other.friendshipId == friendshipId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.isOnline, isOnline) ||
                other.isOnline == isOnline) &&
            (identical(other.since, since) || other.since == since));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    friendshipId,
    userId,
    username,
    displayName,
    isOnline,
    since,
  );

  /// Create a copy of FriendInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FriendInfoImplCopyWith<_$FriendInfoImpl> get copyWith =>
      __$$FriendInfoImplCopyWithImpl<_$FriendInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FriendInfoImplToJson(this);
  }
}

abstract class _FriendInfo implements FriendInfo {
  const factory _FriendInfo({
    required final String friendshipId,
    required final String userId,
    required final String username,
    final String? displayName,
    final bool isOnline,
    required final String since,
  }) = _$FriendInfoImpl;

  factory _FriendInfo.fromJson(Map<String, dynamic> json) =
      _$FriendInfoImpl.fromJson;

  @override
  String get friendshipId;
  @override
  String get userId;
  @override
  String get username;
  @override
  String? get displayName;
  @override
  bool get isOnline;
  @override
  String get since;

  /// Create a copy of FriendInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FriendInfoImplCopyWith<_$FriendInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FriendRequestInfo _$FriendRequestInfoFromJson(Map<String, dynamic> json) {
  return _FriendRequestInfo.fromJson(json);
}

/// @nodoc
mixin _$FriendRequestInfo {
  String get friendshipId => throw _privateConstructorUsedError;
  String get fromUserId => throw _privateConstructorUsedError;
  String get fromUsername => throw _privateConstructorUsedError;
  String? get fromDisplayName => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;

  /// Serializes this FriendRequestInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FriendRequestInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FriendRequestInfoCopyWith<FriendRequestInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FriendRequestInfoCopyWith<$Res> {
  factory $FriendRequestInfoCopyWith(
    FriendRequestInfo value,
    $Res Function(FriendRequestInfo) then,
  ) = _$FriendRequestInfoCopyWithImpl<$Res, FriendRequestInfo>;
  @useResult
  $Res call({
    String friendshipId,
    String fromUserId,
    String fromUsername,
    String? fromDisplayName,
    String createdAt,
  });
}

/// @nodoc
class _$FriendRequestInfoCopyWithImpl<$Res, $Val extends FriendRequestInfo>
    implements $FriendRequestInfoCopyWith<$Res> {
  _$FriendRequestInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FriendRequestInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? friendshipId = null,
    Object? fromUserId = null,
    Object? fromUsername = null,
    Object? fromDisplayName = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            friendshipId: null == friendshipId
                ? _value.friendshipId
                : friendshipId // ignore: cast_nullable_to_non_nullable
                      as String,
            fromUserId: null == fromUserId
                ? _value.fromUserId
                : fromUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            fromUsername: null == fromUsername
                ? _value.fromUsername
                : fromUsername // ignore: cast_nullable_to_non_nullable
                      as String,
            fromDisplayName: freezed == fromDisplayName
                ? _value.fromDisplayName
                : fromDisplayName // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FriendRequestInfoImplCopyWith<$Res>
    implements $FriendRequestInfoCopyWith<$Res> {
  factory _$$FriendRequestInfoImplCopyWith(
    _$FriendRequestInfoImpl value,
    $Res Function(_$FriendRequestInfoImpl) then,
  ) = __$$FriendRequestInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String friendshipId,
    String fromUserId,
    String fromUsername,
    String? fromDisplayName,
    String createdAt,
  });
}

/// @nodoc
class __$$FriendRequestInfoImplCopyWithImpl<$Res>
    extends _$FriendRequestInfoCopyWithImpl<$Res, _$FriendRequestInfoImpl>
    implements _$$FriendRequestInfoImplCopyWith<$Res> {
  __$$FriendRequestInfoImplCopyWithImpl(
    _$FriendRequestInfoImpl _value,
    $Res Function(_$FriendRequestInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FriendRequestInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? friendshipId = null,
    Object? fromUserId = null,
    Object? fromUsername = null,
    Object? fromDisplayName = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$FriendRequestInfoImpl(
        friendshipId: null == friendshipId
            ? _value.friendshipId
            : friendshipId // ignore: cast_nullable_to_non_nullable
                  as String,
        fromUserId: null == fromUserId
            ? _value.fromUserId
            : fromUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        fromUsername: null == fromUsername
            ? _value.fromUsername
            : fromUsername // ignore: cast_nullable_to_non_nullable
                  as String,
        fromDisplayName: freezed == fromDisplayName
            ? _value.fromDisplayName
            : fromDisplayName // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FriendRequestInfoImpl implements _FriendRequestInfo {
  const _$FriendRequestInfoImpl({
    required this.friendshipId,
    required this.fromUserId,
    required this.fromUsername,
    this.fromDisplayName,
    required this.createdAt,
  });

  factory _$FriendRequestInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$FriendRequestInfoImplFromJson(json);

  @override
  final String friendshipId;
  @override
  final String fromUserId;
  @override
  final String fromUsername;
  @override
  final String? fromDisplayName;
  @override
  final String createdAt;

  @override
  String toString() {
    return 'FriendRequestInfo(friendshipId: $friendshipId, fromUserId: $fromUserId, fromUsername: $fromUsername, fromDisplayName: $fromDisplayName, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FriendRequestInfoImpl &&
            (identical(other.friendshipId, friendshipId) ||
                other.friendshipId == friendshipId) &&
            (identical(other.fromUserId, fromUserId) ||
                other.fromUserId == fromUserId) &&
            (identical(other.fromUsername, fromUsername) ||
                other.fromUsername == fromUsername) &&
            (identical(other.fromDisplayName, fromDisplayName) ||
                other.fromDisplayName == fromDisplayName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    friendshipId,
    fromUserId,
    fromUsername,
    fromDisplayName,
    createdAt,
  );

  /// Create a copy of FriendRequestInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FriendRequestInfoImplCopyWith<_$FriendRequestInfoImpl> get copyWith =>
      __$$FriendRequestInfoImplCopyWithImpl<_$FriendRequestInfoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FriendRequestInfoImplToJson(this);
  }
}

abstract class _FriendRequestInfo implements FriendRequestInfo {
  const factory _FriendRequestInfo({
    required final String friendshipId,
    required final String fromUserId,
    required final String fromUsername,
    final String? fromDisplayName,
    required final String createdAt,
  }) = _$FriendRequestInfoImpl;

  factory _FriendRequestInfo.fromJson(Map<String, dynamic> json) =
      _$FriendRequestInfoImpl.fromJson;

  @override
  String get friendshipId;
  @override
  String get fromUserId;
  @override
  String get fromUsername;
  @override
  String? get fromDisplayName;
  @override
  String get createdAt;

  /// Create a copy of FriendRequestInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FriendRequestInfoImplCopyWith<_$FriendRequestInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserSearchResult _$UserSearchResultFromJson(Map<String, dynamic> json) {
  return _UserSearchResult.fromJson(json);
}

/// @nodoc
mixin _$UserSearchResult {
  String get userId => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  String? get relationshipStatus => throw _privateConstructorUsedError;

  /// Serializes this UserSearchResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserSearchResultCopyWith<UserSearchResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSearchResultCopyWith<$Res> {
  factory $UserSearchResultCopyWith(
    UserSearchResult value,
    $Res Function(UserSearchResult) then,
  ) = _$UserSearchResultCopyWithImpl<$Res, UserSearchResult>;
  @useResult
  $Res call({
    String userId,
    String username,
    String? displayName,
    String? relationshipStatus,
  });
}

/// @nodoc
class _$UserSearchResultCopyWithImpl<$Res, $Val extends UserSearchResult>
    implements $UserSearchResultCopyWith<$Res> {
  _$UserSearchResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? username = null,
    Object? displayName = freezed,
    Object? relationshipStatus = freezed,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            username: null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: freezed == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String?,
            relationshipStatus: freezed == relationshipStatus
                ? _value.relationshipStatus
                : relationshipStatus // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserSearchResultImplCopyWith<$Res>
    implements $UserSearchResultCopyWith<$Res> {
  factory _$$UserSearchResultImplCopyWith(
    _$UserSearchResultImpl value,
    $Res Function(_$UserSearchResultImpl) then,
  ) = __$$UserSearchResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String username,
    String? displayName,
    String? relationshipStatus,
  });
}

/// @nodoc
class __$$UserSearchResultImplCopyWithImpl<$Res>
    extends _$UserSearchResultCopyWithImpl<$Res, _$UserSearchResultImpl>
    implements _$$UserSearchResultImplCopyWith<$Res> {
  __$$UserSearchResultImplCopyWithImpl(
    _$UserSearchResultImpl _value,
    $Res Function(_$UserSearchResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? username = null,
    Object? displayName = freezed,
    Object? relationshipStatus = freezed,
  }) {
    return _then(
      _$UserSearchResultImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: freezed == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String?,
        relationshipStatus: freezed == relationshipStatus
            ? _value.relationshipStatus
            : relationshipStatus // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserSearchResultImpl implements _UserSearchResult {
  const _$UserSearchResultImpl({
    required this.userId,
    required this.username,
    this.displayName,
    this.relationshipStatus,
  });

  factory _$UserSearchResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserSearchResultImplFromJson(json);

  @override
  final String userId;
  @override
  final String username;
  @override
  final String? displayName;
  @override
  final String? relationshipStatus;

  @override
  String toString() {
    return 'UserSearchResult(userId: $userId, username: $username, displayName: $displayName, relationshipStatus: $relationshipStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSearchResultImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.relationshipStatus, relationshipStatus) ||
                other.relationshipStatus == relationshipStatus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    username,
    displayName,
    relationshipStatus,
  );

  /// Create a copy of UserSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSearchResultImplCopyWith<_$UserSearchResultImpl> get copyWith =>
      __$$UserSearchResultImplCopyWithImpl<_$UserSearchResultImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UserSearchResultImplToJson(this);
  }
}

abstract class _UserSearchResult implements UserSearchResult {
  const factory _UserSearchResult({
    required final String userId,
    required final String username,
    final String? displayName,
    final String? relationshipStatus,
  }) = _$UserSearchResultImpl;

  factory _UserSearchResult.fromJson(Map<String, dynamic> json) =
      _$UserSearchResultImpl.fromJson;

  @override
  String get userId;
  @override
  String get username;
  @override
  String? get displayName;
  @override
  String? get relationshipStatus;

  /// Create a copy of UserSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserSearchResultImplCopyWith<_$UserSearchResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NotificationCount _$NotificationCountFromJson(Map<String, dynamic> json) {
  return _NotificationCount.fromJson(json);
}

/// @nodoc
mixin _$NotificationCount {
  int get friendRequests => throw _privateConstructorUsedError;
  int get challenges => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;

  /// Serializes this NotificationCount to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NotificationCount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationCountCopyWith<NotificationCount> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationCountCopyWith<$Res> {
  factory $NotificationCountCopyWith(
    NotificationCount value,
    $Res Function(NotificationCount) then,
  ) = _$NotificationCountCopyWithImpl<$Res, NotificationCount>;
  @useResult
  $Res call({int friendRequests, int challenges, int total});
}

/// @nodoc
class _$NotificationCountCopyWithImpl<$Res, $Val extends NotificationCount>
    implements $NotificationCountCopyWith<$Res> {
  _$NotificationCountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationCount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? friendRequests = null,
    Object? challenges = null,
    Object? total = null,
  }) {
    return _then(
      _value.copyWith(
            friendRequests: null == friendRequests
                ? _value.friendRequests
                : friendRequests // ignore: cast_nullable_to_non_nullable
                      as int,
            challenges: null == challenges
                ? _value.challenges
                : challenges // ignore: cast_nullable_to_non_nullable
                      as int,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NotificationCountImplCopyWith<$Res>
    implements $NotificationCountCopyWith<$Res> {
  factory _$$NotificationCountImplCopyWith(
    _$NotificationCountImpl value,
    $Res Function(_$NotificationCountImpl) then,
  ) = __$$NotificationCountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int friendRequests, int challenges, int total});
}

/// @nodoc
class __$$NotificationCountImplCopyWithImpl<$Res>
    extends _$NotificationCountCopyWithImpl<$Res, _$NotificationCountImpl>
    implements _$$NotificationCountImplCopyWith<$Res> {
  __$$NotificationCountImplCopyWithImpl(
    _$NotificationCountImpl _value,
    $Res Function(_$NotificationCountImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationCount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? friendRequests = null,
    Object? challenges = null,
    Object? total = null,
  }) {
    return _then(
      _$NotificationCountImpl(
        friendRequests: null == friendRequests
            ? _value.friendRequests
            : friendRequests // ignore: cast_nullable_to_non_nullable
                  as int,
        challenges: null == challenges
            ? _value.challenges
            : challenges // ignore: cast_nullable_to_non_nullable
                  as int,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationCountImpl implements _NotificationCount {
  const _$NotificationCountImpl({
    this.friendRequests = 0,
    this.challenges = 0,
    this.total = 0,
  });

  factory _$NotificationCountImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationCountImplFromJson(json);

  @override
  @JsonKey()
  final int friendRequests;
  @override
  @JsonKey()
  final int challenges;
  @override
  @JsonKey()
  final int total;

  @override
  String toString() {
    return 'NotificationCount(friendRequests: $friendRequests, challenges: $challenges, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationCountImpl &&
            (identical(other.friendRequests, friendRequests) ||
                other.friendRequests == friendRequests) &&
            (identical(other.challenges, challenges) ||
                other.challenges == challenges) &&
            (identical(other.total, total) || other.total == total));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, friendRequests, challenges, total);

  /// Create a copy of NotificationCount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationCountImplCopyWith<_$NotificationCountImpl> get copyWith =>
      __$$NotificationCountImplCopyWithImpl<_$NotificationCountImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationCountImplToJson(this);
  }
}

abstract class _NotificationCount implements NotificationCount {
  const factory _NotificationCount({
    final int friendRequests,
    final int challenges,
    final int total,
  }) = _$NotificationCountImpl;

  factory _NotificationCount.fromJson(Map<String, dynamic> json) =
      _$NotificationCountImpl.fromJson;

  @override
  int get friendRequests;
  @override
  int get challenges;
  @override
  int get total;

  /// Create a copy of NotificationCount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationCountImplCopyWith<_$NotificationCountImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
