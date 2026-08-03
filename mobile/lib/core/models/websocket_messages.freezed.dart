// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'websocket_messages.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GameStateUpdateMessage _$GameStateUpdateMessageFromJson(
  Map<String, dynamic> json,
) {
  return _GameStateUpdateMessage.fromJson(json);
}

/// @nodoc
mixin _$GameStateUpdateMessage {
  String get gameId => throw _privateConstructorUsedError;
  GameState get gameState => throw _privateConstructorUsedError;
  String? get turnStartedAt => throw _privateConstructorUsedError;
  int get turnTimeLimitMs => throw _privateConstructorUsedError;
  int get player1TimeBankMs => throw _privateConstructorUsedError;
  int get player2TimeBankMs => throw _privateConstructorUsedError;
  bool get isTimed => throw _privateConstructorUsedError;
  int? get timestamp => throw _privateConstructorUsedError;

  /// Which filtered view [gameState] is: "PLAYER" (our own view, from the
  /// user queue) or "SPECTATOR" (all hands hidden, from the game topic).
  /// Null on servers that predate the field.
  String? get view => throw _privateConstructorUsedError;

  /// Serializes this GameStateUpdateMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameStateUpdateMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameStateUpdateMessageCopyWith<GameStateUpdateMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameStateUpdateMessageCopyWith<$Res> {
  factory $GameStateUpdateMessageCopyWith(
    GameStateUpdateMessage value,
    $Res Function(GameStateUpdateMessage) then,
  ) = _$GameStateUpdateMessageCopyWithImpl<$Res, GameStateUpdateMessage>;
  @useResult
  $Res call({
    String gameId,
    GameState gameState,
    String? turnStartedAt,
    int turnTimeLimitMs,
    int player1TimeBankMs,
    int player2TimeBankMs,
    bool isTimed,
    int? timestamp,
    String? view,
  });

  $GameStateCopyWith<$Res> get gameState;
}

/// @nodoc
class _$GameStateUpdateMessageCopyWithImpl<
  $Res,
  $Val extends GameStateUpdateMessage
>
    implements $GameStateUpdateMessageCopyWith<$Res> {
  _$GameStateUpdateMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameStateUpdateMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? gameState = null,
    Object? turnStartedAt = freezed,
    Object? turnTimeLimitMs = null,
    Object? player1TimeBankMs = null,
    Object? player2TimeBankMs = null,
    Object? isTimed = null,
    Object? timestamp = freezed,
    Object? view = freezed,
  }) {
    return _then(
      _value.copyWith(
            gameId: null == gameId
                ? _value.gameId
                : gameId // ignore: cast_nullable_to_non_nullable
                      as String,
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
            player1TimeBankMs: null == player1TimeBankMs
                ? _value.player1TimeBankMs
                : player1TimeBankMs // ignore: cast_nullable_to_non_nullable
                      as int,
            player2TimeBankMs: null == player2TimeBankMs
                ? _value.player2TimeBankMs
                : player2TimeBankMs // ignore: cast_nullable_to_non_nullable
                      as int,
            isTimed: null == isTimed
                ? _value.isTimed
                : isTimed // ignore: cast_nullable_to_non_nullable
                      as bool,
            timestamp: freezed == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as int?,
            view: freezed == view
                ? _value.view
                : view // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of GameStateUpdateMessage
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
abstract class _$$GameStateUpdateMessageImplCopyWith<$Res>
    implements $GameStateUpdateMessageCopyWith<$Res> {
  factory _$$GameStateUpdateMessageImplCopyWith(
    _$GameStateUpdateMessageImpl value,
    $Res Function(_$GameStateUpdateMessageImpl) then,
  ) = __$$GameStateUpdateMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String gameId,
    GameState gameState,
    String? turnStartedAt,
    int turnTimeLimitMs,
    int player1TimeBankMs,
    int player2TimeBankMs,
    bool isTimed,
    int? timestamp,
    String? view,
  });

  @override
  $GameStateCopyWith<$Res> get gameState;
}

/// @nodoc
class __$$GameStateUpdateMessageImplCopyWithImpl<$Res>
    extends
        _$GameStateUpdateMessageCopyWithImpl<$Res, _$GameStateUpdateMessageImpl>
    implements _$$GameStateUpdateMessageImplCopyWith<$Res> {
  __$$GameStateUpdateMessageImplCopyWithImpl(
    _$GameStateUpdateMessageImpl _value,
    $Res Function(_$GameStateUpdateMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameStateUpdateMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? gameState = null,
    Object? turnStartedAt = freezed,
    Object? turnTimeLimitMs = null,
    Object? player1TimeBankMs = null,
    Object? player2TimeBankMs = null,
    Object? isTimed = null,
    Object? timestamp = freezed,
    Object? view = freezed,
  }) {
    return _then(
      _$GameStateUpdateMessageImpl(
        gameId: null == gameId
            ? _value.gameId
            : gameId // ignore: cast_nullable_to_non_nullable
                  as String,
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
        player1TimeBankMs: null == player1TimeBankMs
            ? _value.player1TimeBankMs
            : player1TimeBankMs // ignore: cast_nullable_to_non_nullable
                  as int,
        player2TimeBankMs: null == player2TimeBankMs
            ? _value.player2TimeBankMs
            : player2TimeBankMs // ignore: cast_nullable_to_non_nullable
                  as int,
        isTimed: null == isTimed
            ? _value.isTimed
            : isTimed // ignore: cast_nullable_to_non_nullable
                  as bool,
        timestamp: freezed == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as int?,
        view: freezed == view
            ? _value.view
            : view // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GameStateUpdateMessageImpl implements _GameStateUpdateMessage {
  const _$GameStateUpdateMessageImpl({
    required this.gameId,
    required this.gameState,
    this.turnStartedAt,
    this.turnTimeLimitMs = 30000,
    this.player1TimeBankMs = 120000,
    this.player2TimeBankMs = 120000,
    this.isTimed = false,
    this.timestamp,
    this.view,
  });

  factory _$GameStateUpdateMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameStateUpdateMessageImplFromJson(json);

  @override
  final String gameId;
  @override
  final GameState gameState;
  @override
  final String? turnStartedAt;
  @override
  @JsonKey()
  final int turnTimeLimitMs;
  @override
  @JsonKey()
  final int player1TimeBankMs;
  @override
  @JsonKey()
  final int player2TimeBankMs;
  @override
  @JsonKey()
  final bool isTimed;
  @override
  final int? timestamp;

  /// Which filtered view [gameState] is: "PLAYER" (our own view, from the
  /// user queue) or "SPECTATOR" (all hands hidden, from the game topic).
  /// Null on servers that predate the field.
  @override
  final String? view;

  @override
  String toString() {
    return 'GameStateUpdateMessage(gameId: $gameId, gameState: $gameState, turnStartedAt: $turnStartedAt, turnTimeLimitMs: $turnTimeLimitMs, player1TimeBankMs: $player1TimeBankMs, player2TimeBankMs: $player2TimeBankMs, isTimed: $isTimed, timestamp: $timestamp, view: $view)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameStateUpdateMessageImpl &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.gameState, gameState) ||
                other.gameState == gameState) &&
            (identical(other.turnStartedAt, turnStartedAt) ||
                other.turnStartedAt == turnStartedAt) &&
            (identical(other.turnTimeLimitMs, turnTimeLimitMs) ||
                other.turnTimeLimitMs == turnTimeLimitMs) &&
            (identical(other.player1TimeBankMs, player1TimeBankMs) ||
                other.player1TimeBankMs == player1TimeBankMs) &&
            (identical(other.player2TimeBankMs, player2TimeBankMs) ||
                other.player2TimeBankMs == player2TimeBankMs) &&
            (identical(other.isTimed, isTimed) || other.isTimed == isTimed) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.view, view) || other.view == view));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    gameId,
    gameState,
    turnStartedAt,
    turnTimeLimitMs,
    player1TimeBankMs,
    player2TimeBankMs,
    isTimed,
    timestamp,
    view,
  );

  /// Create a copy of GameStateUpdateMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameStateUpdateMessageImplCopyWith<_$GameStateUpdateMessageImpl>
  get copyWith =>
      __$$GameStateUpdateMessageImplCopyWithImpl<_$GameStateUpdateMessageImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GameStateUpdateMessageImplToJson(this);
  }
}

abstract class _GameStateUpdateMessage implements GameStateUpdateMessage {
  const factory _GameStateUpdateMessage({
    required final String gameId,
    required final GameState gameState,
    final String? turnStartedAt,
    final int turnTimeLimitMs,
    final int player1TimeBankMs,
    final int player2TimeBankMs,
    final bool isTimed,
    final int? timestamp,
    final String? view,
  }) = _$GameStateUpdateMessageImpl;

  factory _GameStateUpdateMessage.fromJson(Map<String, dynamic> json) =
      _$GameStateUpdateMessageImpl.fromJson;

  @override
  String get gameId;
  @override
  GameState get gameState;
  @override
  String? get turnStartedAt;
  @override
  int get turnTimeLimitMs;
  @override
  int get player1TimeBankMs;
  @override
  int get player2TimeBankMs;
  @override
  bool get isTimed;
  @override
  int? get timestamp;

  /// Which filtered view [gameState] is: "PLAYER" (our own view, from the
  /// user queue) or "SPECTATOR" (all hands hidden, from the game topic).
  /// Null on servers that predate the field.
  @override
  String? get view;

  /// Create a copy of GameStateUpdateMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameStateUpdateMessageImplCopyWith<_$GameStateUpdateMessageImpl>
  get copyWith => throw _privateConstructorUsedError;
}

GameErrorMessage _$GameErrorMessageFromJson(Map<String, dynamic> json) {
  return _GameErrorMessage.fromJson(json);
}

/// @nodoc
mixin _$GameErrorMessage {
  String get gameId => throw _privateConstructorUsedError;
  String get error => throw _privateConstructorUsedError;
  int? get timestamp => throw _privateConstructorUsedError;

  /// Serializes this GameErrorMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameErrorMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameErrorMessageCopyWith<GameErrorMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameErrorMessageCopyWith<$Res> {
  factory $GameErrorMessageCopyWith(
    GameErrorMessage value,
    $Res Function(GameErrorMessage) then,
  ) = _$GameErrorMessageCopyWithImpl<$Res, GameErrorMessage>;
  @useResult
  $Res call({String gameId, String error, int? timestamp});
}

/// @nodoc
class _$GameErrorMessageCopyWithImpl<$Res, $Val extends GameErrorMessage>
    implements $GameErrorMessageCopyWith<$Res> {
  _$GameErrorMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameErrorMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? error = null,
    Object? timestamp = freezed,
  }) {
    return _then(
      _value.copyWith(
            gameId: null == gameId
                ? _value.gameId
                : gameId // ignore: cast_nullable_to_non_nullable
                      as String,
            error: null == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String,
            timestamp: freezed == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GameErrorMessageImplCopyWith<$Res>
    implements $GameErrorMessageCopyWith<$Res> {
  factory _$$GameErrorMessageImplCopyWith(
    _$GameErrorMessageImpl value,
    $Res Function(_$GameErrorMessageImpl) then,
  ) = __$$GameErrorMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String gameId, String error, int? timestamp});
}

/// @nodoc
class __$$GameErrorMessageImplCopyWithImpl<$Res>
    extends _$GameErrorMessageCopyWithImpl<$Res, _$GameErrorMessageImpl>
    implements _$$GameErrorMessageImplCopyWith<$Res> {
  __$$GameErrorMessageImplCopyWithImpl(
    _$GameErrorMessageImpl _value,
    $Res Function(_$GameErrorMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameErrorMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? error = null,
    Object? timestamp = freezed,
  }) {
    return _then(
      _$GameErrorMessageImpl(
        gameId: null == gameId
            ? _value.gameId
            : gameId // ignore: cast_nullable_to_non_nullable
                  as String,
        error: null == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: freezed == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GameErrorMessageImpl implements _GameErrorMessage {
  const _$GameErrorMessageImpl({
    required this.gameId,
    required this.error,
    this.timestamp,
  });

  factory _$GameErrorMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameErrorMessageImplFromJson(json);

  @override
  final String gameId;
  @override
  final String error;
  @override
  final int? timestamp;

  @override
  String toString() {
    return 'GameErrorMessage(gameId: $gameId, error: $error, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameErrorMessageImpl &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, gameId, error, timestamp);

  /// Create a copy of GameErrorMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameErrorMessageImplCopyWith<_$GameErrorMessageImpl> get copyWith =>
      __$$GameErrorMessageImplCopyWithImpl<_$GameErrorMessageImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GameErrorMessageImplToJson(this);
  }
}

abstract class _GameErrorMessage implements GameErrorMessage {
  const factory _GameErrorMessage({
    required final String gameId,
    required final String error,
    final int? timestamp,
  }) = _$GameErrorMessageImpl;

  factory _GameErrorMessage.fromJson(Map<String, dynamic> json) =
      _$GameErrorMessageImpl.fromJson;

  @override
  String get gameId;
  @override
  String get error;
  @override
  int? get timestamp;

  /// Create a copy of GameErrorMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameErrorMessageImplCopyWith<_$GameErrorMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
