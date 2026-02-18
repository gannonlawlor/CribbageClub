// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lobby.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LobbyPlayer _$LobbyPlayerFromJson(Map<String, dynamic> json) {
  return _LobbyPlayer.fromJson(json);
}

/// @nodoc
mixin _$LobbyPlayer {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get joinedAt => throw _privateConstructorUsedError;

  /// Serializes this LobbyPlayer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LobbyPlayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LobbyPlayerCopyWith<LobbyPlayer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LobbyPlayerCopyWith<$Res> {
  factory $LobbyPlayerCopyWith(
    LobbyPlayer value,
    $Res Function(LobbyPlayer) then,
  ) = _$LobbyPlayerCopyWithImpl<$Res, LobbyPlayer>;
  @useResult
  $Res call({String id, String name, String joinedAt});
}

/// @nodoc
class _$LobbyPlayerCopyWithImpl<$Res, $Val extends LobbyPlayer>
    implements $LobbyPlayerCopyWith<$Res> {
  _$LobbyPlayerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LobbyPlayer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? joinedAt = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            joinedAt: null == joinedAt
                ? _value.joinedAt
                : joinedAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LobbyPlayerImplCopyWith<$Res>
    implements $LobbyPlayerCopyWith<$Res> {
  factory _$$LobbyPlayerImplCopyWith(
    _$LobbyPlayerImpl value,
    $Res Function(_$LobbyPlayerImpl) then,
  ) = __$$LobbyPlayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String joinedAt});
}

/// @nodoc
class __$$LobbyPlayerImplCopyWithImpl<$Res>
    extends _$LobbyPlayerCopyWithImpl<$Res, _$LobbyPlayerImpl>
    implements _$$LobbyPlayerImplCopyWith<$Res> {
  __$$LobbyPlayerImplCopyWithImpl(
    _$LobbyPlayerImpl _value,
    $Res Function(_$LobbyPlayerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LobbyPlayer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? joinedAt = null}) {
    return _then(
      _$LobbyPlayerImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        joinedAt: null == joinedAt
            ? _value.joinedAt
            : joinedAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LobbyPlayerImpl implements _LobbyPlayer {
  const _$LobbyPlayerImpl({
    required this.id,
    required this.name,
    required this.joinedAt,
  });

  factory _$LobbyPlayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$LobbyPlayerImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String joinedAt;

  @override
  String toString() {
    return 'LobbyPlayer(id: $id, name: $name, joinedAt: $joinedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LobbyPlayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, joinedAt);

  /// Create a copy of LobbyPlayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LobbyPlayerImplCopyWith<_$LobbyPlayerImpl> get copyWith =>
      __$$LobbyPlayerImplCopyWithImpl<_$LobbyPlayerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LobbyPlayerImplToJson(this);
  }
}

abstract class _LobbyPlayer implements LobbyPlayer {
  const factory _LobbyPlayer({
    required final String id,
    required final String name,
    required final String joinedAt,
  }) = _$LobbyPlayerImpl;

  factory _LobbyPlayer.fromJson(Map<String, dynamic> json) =
      _$LobbyPlayerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get joinedAt;

  /// Create a copy of LobbyPlayer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LobbyPlayerImplCopyWith<_$LobbyPlayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Lobby _$LobbyFromJson(Map<String, dynamic> json) {
  return _Lobby.fromJson(json);
}

/// @nodoc
mixin _$Lobby {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<LobbyPlayer> get players => throw _privateConstructorUsedError;
  int get maxPlayers => throw _privateConstructorUsedError;
  LobbyStatus get status => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String? get gameId => throw _privateConstructorUsedError;
  bool get isPrivate => throw _privateConstructorUsedError;
  String? get inviteCode => throw _privateConstructorUsedError;

  /// Serializes this Lobby to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Lobby
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LobbyCopyWith<Lobby> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LobbyCopyWith<$Res> {
  factory $LobbyCopyWith(Lobby value, $Res Function(Lobby) then) =
      _$LobbyCopyWithImpl<$Res, Lobby>;
  @useResult
  $Res call({
    String id,
    String name,
    List<LobbyPlayer> players,
    int maxPlayers,
    LobbyStatus status,
    String createdAt,
    String? gameId,
    bool isPrivate,
    String? inviteCode,
  });
}

/// @nodoc
class _$LobbyCopyWithImpl<$Res, $Val extends Lobby>
    implements $LobbyCopyWith<$Res> {
  _$LobbyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Lobby
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? players = null,
    Object? maxPlayers = null,
    Object? status = null,
    Object? createdAt = null,
    Object? gameId = freezed,
    Object? isPrivate = null,
    Object? inviteCode = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            players: null == players
                ? _value.players
                : players // ignore: cast_nullable_to_non_nullable
                      as List<LobbyPlayer>,
            maxPlayers: null == maxPlayers
                ? _value.maxPlayers
                : maxPlayers // ignore: cast_nullable_to_non_nullable
                      as int,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as LobbyStatus,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
            gameId: freezed == gameId
                ? _value.gameId
                : gameId // ignore: cast_nullable_to_non_nullable
                      as String?,
            isPrivate: null == isPrivate
                ? _value.isPrivate
                : isPrivate // ignore: cast_nullable_to_non_nullable
                      as bool,
            inviteCode: freezed == inviteCode
                ? _value.inviteCode
                : inviteCode // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LobbyImplCopyWith<$Res> implements $LobbyCopyWith<$Res> {
  factory _$$LobbyImplCopyWith(
    _$LobbyImpl value,
    $Res Function(_$LobbyImpl) then,
  ) = __$$LobbyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    List<LobbyPlayer> players,
    int maxPlayers,
    LobbyStatus status,
    String createdAt,
    String? gameId,
    bool isPrivate,
    String? inviteCode,
  });
}

/// @nodoc
class __$$LobbyImplCopyWithImpl<$Res>
    extends _$LobbyCopyWithImpl<$Res, _$LobbyImpl>
    implements _$$LobbyImplCopyWith<$Res> {
  __$$LobbyImplCopyWithImpl(
    _$LobbyImpl _value,
    $Res Function(_$LobbyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Lobby
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? players = null,
    Object? maxPlayers = null,
    Object? status = null,
    Object? createdAt = null,
    Object? gameId = freezed,
    Object? isPrivate = null,
    Object? inviteCode = freezed,
  }) {
    return _then(
      _$LobbyImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        players: null == players
            ? _value._players
            : players // ignore: cast_nullable_to_non_nullable
                  as List<LobbyPlayer>,
        maxPlayers: null == maxPlayers
            ? _value.maxPlayers
            : maxPlayers // ignore: cast_nullable_to_non_nullable
                  as int,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as LobbyStatus,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
        gameId: freezed == gameId
            ? _value.gameId
            : gameId // ignore: cast_nullable_to_non_nullable
                  as String?,
        isPrivate: null == isPrivate
            ? _value.isPrivate
            : isPrivate // ignore: cast_nullable_to_non_nullable
                  as bool,
        inviteCode: freezed == inviteCode
            ? _value.inviteCode
            : inviteCode // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LobbyImpl implements _Lobby {
  const _$LobbyImpl({
    required this.id,
    required this.name,
    final List<LobbyPlayer> players = const [],
    this.maxPlayers = 2,
    this.status = LobbyStatus.waiting,
    required this.createdAt,
    this.gameId,
    this.isPrivate = false,
    this.inviteCode,
  }) : _players = players;

  factory _$LobbyImpl.fromJson(Map<String, dynamic> json) =>
      _$$LobbyImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  final List<LobbyPlayer> _players;
  @override
  @JsonKey()
  List<LobbyPlayer> get players {
    if (_players is EqualUnmodifiableListView) return _players;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_players);
  }

  @override
  @JsonKey()
  final int maxPlayers;
  @override
  @JsonKey()
  final LobbyStatus status;
  @override
  final String createdAt;
  @override
  final String? gameId;
  @override
  @JsonKey()
  final bool isPrivate;
  @override
  final String? inviteCode;

  @override
  String toString() {
    return 'Lobby(id: $id, name: $name, players: $players, maxPlayers: $maxPlayers, status: $status, createdAt: $createdAt, gameId: $gameId, isPrivate: $isPrivate, inviteCode: $inviteCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LobbyImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._players, _players) &&
            (identical(other.maxPlayers, maxPlayers) ||
                other.maxPlayers == maxPlayers) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.isPrivate, isPrivate) ||
                other.isPrivate == isPrivate) &&
            (identical(other.inviteCode, inviteCode) ||
                other.inviteCode == inviteCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    const DeepCollectionEquality().hash(_players),
    maxPlayers,
    status,
    createdAt,
    gameId,
    isPrivate,
    inviteCode,
  );

  /// Create a copy of Lobby
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LobbyImplCopyWith<_$LobbyImpl> get copyWith =>
      __$$LobbyImplCopyWithImpl<_$LobbyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LobbyImplToJson(this);
  }
}

abstract class _Lobby implements Lobby {
  const factory _Lobby({
    required final String id,
    required final String name,
    final List<LobbyPlayer> players,
    final int maxPlayers,
    final LobbyStatus status,
    required final String createdAt,
    final String? gameId,
    final bool isPrivate,
    final String? inviteCode,
  }) = _$LobbyImpl;

  factory _Lobby.fromJson(Map<String, dynamic> json) = _$LobbyImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  List<LobbyPlayer> get players;
  @override
  int get maxPlayers;
  @override
  LobbyStatus get status;
  @override
  String get createdAt;
  @override
  String? get gameId;
  @override
  bool get isPrivate;
  @override
  String? get inviteCode;

  /// Create a copy of Lobby
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LobbyImplCopyWith<_$LobbyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
