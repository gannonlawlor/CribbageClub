// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'head_to_head_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HeadToHeadResponse _$HeadToHeadResponseFromJson(Map<String, dynamic> json) {
  return _HeadToHeadResponse.fromJson(json);
}

/// @nodoc
mixin _$HeadToHeadResponse {
  int get gamesPlayed => throw _privateConstructorUsedError;
  int get viewerWins => throw _privateConstructorUsedError;
  int get opponentWins => throw _privateConstructorUsedError;
  List<HeadToHeadGame> get recentGames => throw _privateConstructorUsedError;

  /// Serializes this HeadToHeadResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HeadToHeadResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HeadToHeadResponseCopyWith<HeadToHeadResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HeadToHeadResponseCopyWith<$Res> {
  factory $HeadToHeadResponseCopyWith(
    HeadToHeadResponse value,
    $Res Function(HeadToHeadResponse) then,
  ) = _$HeadToHeadResponseCopyWithImpl<$Res, HeadToHeadResponse>;
  @useResult
  $Res call({
    int gamesPlayed,
    int viewerWins,
    int opponentWins,
    List<HeadToHeadGame> recentGames,
  });
}

/// @nodoc
class _$HeadToHeadResponseCopyWithImpl<$Res, $Val extends HeadToHeadResponse>
    implements $HeadToHeadResponseCopyWith<$Res> {
  _$HeadToHeadResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HeadToHeadResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gamesPlayed = null,
    Object? viewerWins = null,
    Object? opponentWins = null,
    Object? recentGames = null,
  }) {
    return _then(
      _value.copyWith(
            gamesPlayed: null == gamesPlayed
                ? _value.gamesPlayed
                : gamesPlayed // ignore: cast_nullable_to_non_nullable
                      as int,
            viewerWins: null == viewerWins
                ? _value.viewerWins
                : viewerWins // ignore: cast_nullable_to_non_nullable
                      as int,
            opponentWins: null == opponentWins
                ? _value.opponentWins
                : opponentWins // ignore: cast_nullable_to_non_nullable
                      as int,
            recentGames: null == recentGames
                ? _value.recentGames
                : recentGames // ignore: cast_nullable_to_non_nullable
                      as List<HeadToHeadGame>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HeadToHeadResponseImplCopyWith<$Res>
    implements $HeadToHeadResponseCopyWith<$Res> {
  factory _$$HeadToHeadResponseImplCopyWith(
    _$HeadToHeadResponseImpl value,
    $Res Function(_$HeadToHeadResponseImpl) then,
  ) = __$$HeadToHeadResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int gamesPlayed,
    int viewerWins,
    int opponentWins,
    List<HeadToHeadGame> recentGames,
  });
}

/// @nodoc
class __$$HeadToHeadResponseImplCopyWithImpl<$Res>
    extends _$HeadToHeadResponseCopyWithImpl<$Res, _$HeadToHeadResponseImpl>
    implements _$$HeadToHeadResponseImplCopyWith<$Res> {
  __$$HeadToHeadResponseImplCopyWithImpl(
    _$HeadToHeadResponseImpl _value,
    $Res Function(_$HeadToHeadResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HeadToHeadResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gamesPlayed = null,
    Object? viewerWins = null,
    Object? opponentWins = null,
    Object? recentGames = null,
  }) {
    return _then(
      _$HeadToHeadResponseImpl(
        gamesPlayed: null == gamesPlayed
            ? _value.gamesPlayed
            : gamesPlayed // ignore: cast_nullable_to_non_nullable
                  as int,
        viewerWins: null == viewerWins
            ? _value.viewerWins
            : viewerWins // ignore: cast_nullable_to_non_nullable
                  as int,
        opponentWins: null == opponentWins
            ? _value.opponentWins
            : opponentWins // ignore: cast_nullable_to_non_nullable
                  as int,
        recentGames: null == recentGames
            ? _value._recentGames
            : recentGames // ignore: cast_nullable_to_non_nullable
                  as List<HeadToHeadGame>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HeadToHeadResponseImpl implements _HeadToHeadResponse {
  const _$HeadToHeadResponseImpl({
    this.gamesPlayed = 0,
    this.viewerWins = 0,
    this.opponentWins = 0,
    final List<HeadToHeadGame> recentGames = const [],
  }) : _recentGames = recentGames;

  factory _$HeadToHeadResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$HeadToHeadResponseImplFromJson(json);

  @override
  @JsonKey()
  final int gamesPlayed;
  @override
  @JsonKey()
  final int viewerWins;
  @override
  @JsonKey()
  final int opponentWins;
  final List<HeadToHeadGame> _recentGames;
  @override
  @JsonKey()
  List<HeadToHeadGame> get recentGames {
    if (_recentGames is EqualUnmodifiableListView) return _recentGames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentGames);
  }

  @override
  String toString() {
    return 'HeadToHeadResponse(gamesPlayed: $gamesPlayed, viewerWins: $viewerWins, opponentWins: $opponentWins, recentGames: $recentGames)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HeadToHeadResponseImpl &&
            (identical(other.gamesPlayed, gamesPlayed) ||
                other.gamesPlayed == gamesPlayed) &&
            (identical(other.viewerWins, viewerWins) ||
                other.viewerWins == viewerWins) &&
            (identical(other.opponentWins, opponentWins) ||
                other.opponentWins == opponentWins) &&
            const DeepCollectionEquality().equals(
              other._recentGames,
              _recentGames,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    gamesPlayed,
    viewerWins,
    opponentWins,
    const DeepCollectionEquality().hash(_recentGames),
  );

  /// Create a copy of HeadToHeadResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HeadToHeadResponseImplCopyWith<_$HeadToHeadResponseImpl> get copyWith =>
      __$$HeadToHeadResponseImplCopyWithImpl<_$HeadToHeadResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$HeadToHeadResponseImplToJson(this);
  }
}

abstract class _HeadToHeadResponse implements HeadToHeadResponse {
  const factory _HeadToHeadResponse({
    final int gamesPlayed,
    final int viewerWins,
    final int opponentWins,
    final List<HeadToHeadGame> recentGames,
  }) = _$HeadToHeadResponseImpl;

  factory _HeadToHeadResponse.fromJson(Map<String, dynamic> json) =
      _$HeadToHeadResponseImpl.fromJson;

  @override
  int get gamesPlayed;
  @override
  int get viewerWins;
  @override
  int get opponentWins;
  @override
  List<HeadToHeadGame> get recentGames;

  /// Create a copy of HeadToHeadResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HeadToHeadResponseImplCopyWith<_$HeadToHeadResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HeadToHeadGame _$HeadToHeadGameFromJson(Map<String, dynamic> json) {
  return _HeadToHeadGame.fromJson(json);
}

/// @nodoc
mixin _$HeadToHeadGame {
  String get gameId => throw _privateConstructorUsedError;
  int get viewerScore => throw _privateConstructorUsedError;
  int get opponentScore => throw _privateConstructorUsedError;
  bool get viewerWon => throw _privateConstructorUsedError;
  String get completedAt => throw _privateConstructorUsedError;

  /// Serializes this HeadToHeadGame to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HeadToHeadGame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HeadToHeadGameCopyWith<HeadToHeadGame> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HeadToHeadGameCopyWith<$Res> {
  factory $HeadToHeadGameCopyWith(
    HeadToHeadGame value,
    $Res Function(HeadToHeadGame) then,
  ) = _$HeadToHeadGameCopyWithImpl<$Res, HeadToHeadGame>;
  @useResult
  $Res call({
    String gameId,
    int viewerScore,
    int opponentScore,
    bool viewerWon,
    String completedAt,
  });
}

/// @nodoc
class _$HeadToHeadGameCopyWithImpl<$Res, $Val extends HeadToHeadGame>
    implements $HeadToHeadGameCopyWith<$Res> {
  _$HeadToHeadGameCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HeadToHeadGame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? viewerScore = null,
    Object? opponentScore = null,
    Object? viewerWon = null,
    Object? completedAt = null,
  }) {
    return _then(
      _value.copyWith(
            gameId: null == gameId
                ? _value.gameId
                : gameId // ignore: cast_nullable_to_non_nullable
                      as String,
            viewerScore: null == viewerScore
                ? _value.viewerScore
                : viewerScore // ignore: cast_nullable_to_non_nullable
                      as int,
            opponentScore: null == opponentScore
                ? _value.opponentScore
                : opponentScore // ignore: cast_nullable_to_non_nullable
                      as int,
            viewerWon: null == viewerWon
                ? _value.viewerWon
                : viewerWon // ignore: cast_nullable_to_non_nullable
                      as bool,
            completedAt: null == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HeadToHeadGameImplCopyWith<$Res>
    implements $HeadToHeadGameCopyWith<$Res> {
  factory _$$HeadToHeadGameImplCopyWith(
    _$HeadToHeadGameImpl value,
    $Res Function(_$HeadToHeadGameImpl) then,
  ) = __$$HeadToHeadGameImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String gameId,
    int viewerScore,
    int opponentScore,
    bool viewerWon,
    String completedAt,
  });
}

/// @nodoc
class __$$HeadToHeadGameImplCopyWithImpl<$Res>
    extends _$HeadToHeadGameCopyWithImpl<$Res, _$HeadToHeadGameImpl>
    implements _$$HeadToHeadGameImplCopyWith<$Res> {
  __$$HeadToHeadGameImplCopyWithImpl(
    _$HeadToHeadGameImpl _value,
    $Res Function(_$HeadToHeadGameImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HeadToHeadGame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? viewerScore = null,
    Object? opponentScore = null,
    Object? viewerWon = null,
    Object? completedAt = null,
  }) {
    return _then(
      _$HeadToHeadGameImpl(
        gameId: null == gameId
            ? _value.gameId
            : gameId // ignore: cast_nullable_to_non_nullable
                  as String,
        viewerScore: null == viewerScore
            ? _value.viewerScore
            : viewerScore // ignore: cast_nullable_to_non_nullable
                  as int,
        opponentScore: null == opponentScore
            ? _value.opponentScore
            : opponentScore // ignore: cast_nullable_to_non_nullable
                  as int,
        viewerWon: null == viewerWon
            ? _value.viewerWon
            : viewerWon // ignore: cast_nullable_to_non_nullable
                  as bool,
        completedAt: null == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HeadToHeadGameImpl implements _HeadToHeadGame {
  const _$HeadToHeadGameImpl({
    required this.gameId,
    this.viewerScore = 0,
    this.opponentScore = 0,
    this.viewerWon = false,
    required this.completedAt,
  });

  factory _$HeadToHeadGameImpl.fromJson(Map<String, dynamic> json) =>
      _$$HeadToHeadGameImplFromJson(json);

  @override
  final String gameId;
  @override
  @JsonKey()
  final int viewerScore;
  @override
  @JsonKey()
  final int opponentScore;
  @override
  @JsonKey()
  final bool viewerWon;
  @override
  final String completedAt;

  @override
  String toString() {
    return 'HeadToHeadGame(gameId: $gameId, viewerScore: $viewerScore, opponentScore: $opponentScore, viewerWon: $viewerWon, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HeadToHeadGameImpl &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.viewerScore, viewerScore) ||
                other.viewerScore == viewerScore) &&
            (identical(other.opponentScore, opponentScore) ||
                other.opponentScore == opponentScore) &&
            (identical(other.viewerWon, viewerWon) ||
                other.viewerWon == viewerWon) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    gameId,
    viewerScore,
    opponentScore,
    viewerWon,
    completedAt,
  );

  /// Create a copy of HeadToHeadGame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HeadToHeadGameImplCopyWith<_$HeadToHeadGameImpl> get copyWith =>
      __$$HeadToHeadGameImplCopyWithImpl<_$HeadToHeadGameImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$HeadToHeadGameImplToJson(this);
  }
}

abstract class _HeadToHeadGame implements HeadToHeadGame {
  const factory _HeadToHeadGame({
    required final String gameId,
    final int viewerScore,
    final int opponentScore,
    final bool viewerWon,
    required final String completedAt,
  }) = _$HeadToHeadGameImpl;

  factory _HeadToHeadGame.fromJson(Map<String, dynamic> json) =
      _$HeadToHeadGameImpl.fromJson;

  @override
  String get gameId;
  @override
  int get viewerScore;
  @override
  int get opponentScore;
  @override
  bool get viewerWon;
  @override
  String get completedAt;

  /// Create a copy of HeadToHeadGame
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HeadToHeadGameImplCopyWith<_$HeadToHeadGameImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
