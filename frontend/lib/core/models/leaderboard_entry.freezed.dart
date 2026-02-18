// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leaderboard_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LeaderboardEntry _$LeaderboardEntryFromJson(Map<String, dynamic> json) {
  return _LeaderboardEntry.fromJson(json);
}

/// @nodoc
mixin _$LeaderboardEntry {
  String get playerId => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  int get gamesPlayed => throw _privateConstructorUsedError;
  int get gamesWon => throw _privateConstructorUsedError;
  int get gamesLost => throw _privateConstructorUsedError;
  double get winRate => throw _privateConstructorUsedError;
  double get averageScore => throw _privateConstructorUsedError;
  int get highestGameScore => throw _privateConstructorUsedError;
  int get currentWinStreak => throw _privateConstructorUsedError;
  int get longestWinStreak => throw _privateConstructorUsedError;

  /// Serializes this LeaderboardEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LeaderboardEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LeaderboardEntryCopyWith<LeaderboardEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LeaderboardEntryCopyWith<$Res> {
  factory $LeaderboardEntryCopyWith(
    LeaderboardEntry value,
    $Res Function(LeaderboardEntry) then,
  ) = _$LeaderboardEntryCopyWithImpl<$Res, LeaderboardEntry>;
  @useResult
  $Res call({
    String playerId,
    String displayName,
    int gamesPlayed,
    int gamesWon,
    int gamesLost,
    double winRate,
    double averageScore,
    int highestGameScore,
    int currentWinStreak,
    int longestWinStreak,
  });
}

/// @nodoc
class _$LeaderboardEntryCopyWithImpl<$Res, $Val extends LeaderboardEntry>
    implements $LeaderboardEntryCopyWith<$Res> {
  _$LeaderboardEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LeaderboardEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? displayName = null,
    Object? gamesPlayed = null,
    Object? gamesWon = null,
    Object? gamesLost = null,
    Object? winRate = null,
    Object? averageScore = null,
    Object? highestGameScore = null,
    Object? currentWinStreak = null,
    Object? longestWinStreak = null,
  }) {
    return _then(
      _value.copyWith(
            playerId: null == playerId
                ? _value.playerId
                : playerId // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
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
            highestGameScore: null == highestGameScore
                ? _value.highestGameScore
                : highestGameScore // ignore: cast_nullable_to_non_nullable
                      as int,
            currentWinStreak: null == currentWinStreak
                ? _value.currentWinStreak
                : currentWinStreak // ignore: cast_nullable_to_non_nullable
                      as int,
            longestWinStreak: null == longestWinStreak
                ? _value.longestWinStreak
                : longestWinStreak // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LeaderboardEntryImplCopyWith<$Res>
    implements $LeaderboardEntryCopyWith<$Res> {
  factory _$$LeaderboardEntryImplCopyWith(
    _$LeaderboardEntryImpl value,
    $Res Function(_$LeaderboardEntryImpl) then,
  ) = __$$LeaderboardEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String playerId,
    String displayName,
    int gamesPlayed,
    int gamesWon,
    int gamesLost,
    double winRate,
    double averageScore,
    int highestGameScore,
    int currentWinStreak,
    int longestWinStreak,
  });
}

/// @nodoc
class __$$LeaderboardEntryImplCopyWithImpl<$Res>
    extends _$LeaderboardEntryCopyWithImpl<$Res, _$LeaderboardEntryImpl>
    implements _$$LeaderboardEntryImplCopyWith<$Res> {
  __$$LeaderboardEntryImplCopyWithImpl(
    _$LeaderboardEntryImpl _value,
    $Res Function(_$LeaderboardEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LeaderboardEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? displayName = null,
    Object? gamesPlayed = null,
    Object? gamesWon = null,
    Object? gamesLost = null,
    Object? winRate = null,
    Object? averageScore = null,
    Object? highestGameScore = null,
    Object? currentWinStreak = null,
    Object? longestWinStreak = null,
  }) {
    return _then(
      _$LeaderboardEntryImpl(
        playerId: null == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
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
        highestGameScore: null == highestGameScore
            ? _value.highestGameScore
            : highestGameScore // ignore: cast_nullable_to_non_nullable
                  as int,
        currentWinStreak: null == currentWinStreak
            ? _value.currentWinStreak
            : currentWinStreak // ignore: cast_nullable_to_non_nullable
                  as int,
        longestWinStreak: null == longestWinStreak
            ? _value.longestWinStreak
            : longestWinStreak // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LeaderboardEntryImpl implements _LeaderboardEntry {
  const _$LeaderboardEntryImpl({
    required this.playerId,
    required this.displayName,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.winRate = 0.0,
    this.averageScore = 0.0,
    this.highestGameScore = 0,
    this.currentWinStreak = 0,
    this.longestWinStreak = 0,
  });

  factory _$LeaderboardEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$LeaderboardEntryImplFromJson(json);

  @override
  final String playerId;
  @override
  final String displayName;
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
  @JsonKey()
  final int highestGameScore;
  @override
  @JsonKey()
  final int currentWinStreak;
  @override
  @JsonKey()
  final int longestWinStreak;

  @override
  String toString() {
    return 'LeaderboardEntry(playerId: $playerId, displayName: $displayName, gamesPlayed: $gamesPlayed, gamesWon: $gamesWon, gamesLost: $gamesLost, winRate: $winRate, averageScore: $averageScore, highestGameScore: $highestGameScore, currentWinStreak: $currentWinStreak, longestWinStreak: $longestWinStreak)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeaderboardEntryImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.gamesPlayed, gamesPlayed) ||
                other.gamesPlayed == gamesPlayed) &&
            (identical(other.gamesWon, gamesWon) ||
                other.gamesWon == gamesWon) &&
            (identical(other.gamesLost, gamesLost) ||
                other.gamesLost == gamesLost) &&
            (identical(other.winRate, winRate) || other.winRate == winRate) &&
            (identical(other.averageScore, averageScore) ||
                other.averageScore == averageScore) &&
            (identical(other.highestGameScore, highestGameScore) ||
                other.highestGameScore == highestGameScore) &&
            (identical(other.currentWinStreak, currentWinStreak) ||
                other.currentWinStreak == currentWinStreak) &&
            (identical(other.longestWinStreak, longestWinStreak) ||
                other.longestWinStreak == longestWinStreak));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    playerId,
    displayName,
    gamesPlayed,
    gamesWon,
    gamesLost,
    winRate,
    averageScore,
    highestGameScore,
    currentWinStreak,
    longestWinStreak,
  );

  /// Create a copy of LeaderboardEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LeaderboardEntryImplCopyWith<_$LeaderboardEntryImpl> get copyWith =>
      __$$LeaderboardEntryImplCopyWithImpl<_$LeaderboardEntryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$LeaderboardEntryImplToJson(this);
  }
}

abstract class _LeaderboardEntry implements LeaderboardEntry {
  const factory _LeaderboardEntry({
    required final String playerId,
    required final String displayName,
    final int gamesPlayed,
    final int gamesWon,
    final int gamesLost,
    final double winRate,
    final double averageScore,
    final int highestGameScore,
    final int currentWinStreak,
    final int longestWinStreak,
  }) = _$LeaderboardEntryImpl;

  factory _LeaderboardEntry.fromJson(Map<String, dynamic> json) =
      _$LeaderboardEntryImpl.fromJson;

  @override
  String get playerId;
  @override
  String get displayName;
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
  @override
  int get highestGameScore;
  @override
  int get currentWinStreak;
  @override
  int get longestWinStreak;

  /// Create a copy of LeaderboardEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LeaderboardEntryImplCopyWith<_$LeaderboardEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
