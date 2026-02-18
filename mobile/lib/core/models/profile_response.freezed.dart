// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ProfileResponse _$ProfileResponseFromJson(Map<String, dynamic> json) {
  return _ProfileResponse.fromJson(json);
}

/// @nodoc
mixin _$ProfileResponse {
  String get userId => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  int? get avatarIndex => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String? get relationshipStatus => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  double get ratingDeviation => throw _privateConstructorUsedError;
  CategoryStats get overallStats => throw _privateConstructorUsedError;
  CategoryStats get aiStats => throw _privateConstructorUsedError;
  CategoryStats get humanStats => throw _privateConstructorUsedError;

  /// Serializes this ProfileResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProfileResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileResponseCopyWith<ProfileResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileResponseCopyWith<$Res> {
  factory $ProfileResponseCopyWith(
    ProfileResponse value,
    $Res Function(ProfileResponse) then,
  ) = _$ProfileResponseCopyWithImpl<$Res, ProfileResponse>;
  @useResult
  $Res call({
    String userId,
    String username,
    String? displayName,
    int? avatarIndex,
    String createdAt,
    String? relationshipStatus,
    double rating,
    double ratingDeviation,
    CategoryStats overallStats,
    CategoryStats aiStats,
    CategoryStats humanStats,
  });

  $CategoryStatsCopyWith<$Res> get overallStats;
  $CategoryStatsCopyWith<$Res> get aiStats;
  $CategoryStatsCopyWith<$Res> get humanStats;
}

/// @nodoc
class _$ProfileResponseCopyWithImpl<$Res, $Val extends ProfileResponse>
    implements $ProfileResponseCopyWith<$Res> {
  _$ProfileResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfileResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? username = null,
    Object? displayName = freezed,
    Object? avatarIndex = freezed,
    Object? createdAt = null,
    Object? relationshipStatus = freezed,
    Object? rating = null,
    Object? ratingDeviation = null,
    Object? overallStats = null,
    Object? aiStats = null,
    Object? humanStats = null,
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
            avatarIndex: freezed == avatarIndex
                ? _value.avatarIndex
                : avatarIndex // ignore: cast_nullable_to_non_nullable
                      as int?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
            relationshipStatus: freezed == relationshipStatus
                ? _value.relationshipStatus
                : relationshipStatus // ignore: cast_nullable_to_non_nullable
                      as String?,
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double,
            ratingDeviation: null == ratingDeviation
                ? _value.ratingDeviation
                : ratingDeviation // ignore: cast_nullable_to_non_nullable
                      as double,
            overallStats: null == overallStats
                ? _value.overallStats
                : overallStats // ignore: cast_nullable_to_non_nullable
                      as CategoryStats,
            aiStats: null == aiStats
                ? _value.aiStats
                : aiStats // ignore: cast_nullable_to_non_nullable
                      as CategoryStats,
            humanStats: null == humanStats
                ? _value.humanStats
                : humanStats // ignore: cast_nullable_to_non_nullable
                      as CategoryStats,
          )
          as $Val,
    );
  }

  /// Create a copy of ProfileResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CategoryStatsCopyWith<$Res> get overallStats {
    return $CategoryStatsCopyWith<$Res>(_value.overallStats, (value) {
      return _then(_value.copyWith(overallStats: value) as $Val);
    });
  }

  /// Create a copy of ProfileResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CategoryStatsCopyWith<$Res> get aiStats {
    return $CategoryStatsCopyWith<$Res>(_value.aiStats, (value) {
      return _then(_value.copyWith(aiStats: value) as $Val);
    });
  }

  /// Create a copy of ProfileResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CategoryStatsCopyWith<$Res> get humanStats {
    return $CategoryStatsCopyWith<$Res>(_value.humanStats, (value) {
      return _then(_value.copyWith(humanStats: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProfileResponseImplCopyWith<$Res>
    implements $ProfileResponseCopyWith<$Res> {
  factory _$$ProfileResponseImplCopyWith(
    _$ProfileResponseImpl value,
    $Res Function(_$ProfileResponseImpl) then,
  ) = __$$ProfileResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String username,
    String? displayName,
    int? avatarIndex,
    String createdAt,
    String? relationshipStatus,
    double rating,
    double ratingDeviation,
    CategoryStats overallStats,
    CategoryStats aiStats,
    CategoryStats humanStats,
  });

  @override
  $CategoryStatsCopyWith<$Res> get overallStats;
  @override
  $CategoryStatsCopyWith<$Res> get aiStats;
  @override
  $CategoryStatsCopyWith<$Res> get humanStats;
}

/// @nodoc
class __$$ProfileResponseImplCopyWithImpl<$Res>
    extends _$ProfileResponseCopyWithImpl<$Res, _$ProfileResponseImpl>
    implements _$$ProfileResponseImplCopyWith<$Res> {
  __$$ProfileResponseImplCopyWithImpl(
    _$ProfileResponseImpl _value,
    $Res Function(_$ProfileResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProfileResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? username = null,
    Object? displayName = freezed,
    Object? avatarIndex = freezed,
    Object? createdAt = null,
    Object? relationshipStatus = freezed,
    Object? rating = null,
    Object? ratingDeviation = null,
    Object? overallStats = null,
    Object? aiStats = null,
    Object? humanStats = null,
  }) {
    return _then(
      _$ProfileResponseImpl(
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
        avatarIndex: freezed == avatarIndex
            ? _value.avatarIndex
            : avatarIndex // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
        relationshipStatus: freezed == relationshipStatus
            ? _value.relationshipStatus
            : relationshipStatus // ignore: cast_nullable_to_non_nullable
                  as String?,
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double,
        ratingDeviation: null == ratingDeviation
            ? _value.ratingDeviation
            : ratingDeviation // ignore: cast_nullable_to_non_nullable
                  as double,
        overallStats: null == overallStats
            ? _value.overallStats
            : overallStats // ignore: cast_nullable_to_non_nullable
                  as CategoryStats,
        aiStats: null == aiStats
            ? _value.aiStats
            : aiStats // ignore: cast_nullable_to_non_nullable
                  as CategoryStats,
        humanStats: null == humanStats
            ? _value.humanStats
            : humanStats // ignore: cast_nullable_to_non_nullable
                  as CategoryStats,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfileResponseImpl implements _ProfileResponse {
  const _$ProfileResponseImpl({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarIndex,
    required this.createdAt,
    this.relationshipStatus,
    this.rating = 1500.0,
    this.ratingDeviation = 350.0,
    required this.overallStats,
    required this.aiStats,
    required this.humanStats,
  });

  factory _$ProfileResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfileResponseImplFromJson(json);

  @override
  final String userId;
  @override
  final String username;
  @override
  final String? displayName;
  @override
  final int? avatarIndex;
  @override
  final String createdAt;
  @override
  final String? relationshipStatus;
  @override
  @JsonKey()
  final double rating;
  @override
  @JsonKey()
  final double ratingDeviation;
  @override
  final CategoryStats overallStats;
  @override
  final CategoryStats aiStats;
  @override
  final CategoryStats humanStats;

  @override
  String toString() {
    return 'ProfileResponse(userId: $userId, username: $username, displayName: $displayName, avatarIndex: $avatarIndex, createdAt: $createdAt, relationshipStatus: $relationshipStatus, rating: $rating, ratingDeviation: $ratingDeviation, overallStats: $overallStats, aiStats: $aiStats, humanStats: $humanStats)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileResponseImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarIndex, avatarIndex) ||
                other.avatarIndex == avatarIndex) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.relationshipStatus, relationshipStatus) ||
                other.relationshipStatus == relationshipStatus) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.ratingDeviation, ratingDeviation) ||
                other.ratingDeviation == ratingDeviation) &&
            (identical(other.overallStats, overallStats) ||
                other.overallStats == overallStats) &&
            (identical(other.aiStats, aiStats) || other.aiStats == aiStats) &&
            (identical(other.humanStats, humanStats) ||
                other.humanStats == humanStats));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    username,
    displayName,
    avatarIndex,
    createdAt,
    relationshipStatus,
    rating,
    ratingDeviation,
    overallStats,
    aiStats,
    humanStats,
  );

  /// Create a copy of ProfileResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileResponseImplCopyWith<_$ProfileResponseImpl> get copyWith =>
      __$$ProfileResponseImplCopyWithImpl<_$ProfileResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfileResponseImplToJson(this);
  }
}

abstract class _ProfileResponse implements ProfileResponse {
  const factory _ProfileResponse({
    required final String userId,
    required final String username,
    final String? displayName,
    final int? avatarIndex,
    required final String createdAt,
    final String? relationshipStatus,
    final double rating,
    final double ratingDeviation,
    required final CategoryStats overallStats,
    required final CategoryStats aiStats,
    required final CategoryStats humanStats,
  }) = _$ProfileResponseImpl;

  factory _ProfileResponse.fromJson(Map<String, dynamic> json) =
      _$ProfileResponseImpl.fromJson;

  @override
  String get userId;
  @override
  String get username;
  @override
  String? get displayName;
  @override
  int? get avatarIndex;
  @override
  String get createdAt;
  @override
  String? get relationshipStatus;
  @override
  double get rating;
  @override
  double get ratingDeviation;
  @override
  CategoryStats get overallStats;
  @override
  CategoryStats get aiStats;
  @override
  CategoryStats get humanStats;

  /// Create a copy of ProfileResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileResponseImplCopyWith<_$ProfileResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CategoryStats _$CategoryStatsFromJson(Map<String, dynamic> json) {
  return _CategoryStats.fromJson(json);
}

/// @nodoc
mixin _$CategoryStats {
  int get gamesPlayed => throw _privateConstructorUsedError;
  int get gamesWon => throw _privateConstructorUsedError;
  int get gamesLost => throw _privateConstructorUsedError;
  double get winRate => throw _privateConstructorUsedError;
  double get averageScore => throw _privateConstructorUsedError;

  /// Serializes this CategoryStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CategoryStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategoryStatsCopyWith<CategoryStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryStatsCopyWith<$Res> {
  factory $CategoryStatsCopyWith(
    CategoryStats value,
    $Res Function(CategoryStats) then,
  ) = _$CategoryStatsCopyWithImpl<$Res, CategoryStats>;
  @useResult
  $Res call({
    int gamesPlayed,
    int gamesWon,
    int gamesLost,
    double winRate,
    double averageScore,
  });
}

/// @nodoc
class _$CategoryStatsCopyWithImpl<$Res, $Val extends CategoryStats>
    implements $CategoryStatsCopyWith<$Res> {
  _$CategoryStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CategoryStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gamesPlayed = null,
    Object? gamesWon = null,
    Object? gamesLost = null,
    Object? winRate = null,
    Object? averageScore = null,
  }) {
    return _then(
      _value.copyWith(
            gamesPlayed: null == gamesPlayed
                ? _value.gamesPlayed
                : gamesPlayed // ignore: cast_nullable_to_non_nullable
                      as int,
            gamesWon: null == gamesWon
                ? _value.gamesWon
                : gamesWon // ignore: cast_nullable_to_non_nullable
                      as int,
            gamesLost: null == gamesLost
                ? _value.gamesLost
                : gamesLost // ignore: cast_nullable_to_non_nullable
                      as int,
            winRate: null == winRate
                ? _value.winRate
                : winRate // ignore: cast_nullable_to_non_nullable
                      as double,
            averageScore: null == averageScore
                ? _value.averageScore
                : averageScore // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CategoryStatsImplCopyWith<$Res>
    implements $CategoryStatsCopyWith<$Res> {
  factory _$$CategoryStatsImplCopyWith(
    _$CategoryStatsImpl value,
    $Res Function(_$CategoryStatsImpl) then,
  ) = __$$CategoryStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int gamesPlayed,
    int gamesWon,
    int gamesLost,
    double winRate,
    double averageScore,
  });
}

/// @nodoc
class __$$CategoryStatsImplCopyWithImpl<$Res>
    extends _$CategoryStatsCopyWithImpl<$Res, _$CategoryStatsImpl>
    implements _$$CategoryStatsImplCopyWith<$Res> {
  __$$CategoryStatsImplCopyWithImpl(
    _$CategoryStatsImpl _value,
    $Res Function(_$CategoryStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CategoryStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gamesPlayed = null,
    Object? gamesWon = null,
    Object? gamesLost = null,
    Object? winRate = null,
    Object? averageScore = null,
  }) {
    return _then(
      _$CategoryStatsImpl(
        gamesPlayed: null == gamesPlayed
            ? _value.gamesPlayed
            : gamesPlayed // ignore: cast_nullable_to_non_nullable
                  as int,
        gamesWon: null == gamesWon
            ? _value.gamesWon
            : gamesWon // ignore: cast_nullable_to_non_nullable
                  as int,
        gamesLost: null == gamesLost
            ? _value.gamesLost
            : gamesLost // ignore: cast_nullable_to_non_nullable
                  as int,
        winRate: null == winRate
            ? _value.winRate
            : winRate // ignore: cast_nullable_to_non_nullable
                  as double,
        averageScore: null == averageScore
            ? _value.averageScore
            : averageScore // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CategoryStatsImpl implements _CategoryStats {
  const _$CategoryStatsImpl({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.winRate = 0.0,
    this.averageScore = 0.0,
  });

  factory _$CategoryStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoryStatsImplFromJson(json);

  @override
  @JsonKey()
  final int gamesPlayed;
  @override
  @JsonKey()
  final int gamesWon;
  @override
  @JsonKey()
  final int gamesLost;
  @override
  @JsonKey()
  final double winRate;
  @override
  @JsonKey()
  final double averageScore;

  @override
  String toString() {
    return 'CategoryStats(gamesPlayed: $gamesPlayed, gamesWon: $gamesWon, gamesLost: $gamesLost, winRate: $winRate, averageScore: $averageScore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryStatsImpl &&
            (identical(other.gamesPlayed, gamesPlayed) ||
                other.gamesPlayed == gamesPlayed) &&
            (identical(other.gamesWon, gamesWon) ||
                other.gamesWon == gamesWon) &&
            (identical(other.gamesLost, gamesLost) ||
                other.gamesLost == gamesLost) &&
            (identical(other.winRate, winRate) || other.winRate == winRate) &&
            (identical(other.averageScore, averageScore) ||
                other.averageScore == averageScore));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    gamesPlayed,
    gamesWon,
    gamesLost,
    winRate,
    averageScore,
  );

  /// Create a copy of CategoryStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryStatsImplCopyWith<_$CategoryStatsImpl> get copyWith =>
      __$$CategoryStatsImplCopyWithImpl<_$CategoryStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoryStatsImplToJson(this);
  }
}

abstract class _CategoryStats implements CategoryStats {
  const factory _CategoryStats({
    final int gamesPlayed,
    final int gamesWon,
    final int gamesLost,
    final double winRate,
    final double averageScore,
  }) = _$CategoryStatsImpl;

  factory _CategoryStats.fromJson(Map<String, dynamic> json) =
      _$CategoryStatsImpl.fromJson;

  @override
  int get gamesPlayed;
  @override
  int get gamesWon;
  @override
  int get gamesLost;
  @override
  double get winRate;
  @override
  double get averageScore;

  /// Create a copy of CategoryStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategoryStatsImplCopyWith<_$CategoryStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
