// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'local_game_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LocalGameRecord _$LocalGameRecordFromJson(Map<String, dynamic> json) {
  return _LocalGameRecord.fromJson(json);
}

/// @nodoc
mixin _$LocalGameRecord {
  String get gameId => throw _privateConstructorUsedError;
  String get playerName => throw _privateConstructorUsedError;
  String get opponentName => throw _privateConstructorUsedError;
  int get playerScore => throw _privateConstructorUsedError;
  int get opponentScore => throw _privateConstructorUsedError;
  bool get isWin => throw _privateConstructorUsedError;
  String get difficulty => throw _privateConstructorUsedError;
  DateTime get completedAt => throw _privateConstructorUsedError;

  /// Serializes this LocalGameRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LocalGameRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LocalGameRecordCopyWith<LocalGameRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocalGameRecordCopyWith<$Res> {
  factory $LocalGameRecordCopyWith(
    LocalGameRecord value,
    $Res Function(LocalGameRecord) then,
  ) = _$LocalGameRecordCopyWithImpl<$Res, LocalGameRecord>;
  @useResult
  $Res call({
    String gameId,
    String playerName,
    String opponentName,
    int playerScore,
    int opponentScore,
    bool isWin,
    String difficulty,
    DateTime completedAt,
  });
}

/// @nodoc
class _$LocalGameRecordCopyWithImpl<$Res, $Val extends LocalGameRecord>
    implements $LocalGameRecordCopyWith<$Res> {
  _$LocalGameRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LocalGameRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? playerName = null,
    Object? opponentName = null,
    Object? playerScore = null,
    Object? opponentScore = null,
    Object? isWin = null,
    Object? difficulty = null,
    Object? completedAt = null,
  }) {
    return _then(
      _value.copyWith(
            gameId: null == gameId
                ? _value.gameId
                : gameId // ignore: cast_nullable_to_non_nullable
                      as String,
            playerName: null == playerName
                ? _value.playerName
                : playerName // ignore: cast_nullable_to_non_nullable
                      as String,
            opponentName: null == opponentName
                ? _value.opponentName
                : opponentName // ignore: cast_nullable_to_non_nullable
                      as String,
            playerScore: null == playerScore
                ? _value.playerScore
                : playerScore // ignore: cast_nullable_to_non_nullable
                      as int,
            opponentScore: null == opponentScore
                ? _value.opponentScore
                : opponentScore // ignore: cast_nullable_to_non_nullable
                      as int,
            isWin: null == isWin
                ? _value.isWin
                : isWin // ignore: cast_nullable_to_non_nullable
                      as bool,
            difficulty: null == difficulty
                ? _value.difficulty
                : difficulty // ignore: cast_nullable_to_non_nullable
                      as String,
            completedAt: null == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LocalGameRecordImplCopyWith<$Res>
    implements $LocalGameRecordCopyWith<$Res> {
  factory _$$LocalGameRecordImplCopyWith(
    _$LocalGameRecordImpl value,
    $Res Function(_$LocalGameRecordImpl) then,
  ) = __$$LocalGameRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String gameId,
    String playerName,
    String opponentName,
    int playerScore,
    int opponentScore,
    bool isWin,
    String difficulty,
    DateTime completedAt,
  });
}

/// @nodoc
class __$$LocalGameRecordImplCopyWithImpl<$Res>
    extends _$LocalGameRecordCopyWithImpl<$Res, _$LocalGameRecordImpl>
    implements _$$LocalGameRecordImplCopyWith<$Res> {
  __$$LocalGameRecordImplCopyWithImpl(
    _$LocalGameRecordImpl _value,
    $Res Function(_$LocalGameRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocalGameRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? playerName = null,
    Object? opponentName = null,
    Object? playerScore = null,
    Object? opponentScore = null,
    Object? isWin = null,
    Object? difficulty = null,
    Object? completedAt = null,
  }) {
    return _then(
      _$LocalGameRecordImpl(
        gameId: null == gameId
            ? _value.gameId
            : gameId // ignore: cast_nullable_to_non_nullable
                  as String,
        playerName: null == playerName
            ? _value.playerName
            : playerName // ignore: cast_nullable_to_non_nullable
                  as String,
        opponentName: null == opponentName
            ? _value.opponentName
            : opponentName // ignore: cast_nullable_to_non_nullable
                  as String,
        playerScore: null == playerScore
            ? _value.playerScore
            : playerScore // ignore: cast_nullable_to_non_nullable
                  as int,
        opponentScore: null == opponentScore
            ? _value.opponentScore
            : opponentScore // ignore: cast_nullable_to_non_nullable
                  as int,
        isWin: null == isWin
            ? _value.isWin
            : isWin // ignore: cast_nullable_to_non_nullable
                  as bool,
        difficulty: null == difficulty
            ? _value.difficulty
            : difficulty // ignore: cast_nullable_to_non_nullable
                  as String,
        completedAt: null == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LocalGameRecordImpl implements _LocalGameRecord {
  const _$LocalGameRecordImpl({
    required this.gameId,
    required this.playerName,
    required this.opponentName,
    required this.playerScore,
    required this.opponentScore,
    required this.isWin,
    required this.difficulty,
    required this.completedAt,
  });

  factory _$LocalGameRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$LocalGameRecordImplFromJson(json);

  @override
  final String gameId;
  @override
  final String playerName;
  @override
  final String opponentName;
  @override
  final int playerScore;
  @override
  final int opponentScore;
  @override
  final bool isWin;
  @override
  final String difficulty;
  @override
  final DateTime completedAt;

  @override
  String toString() {
    return 'LocalGameRecord(gameId: $gameId, playerName: $playerName, opponentName: $opponentName, playerScore: $playerScore, opponentScore: $opponentScore, isWin: $isWin, difficulty: $difficulty, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocalGameRecordImpl &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.playerName, playerName) ||
                other.playerName == playerName) &&
            (identical(other.opponentName, opponentName) ||
                other.opponentName == opponentName) &&
            (identical(other.playerScore, playerScore) ||
                other.playerScore == playerScore) &&
            (identical(other.opponentScore, opponentScore) ||
                other.opponentScore == opponentScore) &&
            (identical(other.isWin, isWin) || other.isWin == isWin) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    gameId,
    playerName,
    opponentName,
    playerScore,
    opponentScore,
    isWin,
    difficulty,
    completedAt,
  );

  /// Create a copy of LocalGameRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocalGameRecordImplCopyWith<_$LocalGameRecordImpl> get copyWith =>
      __$$LocalGameRecordImplCopyWithImpl<_$LocalGameRecordImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$LocalGameRecordImplToJson(this);
  }
}

abstract class _LocalGameRecord implements LocalGameRecord {
  const factory _LocalGameRecord({
    required final String gameId,
    required final String playerName,
    required final String opponentName,
    required final int playerScore,
    required final int opponentScore,
    required final bool isWin,
    required final String difficulty,
    required final DateTime completedAt,
  }) = _$LocalGameRecordImpl;

  factory _LocalGameRecord.fromJson(Map<String, dynamic> json) =
      _$LocalGameRecordImpl.fromJson;

  @override
  String get gameId;
  @override
  String get playerName;
  @override
  String get opponentName;
  @override
  int get playerScore;
  @override
  int get opponentScore;
  @override
  bool get isWin;
  @override
  String get difficulty;
  @override
  DateTime get completedAt;

  /// Create a copy of LocalGameRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocalGameRecordImplCopyWith<_$LocalGameRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
