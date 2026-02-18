// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GameState _$GameStateFromJson(Map<String, dynamic> json) {
  return _GameState.fromJson(json);
}

/// @nodoc
mixin _$GameState {
  String get gameId => throw _privateConstructorUsedError;
  List<Player> get players => throw _privateConstructorUsedError;
  List<PlayingCard> get crib => throw _privateConstructorUsedError;
  PlayingCard? get cutCard => throw _privateConstructorUsedError;
  String? get currentPlayerId => throw _privateConstructorUsedError;
  GameStage get stage => throw _privateConstructorUsedError;
  List<PlayingCard> get playedCards => throw _privateConstructorUsedError;
  int get peggingCount => throw _privateConstructorUsedError;
  bool get lastPlayWasGo => throw _privateConstructorUsedError;
  Map<String, List<PlayingCard>> get handsForCounting =>
      throw _privateConstructorUsedError;
  List<GameHistoryEvent> get history => throw _privateConstructorUsedError;
  int get dealerIndex => throw _privateConstructorUsedError;
  List<PlayingCard> get remainingDeck => throw _privateConstructorUsedError;

  /// Serializes this GameState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameStateCopyWith<GameState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameStateCopyWith<$Res> {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) then) =
      _$GameStateCopyWithImpl<$Res, GameState>;
  @useResult
  $Res call({
    String gameId,
    List<Player> players,
    List<PlayingCard> crib,
    PlayingCard? cutCard,
    String? currentPlayerId,
    GameStage stage,
    List<PlayingCard> playedCards,
    int peggingCount,
    bool lastPlayWasGo,
    Map<String, List<PlayingCard>> handsForCounting,
    List<GameHistoryEvent> history,
    int dealerIndex,
    List<PlayingCard> remainingDeck,
  });

  $PlayingCardCopyWith<$Res>? get cutCard;
}

/// @nodoc
class _$GameStateCopyWithImpl<$Res, $Val extends GameState>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? players = null,
    Object? crib = null,
    Object? cutCard = freezed,
    Object? currentPlayerId = freezed,
    Object? stage = null,
    Object? playedCards = null,
    Object? peggingCount = null,
    Object? lastPlayWasGo = null,
    Object? handsForCounting = null,
    Object? history = null,
    Object? dealerIndex = null,
    Object? remainingDeck = null,
  }) {
    return _then(
      _value.copyWith(
            gameId: null == gameId
                ? _value.gameId
                : gameId // ignore: cast_nullable_to_non_nullable
                      as String,
            players: null == players
                ? _value.players
                : players // ignore: cast_nullable_to_non_nullable
                      as List<Player>,
            crib: null == crib
                ? _value.crib
                : crib // ignore: cast_nullable_to_non_nullable
                      as List<PlayingCard>,
            cutCard: freezed == cutCard
                ? _value.cutCard
                : cutCard // ignore: cast_nullable_to_non_nullable
                      as PlayingCard?,
            currentPlayerId: freezed == currentPlayerId
                ? _value.currentPlayerId
                : currentPlayerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            stage: null == stage
                ? _value.stage
                : stage // ignore: cast_nullable_to_non_nullable
                      as GameStage,
            playedCards: null == playedCards
                ? _value.playedCards
                : playedCards // ignore: cast_nullable_to_non_nullable
                      as List<PlayingCard>,
            peggingCount: null == peggingCount
                ? _value.peggingCount
                : peggingCount // ignore: cast_nullable_to_non_nullable
                      as int,
            lastPlayWasGo: null == lastPlayWasGo
                ? _value.lastPlayWasGo
                : lastPlayWasGo // ignore: cast_nullable_to_non_nullable
                      as bool,
            handsForCounting: null == handsForCounting
                ? _value.handsForCounting
                : handsForCounting // ignore: cast_nullable_to_non_nullable
                      as Map<String, List<PlayingCard>>,
            history: null == history
                ? _value.history
                : history // ignore: cast_nullable_to_non_nullable
                      as List<GameHistoryEvent>,
            dealerIndex: null == dealerIndex
                ? _value.dealerIndex
                : dealerIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            remainingDeck: null == remainingDeck
                ? _value.remainingDeck
                : remainingDeck // ignore: cast_nullable_to_non_nullable
                      as List<PlayingCard>,
          )
          as $Val,
    );
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayingCardCopyWith<$Res>? get cutCard {
    if (_value.cutCard == null) {
      return null;
    }

    return $PlayingCardCopyWith<$Res>(_value.cutCard!, (value) {
      return _then(_value.copyWith(cutCard: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GameStateImplCopyWith<$Res>
    implements $GameStateCopyWith<$Res> {
  factory _$$GameStateImplCopyWith(
    _$GameStateImpl value,
    $Res Function(_$GameStateImpl) then,
  ) = __$$GameStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String gameId,
    List<Player> players,
    List<PlayingCard> crib,
    PlayingCard? cutCard,
    String? currentPlayerId,
    GameStage stage,
    List<PlayingCard> playedCards,
    int peggingCount,
    bool lastPlayWasGo,
    Map<String, List<PlayingCard>> handsForCounting,
    List<GameHistoryEvent> history,
    int dealerIndex,
    List<PlayingCard> remainingDeck,
  });

  @override
  $PlayingCardCopyWith<$Res>? get cutCard;
}

/// @nodoc
class __$$GameStateImplCopyWithImpl<$Res>
    extends _$GameStateCopyWithImpl<$Res, _$GameStateImpl>
    implements _$$GameStateImplCopyWith<$Res> {
  __$$GameStateImplCopyWithImpl(
    _$GameStateImpl _value,
    $Res Function(_$GameStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? players = null,
    Object? crib = null,
    Object? cutCard = freezed,
    Object? currentPlayerId = freezed,
    Object? stage = null,
    Object? playedCards = null,
    Object? peggingCount = null,
    Object? lastPlayWasGo = null,
    Object? handsForCounting = null,
    Object? history = null,
    Object? dealerIndex = null,
    Object? remainingDeck = null,
  }) {
    return _then(
      _$GameStateImpl(
        gameId: null == gameId
            ? _value.gameId
            : gameId // ignore: cast_nullable_to_non_nullable
                  as String,
        players: null == players
            ? _value._players
            : players // ignore: cast_nullable_to_non_nullable
                  as List<Player>,
        crib: null == crib
            ? _value._crib
            : crib // ignore: cast_nullable_to_non_nullable
                  as List<PlayingCard>,
        cutCard: freezed == cutCard
            ? _value.cutCard
            : cutCard // ignore: cast_nullable_to_non_nullable
                  as PlayingCard?,
        currentPlayerId: freezed == currentPlayerId
            ? _value.currentPlayerId
            : currentPlayerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        stage: null == stage
            ? _value.stage
            : stage // ignore: cast_nullable_to_non_nullable
                  as GameStage,
        playedCards: null == playedCards
            ? _value._playedCards
            : playedCards // ignore: cast_nullable_to_non_nullable
                  as List<PlayingCard>,
        peggingCount: null == peggingCount
            ? _value.peggingCount
            : peggingCount // ignore: cast_nullable_to_non_nullable
                  as int,
        lastPlayWasGo: null == lastPlayWasGo
            ? _value.lastPlayWasGo
            : lastPlayWasGo // ignore: cast_nullable_to_non_nullable
                  as bool,
        handsForCounting: null == handsForCounting
            ? _value._handsForCounting
            : handsForCounting // ignore: cast_nullable_to_non_nullable
                  as Map<String, List<PlayingCard>>,
        history: null == history
            ? _value._history
            : history // ignore: cast_nullable_to_non_nullable
                  as List<GameHistoryEvent>,
        dealerIndex: null == dealerIndex
            ? _value.dealerIndex
            : dealerIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        remainingDeck: null == remainingDeck
            ? _value._remainingDeck
            : remainingDeck // ignore: cast_nullable_to_non_nullable
                  as List<PlayingCard>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GameStateImpl implements _GameState {
  const _$GameStateImpl({
    required this.gameId,
    required final List<Player> players,
    final List<PlayingCard> crib = const [],
    this.cutCard,
    this.currentPlayerId,
    this.stage = GameStage.dealing,
    final List<PlayingCard> playedCards = const [],
    this.peggingCount = 0,
    this.lastPlayWasGo = false,
    final Map<String, List<PlayingCard>> handsForCounting = const {},
    final List<GameHistoryEvent> history = const [],
    this.dealerIndex = 0,
    final List<PlayingCard> remainingDeck = const [],
  }) : _players = players,
       _crib = crib,
       _playedCards = playedCards,
       _handsForCounting = handsForCounting,
       _history = history,
       _remainingDeck = remainingDeck;

  factory _$GameStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameStateImplFromJson(json);

  @override
  final String gameId;
  final List<Player> _players;
  @override
  List<Player> get players {
    if (_players is EqualUnmodifiableListView) return _players;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_players);
  }

  final List<PlayingCard> _crib;
  @override
  @JsonKey()
  List<PlayingCard> get crib {
    if (_crib is EqualUnmodifiableListView) return _crib;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_crib);
  }

  @override
  final PlayingCard? cutCard;
  @override
  final String? currentPlayerId;
  @override
  @JsonKey()
  final GameStage stage;
  final List<PlayingCard> _playedCards;
  @override
  @JsonKey()
  List<PlayingCard> get playedCards {
    if (_playedCards is EqualUnmodifiableListView) return _playedCards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playedCards);
  }

  @override
  @JsonKey()
  final int peggingCount;
  @override
  @JsonKey()
  final bool lastPlayWasGo;
  final Map<String, List<PlayingCard>> _handsForCounting;
  @override
  @JsonKey()
  Map<String, List<PlayingCard>> get handsForCounting {
    if (_handsForCounting is EqualUnmodifiableMapView) return _handsForCounting;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_handsForCounting);
  }

  final List<GameHistoryEvent> _history;
  @override
  @JsonKey()
  List<GameHistoryEvent> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  @override
  @JsonKey()
  final int dealerIndex;
  final List<PlayingCard> _remainingDeck;
  @override
  @JsonKey()
  List<PlayingCard> get remainingDeck {
    if (_remainingDeck is EqualUnmodifiableListView) return _remainingDeck;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_remainingDeck);
  }

  @override
  String toString() {
    return 'GameState(gameId: $gameId, players: $players, crib: $crib, cutCard: $cutCard, currentPlayerId: $currentPlayerId, stage: $stage, playedCards: $playedCards, peggingCount: $peggingCount, lastPlayWasGo: $lastPlayWasGo, handsForCounting: $handsForCounting, history: $history, dealerIndex: $dealerIndex, remainingDeck: $remainingDeck)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameStateImpl &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            const DeepCollectionEquality().equals(other._players, _players) &&
            const DeepCollectionEquality().equals(other._crib, _crib) &&
            (identical(other.cutCard, cutCard) || other.cutCard == cutCard) &&
            (identical(other.currentPlayerId, currentPlayerId) ||
                other.currentPlayerId == currentPlayerId) &&
            (identical(other.stage, stage) || other.stage == stage) &&
            const DeepCollectionEquality().equals(
              other._playedCards,
              _playedCards,
            ) &&
            (identical(other.peggingCount, peggingCount) ||
                other.peggingCount == peggingCount) &&
            (identical(other.lastPlayWasGo, lastPlayWasGo) ||
                other.lastPlayWasGo == lastPlayWasGo) &&
            const DeepCollectionEquality().equals(
              other._handsForCounting,
              _handsForCounting,
            ) &&
            const DeepCollectionEquality().equals(other._history, _history) &&
            (identical(other.dealerIndex, dealerIndex) ||
                other.dealerIndex == dealerIndex) &&
            const DeepCollectionEquality().equals(
              other._remainingDeck,
              _remainingDeck,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    gameId,
    const DeepCollectionEquality().hash(_players),
    const DeepCollectionEquality().hash(_crib),
    cutCard,
    currentPlayerId,
    stage,
    const DeepCollectionEquality().hash(_playedCards),
    peggingCount,
    lastPlayWasGo,
    const DeepCollectionEquality().hash(_handsForCounting),
    const DeepCollectionEquality().hash(_history),
    dealerIndex,
    const DeepCollectionEquality().hash(_remainingDeck),
  );

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      __$$GameStateImplCopyWithImpl<_$GameStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameStateImplToJson(this);
  }
}

abstract class _GameState implements GameState {
  const factory _GameState({
    required final String gameId,
    required final List<Player> players,
    final List<PlayingCard> crib,
    final PlayingCard? cutCard,
    final String? currentPlayerId,
    final GameStage stage,
    final List<PlayingCard> playedCards,
    final int peggingCount,
    final bool lastPlayWasGo,
    final Map<String, List<PlayingCard>> handsForCounting,
    final List<GameHistoryEvent> history,
    final int dealerIndex,
    final List<PlayingCard> remainingDeck,
  }) = _$GameStateImpl;

  factory _GameState.fromJson(Map<String, dynamic> json) =
      _$GameStateImpl.fromJson;

  @override
  String get gameId;
  @override
  List<Player> get players;
  @override
  List<PlayingCard> get crib;
  @override
  PlayingCard? get cutCard;
  @override
  String? get currentPlayerId;
  @override
  GameStage get stage;
  @override
  List<PlayingCard> get playedCards;
  @override
  int get peggingCount;
  @override
  bool get lastPlayWasGo;
  @override
  Map<String, List<PlayingCard>> get handsForCounting;
  @override
  List<GameHistoryEvent> get history;
  @override
  int get dealerIndex;
  @override
  List<PlayingCard> get remainingDeck;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
