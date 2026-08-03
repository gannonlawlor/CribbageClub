// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'achievement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AchievementStatus _$AchievementStatusFromJson(Map<String, dynamic> json) {
  return _AchievementStatus.fromJson(json);
}

/// @nodoc
mixin _$AchievementStatus {
  String get key => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  AchievementTier get tier => throw _privateConstructorUsedError;
  int? get target => throw _privateConstructorUsedError;
  int? get progress => throw _privateConstructorUsedError;
  bool get unlocked => throw _privateConstructorUsedError;
  String? get unlockedAt => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this AchievementStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AchievementStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AchievementStatusCopyWith<AchievementStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AchievementStatusCopyWith<$Res> {
  factory $AchievementStatusCopyWith(
    AchievementStatus value,
    $Res Function(AchievementStatus) then,
  ) = _$AchievementStatusCopyWithImpl<$Res, AchievementStatus>;
  @useResult
  $Res call({
    String key,
    String name,
    String description,
    AchievementTier tier,
    int? target,
    int? progress,
    bool unlocked,
    String? unlockedAt,
    int sortOrder,
  });
}

/// @nodoc
class _$AchievementStatusCopyWithImpl<$Res, $Val extends AchievementStatus>
    implements $AchievementStatusCopyWith<$Res> {
  _$AchievementStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AchievementStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? name = null,
    Object? description = null,
    Object? tier = null,
    Object? target = freezed,
    Object? progress = freezed,
    Object? unlocked = null,
    Object? unlockedAt = freezed,
    Object? sortOrder = null,
  }) {
    return _then(
      _value.copyWith(
            key: null == key
                ? _value.key
                : key // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            tier: null == tier
                ? _value.tier
                : tier // ignore: cast_nullable_to_non_nullable
                      as AchievementTier,
            target: freezed == target
                ? _value.target
                : target // ignore: cast_nullable_to_non_nullable
                      as int?,
            progress: freezed == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                      as int?,
            unlocked: null == unlocked
                ? _value.unlocked
                : unlocked // ignore: cast_nullable_to_non_nullable
                      as bool,
            unlockedAt: freezed == unlockedAt
                ? _value.unlockedAt
                : unlockedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AchievementStatusImplCopyWith<$Res>
    implements $AchievementStatusCopyWith<$Res> {
  factory _$$AchievementStatusImplCopyWith(
    _$AchievementStatusImpl value,
    $Res Function(_$AchievementStatusImpl) then,
  ) = __$$AchievementStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String key,
    String name,
    String description,
    AchievementTier tier,
    int? target,
    int? progress,
    bool unlocked,
    String? unlockedAt,
    int sortOrder,
  });
}

/// @nodoc
class __$$AchievementStatusImplCopyWithImpl<$Res>
    extends _$AchievementStatusCopyWithImpl<$Res, _$AchievementStatusImpl>
    implements _$$AchievementStatusImplCopyWith<$Res> {
  __$$AchievementStatusImplCopyWithImpl(
    _$AchievementStatusImpl _value,
    $Res Function(_$AchievementStatusImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AchievementStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? name = null,
    Object? description = null,
    Object? tier = null,
    Object? target = freezed,
    Object? progress = freezed,
    Object? unlocked = null,
    Object? unlockedAt = freezed,
    Object? sortOrder = null,
  }) {
    return _then(
      _$AchievementStatusImpl(
        key: null == key
            ? _value.key
            : key // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        tier: null == tier
            ? _value.tier
            : tier // ignore: cast_nullable_to_non_nullable
                  as AchievementTier,
        target: freezed == target
            ? _value.target
            : target // ignore: cast_nullable_to_non_nullable
                  as int?,
        progress: freezed == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as int?,
        unlocked: null == unlocked
            ? _value.unlocked
            : unlocked // ignore: cast_nullable_to_non_nullable
                  as bool,
        unlockedAt: freezed == unlockedAt
            ? _value.unlockedAt
            : unlockedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AchievementStatusImpl implements _AchievementStatus {
  const _$AchievementStatusImpl({
    required this.key,
    required this.name,
    required this.description,
    required this.tier,
    this.target,
    this.progress,
    this.unlocked = false,
    this.unlockedAt,
    this.sortOrder = 0,
  });

  factory _$AchievementStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$AchievementStatusImplFromJson(json);

  @override
  final String key;
  @override
  final String name;
  @override
  final String description;
  @override
  final AchievementTier tier;
  @override
  final int? target;
  @override
  final int? progress;
  @override
  @JsonKey()
  final bool unlocked;
  @override
  final String? unlockedAt;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'AchievementStatus(key: $key, name: $name, description: $description, tier: $tier, target: $target, progress: $progress, unlocked: $unlocked, unlockedAt: $unlockedAt, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AchievementStatusImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.tier, tier) || other.tier == tier) &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.unlocked, unlocked) ||
                other.unlocked == unlocked) &&
            (identical(other.unlockedAt, unlockedAt) ||
                other.unlockedAt == unlockedAt) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    key,
    name,
    description,
    tier,
    target,
    progress,
    unlocked,
    unlockedAt,
    sortOrder,
  );

  /// Create a copy of AchievementStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AchievementStatusImplCopyWith<_$AchievementStatusImpl> get copyWith =>
      __$$AchievementStatusImplCopyWithImpl<_$AchievementStatusImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AchievementStatusImplToJson(this);
  }
}

abstract class _AchievementStatus implements AchievementStatus {
  const factory _AchievementStatus({
    required final String key,
    required final String name,
    required final String description,
    required final AchievementTier tier,
    final int? target,
    final int? progress,
    final bool unlocked,
    final String? unlockedAt,
    final int sortOrder,
  }) = _$AchievementStatusImpl;

  factory _AchievementStatus.fromJson(Map<String, dynamic> json) =
      _$AchievementStatusImpl.fromJson;

  @override
  String get key;
  @override
  String get name;
  @override
  String get description;
  @override
  AchievementTier get tier;
  @override
  int? get target;
  @override
  int? get progress;
  @override
  bool get unlocked;
  @override
  String? get unlockedAt;
  @override
  int get sortOrder;

  /// Create a copy of AchievementStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AchievementStatusImplCopyWith<_$AchievementStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AchievementsResponse _$AchievementsResponseFromJson(Map<String, dynamic> json) {
  return _AchievementsResponse.fromJson(json);
}

/// @nodoc
mixin _$AchievementsResponse {
  List<AchievementStatus> get achievements =>
      throw _privateConstructorUsedError;
  int get unlockedCount => throw _privateConstructorUsedError;
  int get totalCount => throw _privateConstructorUsedError;

  /// Serializes this AchievementsResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AchievementsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AchievementsResponseCopyWith<AchievementsResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AchievementsResponseCopyWith<$Res> {
  factory $AchievementsResponseCopyWith(
    AchievementsResponse value,
    $Res Function(AchievementsResponse) then,
  ) = _$AchievementsResponseCopyWithImpl<$Res, AchievementsResponse>;
  @useResult
  $Res call({
    List<AchievementStatus> achievements,
    int unlockedCount,
    int totalCount,
  });
}

/// @nodoc
class _$AchievementsResponseCopyWithImpl<
  $Res,
  $Val extends AchievementsResponse
>
    implements $AchievementsResponseCopyWith<$Res> {
  _$AchievementsResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AchievementsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? achievements = null,
    Object? unlockedCount = null,
    Object? totalCount = null,
  }) {
    return _then(
      _value.copyWith(
            achievements: null == achievements
                ? _value.achievements
                : achievements // ignore: cast_nullable_to_non_nullable
                      as List<AchievementStatus>,
            unlockedCount: null == unlockedCount
                ? _value.unlockedCount
                : unlockedCount // ignore: cast_nullable_to_non_nullable
                      as int,
            totalCount: null == totalCount
                ? _value.totalCount
                : totalCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AchievementsResponseImplCopyWith<$Res>
    implements $AchievementsResponseCopyWith<$Res> {
  factory _$$AchievementsResponseImplCopyWith(
    _$AchievementsResponseImpl value,
    $Res Function(_$AchievementsResponseImpl) then,
  ) = __$$AchievementsResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<AchievementStatus> achievements,
    int unlockedCount,
    int totalCount,
  });
}

/// @nodoc
class __$$AchievementsResponseImplCopyWithImpl<$Res>
    extends _$AchievementsResponseCopyWithImpl<$Res, _$AchievementsResponseImpl>
    implements _$$AchievementsResponseImplCopyWith<$Res> {
  __$$AchievementsResponseImplCopyWithImpl(
    _$AchievementsResponseImpl _value,
    $Res Function(_$AchievementsResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AchievementsResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? achievements = null,
    Object? unlockedCount = null,
    Object? totalCount = null,
  }) {
    return _then(
      _$AchievementsResponseImpl(
        achievements: null == achievements
            ? _value._achievements
            : achievements // ignore: cast_nullable_to_non_nullable
                  as List<AchievementStatus>,
        unlockedCount: null == unlockedCount
            ? _value.unlockedCount
            : unlockedCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalCount: null == totalCount
            ? _value.totalCount
            : totalCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AchievementsResponseImpl implements _AchievementsResponse {
  const _$AchievementsResponseImpl({
    required final List<AchievementStatus> achievements,
    required this.unlockedCount,
    required this.totalCount,
  }) : _achievements = achievements;

  factory _$AchievementsResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AchievementsResponseImplFromJson(json);

  final List<AchievementStatus> _achievements;
  @override
  List<AchievementStatus> get achievements {
    if (_achievements is EqualUnmodifiableListView) return _achievements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_achievements);
  }

  @override
  final int unlockedCount;
  @override
  final int totalCount;

  @override
  String toString() {
    return 'AchievementsResponse(achievements: $achievements, unlockedCount: $unlockedCount, totalCount: $totalCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AchievementsResponseImpl &&
            const DeepCollectionEquality().equals(
              other._achievements,
              _achievements,
            ) &&
            (identical(other.unlockedCount, unlockedCount) ||
                other.unlockedCount == unlockedCount) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_achievements),
    unlockedCount,
    totalCount,
  );

  /// Create a copy of AchievementsResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AchievementsResponseImplCopyWith<_$AchievementsResponseImpl>
  get copyWith =>
      __$$AchievementsResponseImplCopyWithImpl<_$AchievementsResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AchievementsResponseImplToJson(this);
  }
}

abstract class _AchievementsResponse implements AchievementsResponse {
  const factory _AchievementsResponse({
    required final List<AchievementStatus> achievements,
    required final int unlockedCount,
    required final int totalCount,
  }) = _$AchievementsResponseImpl;

  factory _AchievementsResponse.fromJson(Map<String, dynamic> json) =
      _$AchievementsResponseImpl.fromJson;

  @override
  List<AchievementStatus> get achievements;
  @override
  int get unlockedCount;
  @override
  int get totalCount;

  /// Create a copy of AchievementsResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AchievementsResponseImplCopyWith<_$AchievementsResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}
