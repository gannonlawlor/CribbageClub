// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'score_breakdown.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ScoreBreakdown _$ScoreBreakdownFromJson(Map<String, dynamic> json) {
  return _ScoreBreakdown.fromJson(json);
}

/// @nodoc
mixin _$ScoreBreakdown {
  int get fifteens => throw _privateConstructorUsedError;
  int get pairs => throw _privateConstructorUsedError;
  int get runs => throw _privateConstructorUsedError;
  int get flushes => throw _privateConstructorUsedError;
  int get nobs => throw _privateConstructorUsedError;
  int get totalScore => throw _privateConstructorUsedError;

  /// Serializes this ScoreBreakdown to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScoreBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScoreBreakdownCopyWith<ScoreBreakdown> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScoreBreakdownCopyWith<$Res> {
  factory $ScoreBreakdownCopyWith(
    ScoreBreakdown value,
    $Res Function(ScoreBreakdown) then,
  ) = _$ScoreBreakdownCopyWithImpl<$Res, ScoreBreakdown>;
  @useResult
  $Res call({
    int fifteens,
    int pairs,
    int runs,
    int flushes,
    int nobs,
    int totalScore,
  });
}

/// @nodoc
class _$ScoreBreakdownCopyWithImpl<$Res, $Val extends ScoreBreakdown>
    implements $ScoreBreakdownCopyWith<$Res> {
  _$ScoreBreakdownCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScoreBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fifteens = null,
    Object? pairs = null,
    Object? runs = null,
    Object? flushes = null,
    Object? nobs = null,
    Object? totalScore = null,
  }) {
    return _then(
      _value.copyWith(
            fifteens: null == fifteens
                ? _value.fifteens
                : fifteens // ignore: cast_nullable_to_non_nullable
                      as int,
            pairs: null == pairs
                ? _value.pairs
                : pairs // ignore: cast_nullable_to_non_nullable
                      as int,
            runs: null == runs
                ? _value.runs
                : runs // ignore: cast_nullable_to_non_nullable
                      as int,
            flushes: null == flushes
                ? _value.flushes
                : flushes // ignore: cast_nullable_to_non_nullable
                      as int,
            nobs: null == nobs
                ? _value.nobs
                : nobs // ignore: cast_nullable_to_non_nullable
                      as int,
            totalScore: null == totalScore
                ? _value.totalScore
                : totalScore // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ScoreBreakdownImplCopyWith<$Res>
    implements $ScoreBreakdownCopyWith<$Res> {
  factory _$$ScoreBreakdownImplCopyWith(
    _$ScoreBreakdownImpl value,
    $Res Function(_$ScoreBreakdownImpl) then,
  ) = __$$ScoreBreakdownImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int fifteens,
    int pairs,
    int runs,
    int flushes,
    int nobs,
    int totalScore,
  });
}

/// @nodoc
class __$$ScoreBreakdownImplCopyWithImpl<$Res>
    extends _$ScoreBreakdownCopyWithImpl<$Res, _$ScoreBreakdownImpl>
    implements _$$ScoreBreakdownImplCopyWith<$Res> {
  __$$ScoreBreakdownImplCopyWithImpl(
    _$ScoreBreakdownImpl _value,
    $Res Function(_$ScoreBreakdownImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ScoreBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fifteens = null,
    Object? pairs = null,
    Object? runs = null,
    Object? flushes = null,
    Object? nobs = null,
    Object? totalScore = null,
  }) {
    return _then(
      _$ScoreBreakdownImpl(
        fifteens: null == fifteens
            ? _value.fifteens
            : fifteens // ignore: cast_nullable_to_non_nullable
                  as int,
        pairs: null == pairs
            ? _value.pairs
            : pairs // ignore: cast_nullable_to_non_nullable
                  as int,
        runs: null == runs
            ? _value.runs
            : runs // ignore: cast_nullable_to_non_nullable
                  as int,
        flushes: null == flushes
            ? _value.flushes
            : flushes // ignore: cast_nullable_to_non_nullable
                  as int,
        nobs: null == nobs
            ? _value.nobs
            : nobs // ignore: cast_nullable_to_non_nullable
                  as int,
        totalScore: null == totalScore
            ? _value.totalScore
            : totalScore // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ScoreBreakdownImpl implements _ScoreBreakdown {
  const _$ScoreBreakdownImpl({
    this.fifteens = 0,
    this.pairs = 0,
    this.runs = 0,
    this.flushes = 0,
    this.nobs = 0,
    this.totalScore = 0,
  });

  factory _$ScoreBreakdownImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScoreBreakdownImplFromJson(json);

  @override
  @JsonKey()
  final int fifteens;
  @override
  @JsonKey()
  final int pairs;
  @override
  @JsonKey()
  final int runs;
  @override
  @JsonKey()
  final int flushes;
  @override
  @JsonKey()
  final int nobs;
  @override
  @JsonKey()
  final int totalScore;

  @override
  String toString() {
    return 'ScoreBreakdown(fifteens: $fifteens, pairs: $pairs, runs: $runs, flushes: $flushes, nobs: $nobs, totalScore: $totalScore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScoreBreakdownImpl &&
            (identical(other.fifteens, fifteens) ||
                other.fifteens == fifteens) &&
            (identical(other.pairs, pairs) || other.pairs == pairs) &&
            (identical(other.runs, runs) || other.runs == runs) &&
            (identical(other.flushes, flushes) || other.flushes == flushes) &&
            (identical(other.nobs, nobs) || other.nobs == nobs) &&
            (identical(other.totalScore, totalScore) ||
                other.totalScore == totalScore));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    fifteens,
    pairs,
    runs,
    flushes,
    nobs,
    totalScore,
  );

  /// Create a copy of ScoreBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScoreBreakdownImplCopyWith<_$ScoreBreakdownImpl> get copyWith =>
      __$$ScoreBreakdownImplCopyWithImpl<_$ScoreBreakdownImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ScoreBreakdownImplToJson(this);
  }
}

abstract class _ScoreBreakdown implements ScoreBreakdown {
  const factory _ScoreBreakdown({
    final int fifteens,
    final int pairs,
    final int runs,
    final int flushes,
    final int nobs,
    final int totalScore,
  }) = _$ScoreBreakdownImpl;

  factory _ScoreBreakdown.fromJson(Map<String, dynamic> json) =
      _$ScoreBreakdownImpl.fromJson;

  @override
  int get fifteens;
  @override
  int get pairs;
  @override
  int get runs;
  @override
  int get flushes;
  @override
  int get nobs;
  @override
  int get totalScore;

  /// Create a copy of ScoreBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScoreBreakdownImplCopyWith<_$ScoreBreakdownImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
