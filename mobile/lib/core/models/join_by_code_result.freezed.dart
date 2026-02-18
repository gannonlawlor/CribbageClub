// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'join_by_code_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

JoinByCodeResult _$JoinByCodeResultFromJson(Map<String, dynamic> json) {
  return _JoinByCodeResult.fromJson(json);
}

/// @nodoc
mixin _$JoinByCodeResult {
  Lobby get lobby => throw _privateConstructorUsedError;
  GameState? get gameState => throw _privateConstructorUsedError;

  /// Serializes this JoinByCodeResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JoinByCodeResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JoinByCodeResultCopyWith<JoinByCodeResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JoinByCodeResultCopyWith<$Res> {
  factory $JoinByCodeResultCopyWith(
    JoinByCodeResult value,
    $Res Function(JoinByCodeResult) then,
  ) = _$JoinByCodeResultCopyWithImpl<$Res, JoinByCodeResult>;
  @useResult
  $Res call({Lobby lobby, GameState? gameState});

  $LobbyCopyWith<$Res> get lobby;
  $GameStateCopyWith<$Res>? get gameState;
}

/// @nodoc
class _$JoinByCodeResultCopyWithImpl<$Res, $Val extends JoinByCodeResult>
    implements $JoinByCodeResultCopyWith<$Res> {
  _$JoinByCodeResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JoinByCodeResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? lobby = null, Object? gameState = freezed}) {
    return _then(
      _value.copyWith(
            lobby: null == lobby
                ? _value.lobby
                : lobby // ignore: cast_nullable_to_non_nullable
                      as Lobby,
            gameState: freezed == gameState
                ? _value.gameState
                : gameState // ignore: cast_nullable_to_non_nullable
                      as GameState?,
          )
          as $Val,
    );
  }

  /// Create a copy of JoinByCodeResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LobbyCopyWith<$Res> get lobby {
    return $LobbyCopyWith<$Res>(_value.lobby, (value) {
      return _then(_value.copyWith(lobby: value) as $Val);
    });
  }

  /// Create a copy of JoinByCodeResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GameStateCopyWith<$Res>? get gameState {
    if (_value.gameState == null) {
      return null;
    }

    return $GameStateCopyWith<$Res>(_value.gameState!, (value) {
      return _then(_value.copyWith(gameState: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$JoinByCodeResultImplCopyWith<$Res>
    implements $JoinByCodeResultCopyWith<$Res> {
  factory _$$JoinByCodeResultImplCopyWith(
    _$JoinByCodeResultImpl value,
    $Res Function(_$JoinByCodeResultImpl) then,
  ) = __$$JoinByCodeResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Lobby lobby, GameState? gameState});

  @override
  $LobbyCopyWith<$Res> get lobby;
  @override
  $GameStateCopyWith<$Res>? get gameState;
}

/// @nodoc
class __$$JoinByCodeResultImplCopyWithImpl<$Res>
    extends _$JoinByCodeResultCopyWithImpl<$Res, _$JoinByCodeResultImpl>
    implements _$$JoinByCodeResultImplCopyWith<$Res> {
  __$$JoinByCodeResultImplCopyWithImpl(
    _$JoinByCodeResultImpl _value,
    $Res Function(_$JoinByCodeResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of JoinByCodeResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? lobby = null, Object? gameState = freezed}) {
    return _then(
      _$JoinByCodeResultImpl(
        lobby: null == lobby
            ? _value.lobby
            : lobby // ignore: cast_nullable_to_non_nullable
                  as Lobby,
        gameState: freezed == gameState
            ? _value.gameState
            : gameState // ignore: cast_nullable_to_non_nullable
                  as GameState?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$JoinByCodeResultImpl implements _JoinByCodeResult {
  const _$JoinByCodeResultImpl({required this.lobby, this.gameState});

  factory _$JoinByCodeResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$JoinByCodeResultImplFromJson(json);

  @override
  final Lobby lobby;
  @override
  final GameState? gameState;

  @override
  String toString() {
    return 'JoinByCodeResult(lobby: $lobby, gameState: $gameState)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JoinByCodeResultImpl &&
            (identical(other.lobby, lobby) || other.lobby == lobby) &&
            (identical(other.gameState, gameState) ||
                other.gameState == gameState));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, lobby, gameState);

  /// Create a copy of JoinByCodeResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JoinByCodeResultImplCopyWith<_$JoinByCodeResultImpl> get copyWith =>
      __$$JoinByCodeResultImplCopyWithImpl<_$JoinByCodeResultImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$JoinByCodeResultImplToJson(this);
  }
}

abstract class _JoinByCodeResult implements JoinByCodeResult {
  const factory _JoinByCodeResult({
    required final Lobby lobby,
    final GameState? gameState,
  }) = _$JoinByCodeResultImpl;

  factory _JoinByCodeResult.fromJson(Map<String, dynamic> json) =
      _$JoinByCodeResultImpl.fromJson;

  @override
  Lobby get lobby;
  @override
  GameState? get gameState;

  /// Create a copy of JoinByCodeResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JoinByCodeResultImplCopyWith<_$JoinByCodeResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
