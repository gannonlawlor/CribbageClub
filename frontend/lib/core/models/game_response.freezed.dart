// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GameResponse _$GameResponseFromJson(Map<String, dynamic> json) {
  return _GameResponse.fromJson(json);
}

/// @nodoc
mixin _$GameResponse {
  GameState get gameState => throw _privateConstructorUsedError;
  String? get turnStartedAt => throw _privateConstructorUsedError;
  int get turnTimeLimitMs => throw _privateConstructorUsedError;
  int get myTimeBankMs => throw _privateConstructorUsedError;
  int get opponentTimeBankMs => throw _privateConstructorUsedError;
  bool get isTimed => throw _privateConstructorUsedError;

  /// Serializes this GameResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameResponseCopyWith<GameResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameResponseCopyWith<$Res> {
  factory $GameResponseCopyWith(
    GameResponse value,
    $Res Function(GameResponse) then,
  ) = _$GameResponseCopyWithImpl<$Res, GameResponse>;
  @useResult
  $Res call({
    GameState gameState,
    String? turnStartedAt,
    int turnTimeLimitMs,
    int myTimeBankMs,
    int opponentTimeBankMs,
    bool isTimed,
  });

  $GameStateCopyWith<$Res> get gameState;
}

/// @nodoc
class _$GameResponseCopyWithImpl<$Res, $Val extends GameResponse>
    implements $GameResponseCopyWith<$Res> {
  _$GameResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameState = null,
    Object? turnStartedAt = freezed,
    Object? turnTimeLimitMs = null,
    Object? myTimeBankMs = null,
    Object? opponentTimeBankMs = null,
    Object? isTimed = null,
  }) {
    return _then(
      _value.copyWith(
            gameState: null == gameState
                ? _value.gameState
                : gameState // ignore: cast_nullable_to_non_nullable
                      as GameState,
            turnStartedAt: freezed == turnStartedAt
                ? _value.turnStartedAt
                : turnStartedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            turnTimeLimitMs: null == turnTimeLimitMs
                ? _value.turnTimeLimitMs
                : turnTimeLimitMs // ignore: cast_nullable_to_non_nullable
                      as int,
            myTimeBankMs: null == myTimeBankMs
                ? _value.myTimeBankMs
                : myTimeBankMs // ignore: cast_nullable_to_non_nullable
                      as int,
            opponentTimeBankMs: null == opponentTimeBankMs
                ? _value.opponentTimeBankMs
                : opponentTimeBankMs // ignore: cast_nullable_to_non_nullable
                      as int,
            isTimed: null == isTimed
                ? _value.isTimed
                : isTimed // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of GameResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GameStateCopyWith<$Res> get gameState {
    return $GameStateCopyWith<$Res>(_value.gameState, (value) {
      return _then(_value.copyWith(gameState: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GameResponseImplCopyWith<$Res>
    implements $GameResponseCopyWith<$Res> {
  factory _$$GameResponseImplCopyWith(
    _$GameResponseImpl value,
    $Res Function(_$GameResponseImpl) then,
  ) = __$$GameResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    GameState gameState,
    String? turnStartedAt,
    int turnTimeLimitMs,
    int myTimeBankMs,
    int opponentTimeBankMs,
    bool isTimed,
  });

  @override
  $GameStateCopyWith<$Res> get gameState;
}

/// @nodoc
class __$$GameResponseImplCopyWithImpl<$Res>
    extends _$GameResponseCopyWithImpl<$Res, _$GameResponseImpl>
    implements _$$GameResponseImplCopyWith<$Res> {
  __$$GameResponseImplCopyWithImpl(
    _$GameResponseImpl _value,
    $Res Function(_$GameResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameState = null,
    Object? turnStartedAt = freezed,
    Object? turnTimeLimitMs = null,
    Object? myTimeBankMs = null,
    Object? opponentTimeBankMs = null,
    Object? isTimed = null,
  }) {
    return _then(
      _$GameResponseImpl(
        gameState: null == gameState
            ? _value.gameState
            : gameState // ignore: cast_nullable_to_non_nullable
                  as GameState,
        turnStartedAt: freezed == turnStartedAt
            ? _value.turnStartedAt
            : turnStartedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        turnTimeLimitMs: null == turnTimeLimitMs
            ? _value.turnTimeLimitMs
            : turnTimeLimitMs // ignore: cast_nullable_to_non_nullable
                  as int,
        myTimeBankMs: null == myTimeBankMs
            ? _value.myTimeBankMs
            : myTimeBankMs // ignore: cast_nullable_to_non_nullable
                  as int,
        opponentTimeBankMs: null == opponentTimeBankMs
            ? _value.opponentTimeBankMs
            : opponentTimeBankMs // ignore: cast_nullable_to_non_nullable
                  as int,
        isTimed: null == isTimed
            ? _value.isTimed
            : isTimed // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GameResponseImpl implements _GameResponse {
  const _$GameResponseImpl({
    required this.gameState,
    this.turnStartedAt,
    this.turnTimeLimitMs = 30000,
    this.myTimeBankMs = 120000,
    this.opponentTimeBankMs = 120000,
    this.isTimed = false,
  });

  factory _$GameResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameResponseImplFromJson(json);

  @override
  final GameState gameState;
  @override
  final String? turnStartedAt;
  @override
  @JsonKey()
  final int turnTimeLimitMs;
  @override
  @JsonKey()
  final int myTimeBankMs;
  @override
  @JsonKey()
  final int opponentTimeBankMs;
  @override
  @JsonKey()
  final bool isTimed;

  @override
  String toString() {
    return 'GameResponse(gameState: $gameState, turnStartedAt: $turnStartedAt, turnTimeLimitMs: $turnTimeLimitMs, myTimeBankMs: $myTimeBankMs, opponentTimeBankMs: $opponentTimeBankMs, isTimed: $isTimed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameResponseImpl &&
            (identical(other.gameState, gameState) ||
                other.gameState == gameState) &&
            (identical(other.turnStartedAt, turnStartedAt) ||
                other.turnStartedAt == turnStartedAt) &&
            (identical(other.turnTimeLimitMs, turnTimeLimitMs) ||
                other.turnTimeLimitMs == turnTimeLimitMs) &&
            (identical(other.myTimeBankMs, myTimeBankMs) ||
                other.myTimeBankMs == myTimeBankMs) &&
            (identical(other.opponentTimeBankMs, opponentTimeBankMs) ||
                other.opponentTimeBankMs == opponentTimeBankMs) &&
            (identical(other.isTimed, isTimed) || other.isTimed == isTimed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    gameState,
    turnStartedAt,
    turnTimeLimitMs,
    myTimeBankMs,
    opponentTimeBankMs,
    isTimed,
  );

  /// Create a copy of GameResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameResponseImplCopyWith<_$GameResponseImpl> get copyWith =>
      __$$GameResponseImplCopyWithImpl<_$GameResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameResponseImplToJson(this);
  }
}

abstract class _GameResponse implements GameResponse {
  const factory _GameResponse({
    required final GameState gameState,
    final String? turnStartedAt,
    final int turnTimeLimitMs,
    final int myTimeBankMs,
    final int opponentTimeBankMs,
    final bool isTimed,
  }) = _$GameResponseImpl;

  factory _GameResponse.fromJson(Map<String, dynamic> json) =
      _$GameResponseImpl.fromJson;

  @override
  GameState get gameState;
  @override
  String? get turnStartedAt;
  @override
  int get turnTimeLimitMs;
  @override
  int get myTimeBankMs;
  @override
  int get opponentTimeBankMs;
  @override
  bool get isTimed;

  /// Create a copy of GameResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameResponseImplCopyWith<_$GameResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
