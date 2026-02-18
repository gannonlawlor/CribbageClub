// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_history_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GameHistoryEvent _$GameHistoryEventFromJson(Map<String, dynamic> json) {
  switch (json['type']) {
    case 'RoundStarted':
      return RoundStarted.fromJson(json);
    case 'CardsDealt':
      return CardsDealt.fromJson(json);
    case 'DeckCut':
      return DeckCut.fromJson(json);
    case 'CardPlayed':
      return CardPlayed.fromJson(json);
    case 'GoAnnounced':
      return GoAnnounced.fromJson(json);
    case 'PeggingEnded':
      return PeggingEnded.fromJson(json);
    case 'HandCounted':
      return HandCounted.fromJson(json);
    case 'CribCounted':
      return CribCounted.fromJson(json);
    case 'GameEnded':
      return GameEnded.fromJson(json);

    default:
      throw CheckedFromJsonException(
        json,
        'type',
        'GameHistoryEvent',
        'Invalid union type "${json['type']}"!',
      );
  }
}

/// @nodoc
mixin _$GameHistoryEvent {
  String get timestamp => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String timestamp, int roundNumber) roundStarted,
    required TResult Function(String timestamp) cardsDealt,
    required TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )
    deckCut,
    required TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )
    cardPlayed,
    required TResult Function(
      String timestamp,
      String playerId,
      int pointsScored,
    )
    goAnnounced,
    required TResult Function(String timestamp) peggingEnded,
    required TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    handCounted,
    required TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    cribCounted,
    required TResult Function(
      String timestamp,
      String winnerPlayerId,
      int finalScore,
    )
    gameEnded,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String timestamp, int roundNumber)? roundStarted,
    TResult? Function(String timestamp)? cardsDealt,
    TResult? Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult? Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult? Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult? Function(String timestamp)? peggingEnded,
    TResult? Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult? Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult? Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String timestamp, int roundNumber)? roundStarted,
    TResult Function(String timestamp)? cardsDealt,
    TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult Function(String timestamp)? peggingEnded,
    TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RoundStarted value) roundStarted,
    required TResult Function(CardsDealt value) cardsDealt,
    required TResult Function(DeckCut value) deckCut,
    required TResult Function(CardPlayed value) cardPlayed,
    required TResult Function(GoAnnounced value) goAnnounced,
    required TResult Function(PeggingEnded value) peggingEnded,
    required TResult Function(HandCounted value) handCounted,
    required TResult Function(CribCounted value) cribCounted,
    required TResult Function(GameEnded value) gameEnded,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RoundStarted value)? roundStarted,
    TResult? Function(CardsDealt value)? cardsDealt,
    TResult? Function(DeckCut value)? deckCut,
    TResult? Function(CardPlayed value)? cardPlayed,
    TResult? Function(GoAnnounced value)? goAnnounced,
    TResult? Function(PeggingEnded value)? peggingEnded,
    TResult? Function(HandCounted value)? handCounted,
    TResult? Function(CribCounted value)? cribCounted,
    TResult? Function(GameEnded value)? gameEnded,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RoundStarted value)? roundStarted,
    TResult Function(CardsDealt value)? cardsDealt,
    TResult Function(DeckCut value)? deckCut,
    TResult Function(CardPlayed value)? cardPlayed,
    TResult Function(GoAnnounced value)? goAnnounced,
    TResult Function(PeggingEnded value)? peggingEnded,
    TResult Function(HandCounted value)? handCounted,
    TResult Function(CribCounted value)? cribCounted,
    TResult Function(GameEnded value)? gameEnded,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Serializes this GameHistoryEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameHistoryEventCopyWith<GameHistoryEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameHistoryEventCopyWith<$Res> {
  factory $GameHistoryEventCopyWith(
    GameHistoryEvent value,
    $Res Function(GameHistoryEvent) then,
  ) = _$GameHistoryEventCopyWithImpl<$Res, GameHistoryEvent>;
  @useResult
  $Res call({String timestamp});
}

/// @nodoc
class _$GameHistoryEventCopyWithImpl<$Res, $Val extends GameHistoryEvent>
    implements $GameHistoryEventCopyWith<$Res> {
  _$GameHistoryEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? timestamp = null}) {
    return _then(
      _value.copyWith(
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RoundStartedImplCopyWith<$Res>
    implements $GameHistoryEventCopyWith<$Res> {
  factory _$$RoundStartedImplCopyWith(
    _$RoundStartedImpl value,
    $Res Function(_$RoundStartedImpl) then,
  ) = __$$RoundStartedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String timestamp, int roundNumber});
}

/// @nodoc
class __$$RoundStartedImplCopyWithImpl<$Res>
    extends _$GameHistoryEventCopyWithImpl<$Res, _$RoundStartedImpl>
    implements _$$RoundStartedImplCopyWith<$Res> {
  __$$RoundStartedImplCopyWithImpl(
    _$RoundStartedImpl _value,
    $Res Function(_$RoundStartedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? timestamp = null, Object? roundNumber = null}) {
    return _then(
      _$RoundStartedImpl(
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String,
        roundNumber: null == roundNumber
            ? _value.roundNumber
            : roundNumber // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RoundStartedImpl implements RoundStarted {
  const _$RoundStartedImpl({
    required this.timestamp,
    required this.roundNumber,
    final String? $type,
  }) : $type = $type ?? 'RoundStarted';

  factory _$RoundStartedImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoundStartedImplFromJson(json);

  @override
  final String timestamp;
  @override
  final int roundNumber;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'GameHistoryEvent.roundStarted(timestamp: $timestamp, roundNumber: $roundNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoundStartedImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.roundNumber, roundNumber) ||
                other.roundNumber == roundNumber));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, timestamp, roundNumber);

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoundStartedImplCopyWith<_$RoundStartedImpl> get copyWith =>
      __$$RoundStartedImplCopyWithImpl<_$RoundStartedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String timestamp, int roundNumber) roundStarted,
    required TResult Function(String timestamp) cardsDealt,
    required TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )
    deckCut,
    required TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )
    cardPlayed,
    required TResult Function(
      String timestamp,
      String playerId,
      int pointsScored,
    )
    goAnnounced,
    required TResult Function(String timestamp) peggingEnded,
    required TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    handCounted,
    required TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    cribCounted,
    required TResult Function(
      String timestamp,
      String winnerPlayerId,
      int finalScore,
    )
    gameEnded,
  }) {
    return roundStarted(timestamp, roundNumber);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String timestamp, int roundNumber)? roundStarted,
    TResult? Function(String timestamp)? cardsDealt,
    TResult? Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult? Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult? Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult? Function(String timestamp)? peggingEnded,
    TResult? Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult? Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult? Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
  }) {
    return roundStarted?.call(timestamp, roundNumber);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String timestamp, int roundNumber)? roundStarted,
    TResult Function(String timestamp)? cardsDealt,
    TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult Function(String timestamp)? peggingEnded,
    TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
    required TResult orElse(),
  }) {
    if (roundStarted != null) {
      return roundStarted(timestamp, roundNumber);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RoundStarted value) roundStarted,
    required TResult Function(CardsDealt value) cardsDealt,
    required TResult Function(DeckCut value) deckCut,
    required TResult Function(CardPlayed value) cardPlayed,
    required TResult Function(GoAnnounced value) goAnnounced,
    required TResult Function(PeggingEnded value) peggingEnded,
    required TResult Function(HandCounted value) handCounted,
    required TResult Function(CribCounted value) cribCounted,
    required TResult Function(GameEnded value) gameEnded,
  }) {
    return roundStarted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RoundStarted value)? roundStarted,
    TResult? Function(CardsDealt value)? cardsDealt,
    TResult? Function(DeckCut value)? deckCut,
    TResult? Function(CardPlayed value)? cardPlayed,
    TResult? Function(GoAnnounced value)? goAnnounced,
    TResult? Function(PeggingEnded value)? peggingEnded,
    TResult? Function(HandCounted value)? handCounted,
    TResult? Function(CribCounted value)? cribCounted,
    TResult? Function(GameEnded value)? gameEnded,
  }) {
    return roundStarted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RoundStarted value)? roundStarted,
    TResult Function(CardsDealt value)? cardsDealt,
    TResult Function(DeckCut value)? deckCut,
    TResult Function(CardPlayed value)? cardPlayed,
    TResult Function(GoAnnounced value)? goAnnounced,
    TResult Function(PeggingEnded value)? peggingEnded,
    TResult Function(HandCounted value)? handCounted,
    TResult Function(CribCounted value)? cribCounted,
    TResult Function(GameEnded value)? gameEnded,
    required TResult orElse(),
  }) {
    if (roundStarted != null) {
      return roundStarted(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$RoundStartedImplToJson(this);
  }
}

abstract class RoundStarted implements GameHistoryEvent {
  const factory RoundStarted({
    required final String timestamp,
    required final int roundNumber,
  }) = _$RoundStartedImpl;

  factory RoundStarted.fromJson(Map<String, dynamic> json) =
      _$RoundStartedImpl.fromJson;

  @override
  String get timestamp;
  int get roundNumber;

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoundStartedImplCopyWith<_$RoundStartedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CardsDealtImplCopyWith<$Res>
    implements $GameHistoryEventCopyWith<$Res> {
  factory _$$CardsDealtImplCopyWith(
    _$CardsDealtImpl value,
    $Res Function(_$CardsDealtImpl) then,
  ) = __$$CardsDealtImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String timestamp});
}

/// @nodoc
class __$$CardsDealtImplCopyWithImpl<$Res>
    extends _$GameHistoryEventCopyWithImpl<$Res, _$CardsDealtImpl>
    implements _$$CardsDealtImplCopyWith<$Res> {
  __$$CardsDealtImplCopyWithImpl(
    _$CardsDealtImpl _value,
    $Res Function(_$CardsDealtImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? timestamp = null}) {
    return _then(
      _$CardsDealtImpl(
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CardsDealtImpl implements CardsDealt {
  const _$CardsDealtImpl({required this.timestamp, final String? $type})
    : $type = $type ?? 'CardsDealt';

  factory _$CardsDealtImpl.fromJson(Map<String, dynamic> json) =>
      _$$CardsDealtImplFromJson(json);

  @override
  final String timestamp;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'GameHistoryEvent.cardsDealt(timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CardsDealtImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, timestamp);

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CardsDealtImplCopyWith<_$CardsDealtImpl> get copyWith =>
      __$$CardsDealtImplCopyWithImpl<_$CardsDealtImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String timestamp, int roundNumber) roundStarted,
    required TResult Function(String timestamp) cardsDealt,
    required TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )
    deckCut,
    required TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )
    cardPlayed,
    required TResult Function(
      String timestamp,
      String playerId,
      int pointsScored,
    )
    goAnnounced,
    required TResult Function(String timestamp) peggingEnded,
    required TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    handCounted,
    required TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    cribCounted,
    required TResult Function(
      String timestamp,
      String winnerPlayerId,
      int finalScore,
    )
    gameEnded,
  }) {
    return cardsDealt(timestamp);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String timestamp, int roundNumber)? roundStarted,
    TResult? Function(String timestamp)? cardsDealt,
    TResult? Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult? Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult? Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult? Function(String timestamp)? peggingEnded,
    TResult? Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult? Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult? Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
  }) {
    return cardsDealt?.call(timestamp);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String timestamp, int roundNumber)? roundStarted,
    TResult Function(String timestamp)? cardsDealt,
    TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult Function(String timestamp)? peggingEnded,
    TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
    required TResult orElse(),
  }) {
    if (cardsDealt != null) {
      return cardsDealt(timestamp);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RoundStarted value) roundStarted,
    required TResult Function(CardsDealt value) cardsDealt,
    required TResult Function(DeckCut value) deckCut,
    required TResult Function(CardPlayed value) cardPlayed,
    required TResult Function(GoAnnounced value) goAnnounced,
    required TResult Function(PeggingEnded value) peggingEnded,
    required TResult Function(HandCounted value) handCounted,
    required TResult Function(CribCounted value) cribCounted,
    required TResult Function(GameEnded value) gameEnded,
  }) {
    return cardsDealt(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RoundStarted value)? roundStarted,
    TResult? Function(CardsDealt value)? cardsDealt,
    TResult? Function(DeckCut value)? deckCut,
    TResult? Function(CardPlayed value)? cardPlayed,
    TResult? Function(GoAnnounced value)? goAnnounced,
    TResult? Function(PeggingEnded value)? peggingEnded,
    TResult? Function(HandCounted value)? handCounted,
    TResult? Function(CribCounted value)? cribCounted,
    TResult? Function(GameEnded value)? gameEnded,
  }) {
    return cardsDealt?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RoundStarted value)? roundStarted,
    TResult Function(CardsDealt value)? cardsDealt,
    TResult Function(DeckCut value)? deckCut,
    TResult Function(CardPlayed value)? cardPlayed,
    TResult Function(GoAnnounced value)? goAnnounced,
    TResult Function(PeggingEnded value)? peggingEnded,
    TResult Function(HandCounted value)? handCounted,
    TResult Function(CribCounted value)? cribCounted,
    TResult Function(GameEnded value)? gameEnded,
    required TResult orElse(),
  }) {
    if (cardsDealt != null) {
      return cardsDealt(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CardsDealtImplToJson(this);
  }
}

abstract class CardsDealt implements GameHistoryEvent {
  const factory CardsDealt({required final String timestamp}) =
      _$CardsDealtImpl;

  factory CardsDealt.fromJson(Map<String, dynamic> json) =
      _$CardsDealtImpl.fromJson;

  @override
  String get timestamp;

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CardsDealtImplCopyWith<_$CardsDealtImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DeckCutImplCopyWith<$Res>
    implements $GameHistoryEventCopyWith<$Res> {
  factory _$$DeckCutImplCopyWith(
    _$DeckCutImpl value,
    $Res Function(_$DeckCutImpl) then,
  ) = __$$DeckCutImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String timestamp,
    PlayingCard cutCard,
    String cuttingPlayerId,
    bool dealerScoredNobs,
  });

  $PlayingCardCopyWith<$Res> get cutCard;
}

/// @nodoc
class __$$DeckCutImplCopyWithImpl<$Res>
    extends _$GameHistoryEventCopyWithImpl<$Res, _$DeckCutImpl>
    implements _$$DeckCutImplCopyWith<$Res> {
  __$$DeckCutImplCopyWithImpl(
    _$DeckCutImpl _value,
    $Res Function(_$DeckCutImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? cutCard = null,
    Object? cuttingPlayerId = null,
    Object? dealerScoredNobs = null,
  }) {
    return _then(
      _$DeckCutImpl(
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String,
        cutCard: null == cutCard
            ? _value.cutCard
            : cutCard // ignore: cast_nullable_to_non_nullable
                  as PlayingCard,
        cuttingPlayerId: null == cuttingPlayerId
            ? _value.cuttingPlayerId
            : cuttingPlayerId // ignore: cast_nullable_to_non_nullable
                  as String,
        dealerScoredNobs: null == dealerScoredNobs
            ? _value.dealerScoredNobs
            : dealerScoredNobs // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayingCardCopyWith<$Res> get cutCard {
    return $PlayingCardCopyWith<$Res>(_value.cutCard, (value) {
      return _then(_value.copyWith(cutCard: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$DeckCutImpl implements DeckCut {
  const _$DeckCutImpl({
    required this.timestamp,
    required this.cutCard,
    required this.cuttingPlayerId,
    this.dealerScoredNobs = false,
    final String? $type,
  }) : $type = $type ?? 'DeckCut';

  factory _$DeckCutImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeckCutImplFromJson(json);

  @override
  final String timestamp;
  @override
  final PlayingCard cutCard;
  @override
  final String cuttingPlayerId;
  @override
  @JsonKey()
  final bool dealerScoredNobs;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'GameHistoryEvent.deckCut(timestamp: $timestamp, cutCard: $cutCard, cuttingPlayerId: $cuttingPlayerId, dealerScoredNobs: $dealerScoredNobs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeckCutImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.cutCard, cutCard) || other.cutCard == cutCard) &&
            (identical(other.cuttingPlayerId, cuttingPlayerId) ||
                other.cuttingPlayerId == cuttingPlayerId) &&
            (identical(other.dealerScoredNobs, dealerScoredNobs) ||
                other.dealerScoredNobs == dealerScoredNobs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    timestamp,
    cutCard,
    cuttingPlayerId,
    dealerScoredNobs,
  );

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeckCutImplCopyWith<_$DeckCutImpl> get copyWith =>
      __$$DeckCutImplCopyWithImpl<_$DeckCutImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String timestamp, int roundNumber) roundStarted,
    required TResult Function(String timestamp) cardsDealt,
    required TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )
    deckCut,
    required TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )
    cardPlayed,
    required TResult Function(
      String timestamp,
      String playerId,
      int pointsScored,
    )
    goAnnounced,
    required TResult Function(String timestamp) peggingEnded,
    required TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    handCounted,
    required TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    cribCounted,
    required TResult Function(
      String timestamp,
      String winnerPlayerId,
      int finalScore,
    )
    gameEnded,
  }) {
    return deckCut(timestamp, cutCard, cuttingPlayerId, dealerScoredNobs);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String timestamp, int roundNumber)? roundStarted,
    TResult? Function(String timestamp)? cardsDealt,
    TResult? Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult? Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult? Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult? Function(String timestamp)? peggingEnded,
    TResult? Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult? Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult? Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
  }) {
    return deckCut?.call(timestamp, cutCard, cuttingPlayerId, dealerScoredNobs);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String timestamp, int roundNumber)? roundStarted,
    TResult Function(String timestamp)? cardsDealt,
    TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult Function(String timestamp)? peggingEnded,
    TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
    required TResult orElse(),
  }) {
    if (deckCut != null) {
      return deckCut(timestamp, cutCard, cuttingPlayerId, dealerScoredNobs);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RoundStarted value) roundStarted,
    required TResult Function(CardsDealt value) cardsDealt,
    required TResult Function(DeckCut value) deckCut,
    required TResult Function(CardPlayed value) cardPlayed,
    required TResult Function(GoAnnounced value) goAnnounced,
    required TResult Function(PeggingEnded value) peggingEnded,
    required TResult Function(HandCounted value) handCounted,
    required TResult Function(CribCounted value) cribCounted,
    required TResult Function(GameEnded value) gameEnded,
  }) {
    return deckCut(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RoundStarted value)? roundStarted,
    TResult? Function(CardsDealt value)? cardsDealt,
    TResult? Function(DeckCut value)? deckCut,
    TResult? Function(CardPlayed value)? cardPlayed,
    TResult? Function(GoAnnounced value)? goAnnounced,
    TResult? Function(PeggingEnded value)? peggingEnded,
    TResult? Function(HandCounted value)? handCounted,
    TResult? Function(CribCounted value)? cribCounted,
    TResult? Function(GameEnded value)? gameEnded,
  }) {
    return deckCut?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RoundStarted value)? roundStarted,
    TResult Function(CardsDealt value)? cardsDealt,
    TResult Function(DeckCut value)? deckCut,
    TResult Function(CardPlayed value)? cardPlayed,
    TResult Function(GoAnnounced value)? goAnnounced,
    TResult Function(PeggingEnded value)? peggingEnded,
    TResult Function(HandCounted value)? handCounted,
    TResult Function(CribCounted value)? cribCounted,
    TResult Function(GameEnded value)? gameEnded,
    required TResult orElse(),
  }) {
    if (deckCut != null) {
      return deckCut(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$DeckCutImplToJson(this);
  }
}

abstract class DeckCut implements GameHistoryEvent {
  const factory DeckCut({
    required final String timestamp,
    required final PlayingCard cutCard,
    required final String cuttingPlayerId,
    final bool dealerScoredNobs,
  }) = _$DeckCutImpl;

  factory DeckCut.fromJson(Map<String, dynamic> json) = _$DeckCutImpl.fromJson;

  @override
  String get timestamp;
  PlayingCard get cutCard;
  String get cuttingPlayerId;
  bool get dealerScoredNobs;

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeckCutImplCopyWith<_$DeckCutImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CardPlayedImplCopyWith<$Res>
    implements $GameHistoryEventCopyWith<$Res> {
  factory _$$CardPlayedImplCopyWith(
    _$CardPlayedImpl value,
    $Res Function(_$CardPlayedImpl) then,
  ) = __$$CardPlayedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String timestamp,
    String playerId,
    PlayingCard card,
    int newCount,
    int pointsScored,
    String? scoringReason,
  });

  $PlayingCardCopyWith<$Res> get card;
}

/// @nodoc
class __$$CardPlayedImplCopyWithImpl<$Res>
    extends _$GameHistoryEventCopyWithImpl<$Res, _$CardPlayedImpl>
    implements _$$CardPlayedImplCopyWith<$Res> {
  __$$CardPlayedImplCopyWithImpl(
    _$CardPlayedImpl _value,
    $Res Function(_$CardPlayedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? playerId = null,
    Object? card = null,
    Object? newCount = null,
    Object? pointsScored = null,
    Object? scoringReason = freezed,
  }) {
    return _then(
      _$CardPlayedImpl(
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String,
        playerId: null == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String,
        card: null == card
            ? _value.card
            : card // ignore: cast_nullable_to_non_nullable
                  as PlayingCard,
        newCount: null == newCount
            ? _value.newCount
            : newCount // ignore: cast_nullable_to_non_nullable
                  as int,
        pointsScored: null == pointsScored
            ? _value.pointsScored
            : pointsScored // ignore: cast_nullable_to_non_nullable
                  as int,
        scoringReason: freezed == scoringReason
            ? _value.scoringReason
            : scoringReason // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayingCardCopyWith<$Res> get card {
    return $PlayingCardCopyWith<$Res>(_value.card, (value) {
      return _then(_value.copyWith(card: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$CardPlayedImpl implements CardPlayed {
  const _$CardPlayedImpl({
    required this.timestamp,
    required this.playerId,
    required this.card,
    required this.newCount,
    required this.pointsScored,
    this.scoringReason,
    final String? $type,
  }) : $type = $type ?? 'CardPlayed';

  factory _$CardPlayedImpl.fromJson(Map<String, dynamic> json) =>
      _$$CardPlayedImplFromJson(json);

  @override
  final String timestamp;
  @override
  final String playerId;
  @override
  final PlayingCard card;
  @override
  final int newCount;
  @override
  final int pointsScored;
  @override
  final String? scoringReason;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'GameHistoryEvent.cardPlayed(timestamp: $timestamp, playerId: $playerId, card: $card, newCount: $newCount, pointsScored: $pointsScored, scoringReason: $scoringReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CardPlayedImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.card, card) || other.card == card) &&
            (identical(other.newCount, newCount) ||
                other.newCount == newCount) &&
            (identical(other.pointsScored, pointsScored) ||
                other.pointsScored == pointsScored) &&
            (identical(other.scoringReason, scoringReason) ||
                other.scoringReason == scoringReason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    timestamp,
    playerId,
    card,
    newCount,
    pointsScored,
    scoringReason,
  );

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CardPlayedImplCopyWith<_$CardPlayedImpl> get copyWith =>
      __$$CardPlayedImplCopyWithImpl<_$CardPlayedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String timestamp, int roundNumber) roundStarted,
    required TResult Function(String timestamp) cardsDealt,
    required TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )
    deckCut,
    required TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )
    cardPlayed,
    required TResult Function(
      String timestamp,
      String playerId,
      int pointsScored,
    )
    goAnnounced,
    required TResult Function(String timestamp) peggingEnded,
    required TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    handCounted,
    required TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    cribCounted,
    required TResult Function(
      String timestamp,
      String winnerPlayerId,
      int finalScore,
    )
    gameEnded,
  }) {
    return cardPlayed(
      timestamp,
      playerId,
      card,
      newCount,
      pointsScored,
      scoringReason,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String timestamp, int roundNumber)? roundStarted,
    TResult? Function(String timestamp)? cardsDealt,
    TResult? Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult? Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult? Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult? Function(String timestamp)? peggingEnded,
    TResult? Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult? Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult? Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
  }) {
    return cardPlayed?.call(
      timestamp,
      playerId,
      card,
      newCount,
      pointsScored,
      scoringReason,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String timestamp, int roundNumber)? roundStarted,
    TResult Function(String timestamp)? cardsDealt,
    TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult Function(String timestamp)? peggingEnded,
    TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
    required TResult orElse(),
  }) {
    if (cardPlayed != null) {
      return cardPlayed(
        timestamp,
        playerId,
        card,
        newCount,
        pointsScored,
        scoringReason,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RoundStarted value) roundStarted,
    required TResult Function(CardsDealt value) cardsDealt,
    required TResult Function(DeckCut value) deckCut,
    required TResult Function(CardPlayed value) cardPlayed,
    required TResult Function(GoAnnounced value) goAnnounced,
    required TResult Function(PeggingEnded value) peggingEnded,
    required TResult Function(HandCounted value) handCounted,
    required TResult Function(CribCounted value) cribCounted,
    required TResult Function(GameEnded value) gameEnded,
  }) {
    return cardPlayed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RoundStarted value)? roundStarted,
    TResult? Function(CardsDealt value)? cardsDealt,
    TResult? Function(DeckCut value)? deckCut,
    TResult? Function(CardPlayed value)? cardPlayed,
    TResult? Function(GoAnnounced value)? goAnnounced,
    TResult? Function(PeggingEnded value)? peggingEnded,
    TResult? Function(HandCounted value)? handCounted,
    TResult? Function(CribCounted value)? cribCounted,
    TResult? Function(GameEnded value)? gameEnded,
  }) {
    return cardPlayed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RoundStarted value)? roundStarted,
    TResult Function(CardsDealt value)? cardsDealt,
    TResult Function(DeckCut value)? deckCut,
    TResult Function(CardPlayed value)? cardPlayed,
    TResult Function(GoAnnounced value)? goAnnounced,
    TResult Function(PeggingEnded value)? peggingEnded,
    TResult Function(HandCounted value)? handCounted,
    TResult Function(CribCounted value)? cribCounted,
    TResult Function(GameEnded value)? gameEnded,
    required TResult orElse(),
  }) {
    if (cardPlayed != null) {
      return cardPlayed(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CardPlayedImplToJson(this);
  }
}

abstract class CardPlayed implements GameHistoryEvent {
  const factory CardPlayed({
    required final String timestamp,
    required final String playerId,
    required final PlayingCard card,
    required final int newCount,
    required final int pointsScored,
    final String? scoringReason,
  }) = _$CardPlayedImpl;

  factory CardPlayed.fromJson(Map<String, dynamic> json) =
      _$CardPlayedImpl.fromJson;

  @override
  String get timestamp;
  String get playerId;
  PlayingCard get card;
  int get newCount;
  int get pointsScored;
  String? get scoringReason;

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CardPlayedImplCopyWith<_$CardPlayedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GoAnnouncedImplCopyWith<$Res>
    implements $GameHistoryEventCopyWith<$Res> {
  factory _$$GoAnnouncedImplCopyWith(
    _$GoAnnouncedImpl value,
    $Res Function(_$GoAnnouncedImpl) then,
  ) = __$$GoAnnouncedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String timestamp, String playerId, int pointsScored});
}

/// @nodoc
class __$$GoAnnouncedImplCopyWithImpl<$Res>
    extends _$GameHistoryEventCopyWithImpl<$Res, _$GoAnnouncedImpl>
    implements _$$GoAnnouncedImplCopyWith<$Res> {
  __$$GoAnnouncedImplCopyWithImpl(
    _$GoAnnouncedImpl _value,
    $Res Function(_$GoAnnouncedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? playerId = null,
    Object? pointsScored = null,
  }) {
    return _then(
      _$GoAnnouncedImpl(
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String,
        playerId: null == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String,
        pointsScored: null == pointsScored
            ? _value.pointsScored
            : pointsScored // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GoAnnouncedImpl implements GoAnnounced {
  const _$GoAnnouncedImpl({
    required this.timestamp,
    required this.playerId,
    this.pointsScored = 0,
    final String? $type,
  }) : $type = $type ?? 'GoAnnounced';

  factory _$GoAnnouncedImpl.fromJson(Map<String, dynamic> json) =>
      _$$GoAnnouncedImplFromJson(json);

  @override
  final String timestamp;
  @override
  final String playerId;
  @override
  @JsonKey()
  final int pointsScored;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'GameHistoryEvent.goAnnounced(timestamp: $timestamp, playerId: $playerId, pointsScored: $pointsScored)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoAnnouncedImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.pointsScored, pointsScored) ||
                other.pointsScored == pointsScored));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, timestamp, playerId, pointsScored);

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GoAnnouncedImplCopyWith<_$GoAnnouncedImpl> get copyWith =>
      __$$GoAnnouncedImplCopyWithImpl<_$GoAnnouncedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String timestamp, int roundNumber) roundStarted,
    required TResult Function(String timestamp) cardsDealt,
    required TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )
    deckCut,
    required TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )
    cardPlayed,
    required TResult Function(
      String timestamp,
      String playerId,
      int pointsScored,
    )
    goAnnounced,
    required TResult Function(String timestamp) peggingEnded,
    required TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    handCounted,
    required TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    cribCounted,
    required TResult Function(
      String timestamp,
      String winnerPlayerId,
      int finalScore,
    )
    gameEnded,
  }) {
    return goAnnounced(timestamp, playerId, pointsScored);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String timestamp, int roundNumber)? roundStarted,
    TResult? Function(String timestamp)? cardsDealt,
    TResult? Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult? Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult? Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult? Function(String timestamp)? peggingEnded,
    TResult? Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult? Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult? Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
  }) {
    return goAnnounced?.call(timestamp, playerId, pointsScored);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String timestamp, int roundNumber)? roundStarted,
    TResult Function(String timestamp)? cardsDealt,
    TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult Function(String timestamp)? peggingEnded,
    TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
    required TResult orElse(),
  }) {
    if (goAnnounced != null) {
      return goAnnounced(timestamp, playerId, pointsScored);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RoundStarted value) roundStarted,
    required TResult Function(CardsDealt value) cardsDealt,
    required TResult Function(DeckCut value) deckCut,
    required TResult Function(CardPlayed value) cardPlayed,
    required TResult Function(GoAnnounced value) goAnnounced,
    required TResult Function(PeggingEnded value) peggingEnded,
    required TResult Function(HandCounted value) handCounted,
    required TResult Function(CribCounted value) cribCounted,
    required TResult Function(GameEnded value) gameEnded,
  }) {
    return goAnnounced(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RoundStarted value)? roundStarted,
    TResult? Function(CardsDealt value)? cardsDealt,
    TResult? Function(DeckCut value)? deckCut,
    TResult? Function(CardPlayed value)? cardPlayed,
    TResult? Function(GoAnnounced value)? goAnnounced,
    TResult? Function(PeggingEnded value)? peggingEnded,
    TResult? Function(HandCounted value)? handCounted,
    TResult? Function(CribCounted value)? cribCounted,
    TResult? Function(GameEnded value)? gameEnded,
  }) {
    return goAnnounced?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RoundStarted value)? roundStarted,
    TResult Function(CardsDealt value)? cardsDealt,
    TResult Function(DeckCut value)? deckCut,
    TResult Function(CardPlayed value)? cardPlayed,
    TResult Function(GoAnnounced value)? goAnnounced,
    TResult Function(PeggingEnded value)? peggingEnded,
    TResult Function(HandCounted value)? handCounted,
    TResult Function(CribCounted value)? cribCounted,
    TResult Function(GameEnded value)? gameEnded,
    required TResult orElse(),
  }) {
    if (goAnnounced != null) {
      return goAnnounced(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$GoAnnouncedImplToJson(this);
  }
}

abstract class GoAnnounced implements GameHistoryEvent {
  const factory GoAnnounced({
    required final String timestamp,
    required final String playerId,
    final int pointsScored,
  }) = _$GoAnnouncedImpl;

  factory GoAnnounced.fromJson(Map<String, dynamic> json) =
      _$GoAnnouncedImpl.fromJson;

  @override
  String get timestamp;
  String get playerId;
  int get pointsScored;

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GoAnnouncedImplCopyWith<_$GoAnnouncedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PeggingEndedImplCopyWith<$Res>
    implements $GameHistoryEventCopyWith<$Res> {
  factory _$$PeggingEndedImplCopyWith(
    _$PeggingEndedImpl value,
    $Res Function(_$PeggingEndedImpl) then,
  ) = __$$PeggingEndedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String timestamp});
}

/// @nodoc
class __$$PeggingEndedImplCopyWithImpl<$Res>
    extends _$GameHistoryEventCopyWithImpl<$Res, _$PeggingEndedImpl>
    implements _$$PeggingEndedImplCopyWith<$Res> {
  __$$PeggingEndedImplCopyWithImpl(
    _$PeggingEndedImpl _value,
    $Res Function(_$PeggingEndedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? timestamp = null}) {
    return _then(
      _$PeggingEndedImpl(
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PeggingEndedImpl implements PeggingEnded {
  const _$PeggingEndedImpl({required this.timestamp, final String? $type})
    : $type = $type ?? 'PeggingEnded';

  factory _$PeggingEndedImpl.fromJson(Map<String, dynamic> json) =>
      _$$PeggingEndedImplFromJson(json);

  @override
  final String timestamp;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'GameHistoryEvent.peggingEnded(timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PeggingEndedImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, timestamp);

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PeggingEndedImplCopyWith<_$PeggingEndedImpl> get copyWith =>
      __$$PeggingEndedImplCopyWithImpl<_$PeggingEndedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String timestamp, int roundNumber) roundStarted,
    required TResult Function(String timestamp) cardsDealt,
    required TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )
    deckCut,
    required TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )
    cardPlayed,
    required TResult Function(
      String timestamp,
      String playerId,
      int pointsScored,
    )
    goAnnounced,
    required TResult Function(String timestamp) peggingEnded,
    required TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    handCounted,
    required TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    cribCounted,
    required TResult Function(
      String timestamp,
      String winnerPlayerId,
      int finalScore,
    )
    gameEnded,
  }) {
    return peggingEnded(timestamp);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String timestamp, int roundNumber)? roundStarted,
    TResult? Function(String timestamp)? cardsDealt,
    TResult? Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult? Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult? Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult? Function(String timestamp)? peggingEnded,
    TResult? Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult? Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult? Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
  }) {
    return peggingEnded?.call(timestamp);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String timestamp, int roundNumber)? roundStarted,
    TResult Function(String timestamp)? cardsDealt,
    TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult Function(String timestamp)? peggingEnded,
    TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
    required TResult orElse(),
  }) {
    if (peggingEnded != null) {
      return peggingEnded(timestamp);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RoundStarted value) roundStarted,
    required TResult Function(CardsDealt value) cardsDealt,
    required TResult Function(DeckCut value) deckCut,
    required TResult Function(CardPlayed value) cardPlayed,
    required TResult Function(GoAnnounced value) goAnnounced,
    required TResult Function(PeggingEnded value) peggingEnded,
    required TResult Function(HandCounted value) handCounted,
    required TResult Function(CribCounted value) cribCounted,
    required TResult Function(GameEnded value) gameEnded,
  }) {
    return peggingEnded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RoundStarted value)? roundStarted,
    TResult? Function(CardsDealt value)? cardsDealt,
    TResult? Function(DeckCut value)? deckCut,
    TResult? Function(CardPlayed value)? cardPlayed,
    TResult? Function(GoAnnounced value)? goAnnounced,
    TResult? Function(PeggingEnded value)? peggingEnded,
    TResult? Function(HandCounted value)? handCounted,
    TResult? Function(CribCounted value)? cribCounted,
    TResult? Function(GameEnded value)? gameEnded,
  }) {
    return peggingEnded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RoundStarted value)? roundStarted,
    TResult Function(CardsDealt value)? cardsDealt,
    TResult Function(DeckCut value)? deckCut,
    TResult Function(CardPlayed value)? cardPlayed,
    TResult Function(GoAnnounced value)? goAnnounced,
    TResult Function(PeggingEnded value)? peggingEnded,
    TResult Function(HandCounted value)? handCounted,
    TResult Function(CribCounted value)? cribCounted,
    TResult Function(GameEnded value)? gameEnded,
    required TResult orElse(),
  }) {
    if (peggingEnded != null) {
      return peggingEnded(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PeggingEndedImplToJson(this);
  }
}

abstract class PeggingEnded implements GameHistoryEvent {
  const factory PeggingEnded({required final String timestamp}) =
      _$PeggingEndedImpl;

  factory PeggingEnded.fromJson(Map<String, dynamic> json) =
      _$PeggingEndedImpl.fromJson;

  @override
  String get timestamp;

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PeggingEndedImplCopyWith<_$PeggingEndedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$HandCountedImplCopyWith<$Res>
    implements $GameHistoryEventCopyWith<$Res> {
  factory _$$HandCountedImplCopyWith(
    _$HandCountedImpl value,
    $Res Function(_$HandCountedImpl) then,
  ) = __$$HandCountedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String timestamp,
    String playerId,
    int totalPoints,
    ScoreBreakdown scoreBreakdown,
  });

  $ScoreBreakdownCopyWith<$Res> get scoreBreakdown;
}

/// @nodoc
class __$$HandCountedImplCopyWithImpl<$Res>
    extends _$GameHistoryEventCopyWithImpl<$Res, _$HandCountedImpl>
    implements _$$HandCountedImplCopyWith<$Res> {
  __$$HandCountedImplCopyWithImpl(
    _$HandCountedImpl _value,
    $Res Function(_$HandCountedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? playerId = null,
    Object? totalPoints = null,
    Object? scoreBreakdown = null,
  }) {
    return _then(
      _$HandCountedImpl(
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String,
        playerId: null == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String,
        totalPoints: null == totalPoints
            ? _value.totalPoints
            : totalPoints // ignore: cast_nullable_to_non_nullable
                  as int,
        scoreBreakdown: null == scoreBreakdown
            ? _value.scoreBreakdown
            : scoreBreakdown // ignore: cast_nullable_to_non_nullable
                  as ScoreBreakdown,
      ),
    );
  }

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoreBreakdownCopyWith<$Res> get scoreBreakdown {
    return $ScoreBreakdownCopyWith<$Res>(_value.scoreBreakdown, (value) {
      return _then(_value.copyWith(scoreBreakdown: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$HandCountedImpl implements HandCounted {
  const _$HandCountedImpl({
    required this.timestamp,
    required this.playerId,
    required this.totalPoints,
    required this.scoreBreakdown,
    final String? $type,
  }) : $type = $type ?? 'HandCounted';

  factory _$HandCountedImpl.fromJson(Map<String, dynamic> json) =>
      _$$HandCountedImplFromJson(json);

  @override
  final String timestamp;
  @override
  final String playerId;
  @override
  final int totalPoints;
  @override
  final ScoreBreakdown scoreBreakdown;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'GameHistoryEvent.handCounted(timestamp: $timestamp, playerId: $playerId, totalPoints: $totalPoints, scoreBreakdown: $scoreBreakdown)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HandCountedImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.totalPoints, totalPoints) ||
                other.totalPoints == totalPoints) &&
            (identical(other.scoreBreakdown, scoreBreakdown) ||
                other.scoreBreakdown == scoreBreakdown));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    timestamp,
    playerId,
    totalPoints,
    scoreBreakdown,
  );

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HandCountedImplCopyWith<_$HandCountedImpl> get copyWith =>
      __$$HandCountedImplCopyWithImpl<_$HandCountedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String timestamp, int roundNumber) roundStarted,
    required TResult Function(String timestamp) cardsDealt,
    required TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )
    deckCut,
    required TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )
    cardPlayed,
    required TResult Function(
      String timestamp,
      String playerId,
      int pointsScored,
    )
    goAnnounced,
    required TResult Function(String timestamp) peggingEnded,
    required TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    handCounted,
    required TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    cribCounted,
    required TResult Function(
      String timestamp,
      String winnerPlayerId,
      int finalScore,
    )
    gameEnded,
  }) {
    return handCounted(timestamp, playerId, totalPoints, scoreBreakdown);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String timestamp, int roundNumber)? roundStarted,
    TResult? Function(String timestamp)? cardsDealt,
    TResult? Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult? Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult? Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult? Function(String timestamp)? peggingEnded,
    TResult? Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult? Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult? Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
  }) {
    return handCounted?.call(timestamp, playerId, totalPoints, scoreBreakdown);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String timestamp, int roundNumber)? roundStarted,
    TResult Function(String timestamp)? cardsDealt,
    TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult Function(String timestamp)? peggingEnded,
    TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
    required TResult orElse(),
  }) {
    if (handCounted != null) {
      return handCounted(timestamp, playerId, totalPoints, scoreBreakdown);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RoundStarted value) roundStarted,
    required TResult Function(CardsDealt value) cardsDealt,
    required TResult Function(DeckCut value) deckCut,
    required TResult Function(CardPlayed value) cardPlayed,
    required TResult Function(GoAnnounced value) goAnnounced,
    required TResult Function(PeggingEnded value) peggingEnded,
    required TResult Function(HandCounted value) handCounted,
    required TResult Function(CribCounted value) cribCounted,
    required TResult Function(GameEnded value) gameEnded,
  }) {
    return handCounted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RoundStarted value)? roundStarted,
    TResult? Function(CardsDealt value)? cardsDealt,
    TResult? Function(DeckCut value)? deckCut,
    TResult? Function(CardPlayed value)? cardPlayed,
    TResult? Function(GoAnnounced value)? goAnnounced,
    TResult? Function(PeggingEnded value)? peggingEnded,
    TResult? Function(HandCounted value)? handCounted,
    TResult? Function(CribCounted value)? cribCounted,
    TResult? Function(GameEnded value)? gameEnded,
  }) {
    return handCounted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RoundStarted value)? roundStarted,
    TResult Function(CardsDealt value)? cardsDealt,
    TResult Function(DeckCut value)? deckCut,
    TResult Function(CardPlayed value)? cardPlayed,
    TResult Function(GoAnnounced value)? goAnnounced,
    TResult Function(PeggingEnded value)? peggingEnded,
    TResult Function(HandCounted value)? handCounted,
    TResult Function(CribCounted value)? cribCounted,
    TResult Function(GameEnded value)? gameEnded,
    required TResult orElse(),
  }) {
    if (handCounted != null) {
      return handCounted(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$HandCountedImplToJson(this);
  }
}

abstract class HandCounted implements GameHistoryEvent {
  const factory HandCounted({
    required final String timestamp,
    required final String playerId,
    required final int totalPoints,
    required final ScoreBreakdown scoreBreakdown,
  }) = _$HandCountedImpl;

  factory HandCounted.fromJson(Map<String, dynamic> json) =
      _$HandCountedImpl.fromJson;

  @override
  String get timestamp;
  String get playerId;
  int get totalPoints;
  ScoreBreakdown get scoreBreakdown;

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HandCountedImplCopyWith<_$HandCountedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CribCountedImplCopyWith<$Res>
    implements $GameHistoryEventCopyWith<$Res> {
  factory _$$CribCountedImplCopyWith(
    _$CribCountedImpl value,
    $Res Function(_$CribCountedImpl) then,
  ) = __$$CribCountedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String timestamp,
    String dealerPlayerId,
    int totalPoints,
    ScoreBreakdown scoreBreakdown,
  });

  $ScoreBreakdownCopyWith<$Res> get scoreBreakdown;
}

/// @nodoc
class __$$CribCountedImplCopyWithImpl<$Res>
    extends _$GameHistoryEventCopyWithImpl<$Res, _$CribCountedImpl>
    implements _$$CribCountedImplCopyWith<$Res> {
  __$$CribCountedImplCopyWithImpl(
    _$CribCountedImpl _value,
    $Res Function(_$CribCountedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? dealerPlayerId = null,
    Object? totalPoints = null,
    Object? scoreBreakdown = null,
  }) {
    return _then(
      _$CribCountedImpl(
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String,
        dealerPlayerId: null == dealerPlayerId
            ? _value.dealerPlayerId
            : dealerPlayerId // ignore: cast_nullable_to_non_nullable
                  as String,
        totalPoints: null == totalPoints
            ? _value.totalPoints
            : totalPoints // ignore: cast_nullable_to_non_nullable
                  as int,
        scoreBreakdown: null == scoreBreakdown
            ? _value.scoreBreakdown
            : scoreBreakdown // ignore: cast_nullable_to_non_nullable
                  as ScoreBreakdown,
      ),
    );
  }

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoreBreakdownCopyWith<$Res> get scoreBreakdown {
    return $ScoreBreakdownCopyWith<$Res>(_value.scoreBreakdown, (value) {
      return _then(_value.copyWith(scoreBreakdown: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$CribCountedImpl implements CribCounted {
  const _$CribCountedImpl({
    required this.timestamp,
    required this.dealerPlayerId,
    required this.totalPoints,
    required this.scoreBreakdown,
    final String? $type,
  }) : $type = $type ?? 'CribCounted';

  factory _$CribCountedImpl.fromJson(Map<String, dynamic> json) =>
      _$$CribCountedImplFromJson(json);

  @override
  final String timestamp;
  @override
  final String dealerPlayerId;
  @override
  final int totalPoints;
  @override
  final ScoreBreakdown scoreBreakdown;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'GameHistoryEvent.cribCounted(timestamp: $timestamp, dealerPlayerId: $dealerPlayerId, totalPoints: $totalPoints, scoreBreakdown: $scoreBreakdown)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CribCountedImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.dealerPlayerId, dealerPlayerId) ||
                other.dealerPlayerId == dealerPlayerId) &&
            (identical(other.totalPoints, totalPoints) ||
                other.totalPoints == totalPoints) &&
            (identical(other.scoreBreakdown, scoreBreakdown) ||
                other.scoreBreakdown == scoreBreakdown));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    timestamp,
    dealerPlayerId,
    totalPoints,
    scoreBreakdown,
  );

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CribCountedImplCopyWith<_$CribCountedImpl> get copyWith =>
      __$$CribCountedImplCopyWithImpl<_$CribCountedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String timestamp, int roundNumber) roundStarted,
    required TResult Function(String timestamp) cardsDealt,
    required TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )
    deckCut,
    required TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )
    cardPlayed,
    required TResult Function(
      String timestamp,
      String playerId,
      int pointsScored,
    )
    goAnnounced,
    required TResult Function(String timestamp) peggingEnded,
    required TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    handCounted,
    required TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    cribCounted,
    required TResult Function(
      String timestamp,
      String winnerPlayerId,
      int finalScore,
    )
    gameEnded,
  }) {
    return cribCounted(timestamp, dealerPlayerId, totalPoints, scoreBreakdown);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String timestamp, int roundNumber)? roundStarted,
    TResult? Function(String timestamp)? cardsDealt,
    TResult? Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult? Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult? Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult? Function(String timestamp)? peggingEnded,
    TResult? Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult? Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult? Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
  }) {
    return cribCounted?.call(
      timestamp,
      dealerPlayerId,
      totalPoints,
      scoreBreakdown,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String timestamp, int roundNumber)? roundStarted,
    TResult Function(String timestamp)? cardsDealt,
    TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult Function(String timestamp)? peggingEnded,
    TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
    required TResult orElse(),
  }) {
    if (cribCounted != null) {
      return cribCounted(
        timestamp,
        dealerPlayerId,
        totalPoints,
        scoreBreakdown,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RoundStarted value) roundStarted,
    required TResult Function(CardsDealt value) cardsDealt,
    required TResult Function(DeckCut value) deckCut,
    required TResult Function(CardPlayed value) cardPlayed,
    required TResult Function(GoAnnounced value) goAnnounced,
    required TResult Function(PeggingEnded value) peggingEnded,
    required TResult Function(HandCounted value) handCounted,
    required TResult Function(CribCounted value) cribCounted,
    required TResult Function(GameEnded value) gameEnded,
  }) {
    return cribCounted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RoundStarted value)? roundStarted,
    TResult? Function(CardsDealt value)? cardsDealt,
    TResult? Function(DeckCut value)? deckCut,
    TResult? Function(CardPlayed value)? cardPlayed,
    TResult? Function(GoAnnounced value)? goAnnounced,
    TResult? Function(PeggingEnded value)? peggingEnded,
    TResult? Function(HandCounted value)? handCounted,
    TResult? Function(CribCounted value)? cribCounted,
    TResult? Function(GameEnded value)? gameEnded,
  }) {
    return cribCounted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RoundStarted value)? roundStarted,
    TResult Function(CardsDealt value)? cardsDealt,
    TResult Function(DeckCut value)? deckCut,
    TResult Function(CardPlayed value)? cardPlayed,
    TResult Function(GoAnnounced value)? goAnnounced,
    TResult Function(PeggingEnded value)? peggingEnded,
    TResult Function(HandCounted value)? handCounted,
    TResult Function(CribCounted value)? cribCounted,
    TResult Function(GameEnded value)? gameEnded,
    required TResult orElse(),
  }) {
    if (cribCounted != null) {
      return cribCounted(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CribCountedImplToJson(this);
  }
}

abstract class CribCounted implements GameHistoryEvent {
  const factory CribCounted({
    required final String timestamp,
    required final String dealerPlayerId,
    required final int totalPoints,
    required final ScoreBreakdown scoreBreakdown,
  }) = _$CribCountedImpl;

  factory CribCounted.fromJson(Map<String, dynamic> json) =
      _$CribCountedImpl.fromJson;

  @override
  String get timestamp;
  String get dealerPlayerId;
  int get totalPoints;
  ScoreBreakdown get scoreBreakdown;

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CribCountedImplCopyWith<_$CribCountedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GameEndedImplCopyWith<$Res>
    implements $GameHistoryEventCopyWith<$Res> {
  factory _$$GameEndedImplCopyWith(
    _$GameEndedImpl value,
    $Res Function(_$GameEndedImpl) then,
  ) = __$$GameEndedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String timestamp, String winnerPlayerId, int finalScore});
}

/// @nodoc
class __$$GameEndedImplCopyWithImpl<$Res>
    extends _$GameHistoryEventCopyWithImpl<$Res, _$GameEndedImpl>
    implements _$$GameEndedImplCopyWith<$Res> {
  __$$GameEndedImplCopyWithImpl(
    _$GameEndedImpl _value,
    $Res Function(_$GameEndedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? winnerPlayerId = null,
    Object? finalScore = null,
  }) {
    return _then(
      _$GameEndedImpl(
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as String,
        winnerPlayerId: null == winnerPlayerId
            ? _value.winnerPlayerId
            : winnerPlayerId // ignore: cast_nullable_to_non_nullable
                  as String,
        finalScore: null == finalScore
            ? _value.finalScore
            : finalScore // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GameEndedImpl implements GameEnded {
  const _$GameEndedImpl({
    required this.timestamp,
    required this.winnerPlayerId,
    required this.finalScore,
    final String? $type,
  }) : $type = $type ?? 'GameEnded';

  factory _$GameEndedImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameEndedImplFromJson(json);

  @override
  final String timestamp;
  @override
  final String winnerPlayerId;
  @override
  final int finalScore;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'GameHistoryEvent.gameEnded(timestamp: $timestamp, winnerPlayerId: $winnerPlayerId, finalScore: $finalScore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameEndedImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.winnerPlayerId, winnerPlayerId) ||
                other.winnerPlayerId == winnerPlayerId) &&
            (identical(other.finalScore, finalScore) ||
                other.finalScore == finalScore));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, timestamp, winnerPlayerId, finalScore);

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameEndedImplCopyWith<_$GameEndedImpl> get copyWith =>
      __$$GameEndedImplCopyWithImpl<_$GameEndedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String timestamp, int roundNumber) roundStarted,
    required TResult Function(String timestamp) cardsDealt,
    required TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )
    deckCut,
    required TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )
    cardPlayed,
    required TResult Function(
      String timestamp,
      String playerId,
      int pointsScored,
    )
    goAnnounced,
    required TResult Function(String timestamp) peggingEnded,
    required TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    handCounted,
    required TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )
    cribCounted,
    required TResult Function(
      String timestamp,
      String winnerPlayerId,
      int finalScore,
    )
    gameEnded,
  }) {
    return gameEnded(timestamp, winnerPlayerId, finalScore);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String timestamp, int roundNumber)? roundStarted,
    TResult? Function(String timestamp)? cardsDealt,
    TResult? Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult? Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult? Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult? Function(String timestamp)? peggingEnded,
    TResult? Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult? Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult? Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
  }) {
    return gameEnded?.call(timestamp, winnerPlayerId, finalScore);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String timestamp, int roundNumber)? roundStarted,
    TResult Function(String timestamp)? cardsDealt,
    TResult Function(
      String timestamp,
      PlayingCard cutCard,
      String cuttingPlayerId,
      bool dealerScoredNobs,
    )?
    deckCut,
    TResult Function(
      String timestamp,
      String playerId,
      PlayingCard card,
      int newCount,
      int pointsScored,
      String? scoringReason,
    )?
    cardPlayed,
    TResult Function(String timestamp, String playerId, int pointsScored)?
    goAnnounced,
    TResult Function(String timestamp)? peggingEnded,
    TResult Function(
      String timestamp,
      String playerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    handCounted,
    TResult Function(
      String timestamp,
      String dealerPlayerId,
      int totalPoints,
      ScoreBreakdown scoreBreakdown,
    )?
    cribCounted,
    TResult Function(String timestamp, String winnerPlayerId, int finalScore)?
    gameEnded,
    required TResult orElse(),
  }) {
    if (gameEnded != null) {
      return gameEnded(timestamp, winnerPlayerId, finalScore);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RoundStarted value) roundStarted,
    required TResult Function(CardsDealt value) cardsDealt,
    required TResult Function(DeckCut value) deckCut,
    required TResult Function(CardPlayed value) cardPlayed,
    required TResult Function(GoAnnounced value) goAnnounced,
    required TResult Function(PeggingEnded value) peggingEnded,
    required TResult Function(HandCounted value) handCounted,
    required TResult Function(CribCounted value) cribCounted,
    required TResult Function(GameEnded value) gameEnded,
  }) {
    return gameEnded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RoundStarted value)? roundStarted,
    TResult? Function(CardsDealt value)? cardsDealt,
    TResult? Function(DeckCut value)? deckCut,
    TResult? Function(CardPlayed value)? cardPlayed,
    TResult? Function(GoAnnounced value)? goAnnounced,
    TResult? Function(PeggingEnded value)? peggingEnded,
    TResult? Function(HandCounted value)? handCounted,
    TResult? Function(CribCounted value)? cribCounted,
    TResult? Function(GameEnded value)? gameEnded,
  }) {
    return gameEnded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RoundStarted value)? roundStarted,
    TResult Function(CardsDealt value)? cardsDealt,
    TResult Function(DeckCut value)? deckCut,
    TResult Function(CardPlayed value)? cardPlayed,
    TResult Function(GoAnnounced value)? goAnnounced,
    TResult Function(PeggingEnded value)? peggingEnded,
    TResult Function(HandCounted value)? handCounted,
    TResult Function(CribCounted value)? cribCounted,
    TResult Function(GameEnded value)? gameEnded,
    required TResult orElse(),
  }) {
    if (gameEnded != null) {
      return gameEnded(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$GameEndedImplToJson(this);
  }
}

abstract class GameEnded implements GameHistoryEvent {
  const factory GameEnded({
    required final String timestamp,
    required final String winnerPlayerId,
    required final int finalScore,
  }) = _$GameEndedImpl;

  factory GameEnded.fromJson(Map<String, dynamic> json) =
      _$GameEndedImpl.fromJson;

  @override
  String get timestamp;
  String get winnerPlayerId;
  int get finalScore;

  /// Create a copy of GameHistoryEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameEndedImplCopyWith<_$GameEndedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
