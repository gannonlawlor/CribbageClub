// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GameAction _$GameActionFromJson(Map<String, dynamic> json) {
  switch (json['type']) {
    case 'DiscardToCrib':
      return DiscardToCrib.fromJson(json);
    case 'PlayCard':
      return PlayCard.fromJson(json);
    case 'CutDeck':
      return CutDeck.fromJson(json);
    case 'Go':
      return Go.fromJson(json);
    case 'CountHand':
      return CountHand.fromJson(json);
    case 'Forfeit':
      return ForfeitAction.fromJson(json);

    default:
      throw CheckedFromJsonException(
        json,
        'type',
        'GameAction',
        'Invalid union type "${json['type']}"!',
      );
  }
}

/// @nodoc
mixin _$GameAction {
  String get playerId => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String playerId, PlayingCard card) discardToCrib,
    required TResult Function(String playerId, PlayingCard card) playCard,
    required TResult Function(String playerId) cutDeck,
    required TResult Function(String playerId) go,
    required TResult Function(String playerId) countHand,
    required TResult Function(String playerId, String reason) forfeit,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String playerId, PlayingCard card)? discardToCrib,
    TResult? Function(String playerId, PlayingCard card)? playCard,
    TResult? Function(String playerId)? cutDeck,
    TResult? Function(String playerId)? go,
    TResult? Function(String playerId)? countHand,
    TResult? Function(String playerId, String reason)? forfeit,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String playerId, PlayingCard card)? discardToCrib,
    TResult Function(String playerId, PlayingCard card)? playCard,
    TResult Function(String playerId)? cutDeck,
    TResult Function(String playerId)? go,
    TResult Function(String playerId)? countHand,
    TResult Function(String playerId, String reason)? forfeit,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DiscardToCrib value) discardToCrib,
    required TResult Function(PlayCard value) playCard,
    required TResult Function(CutDeck value) cutDeck,
    required TResult Function(Go value) go,
    required TResult Function(CountHand value) countHand,
    required TResult Function(ForfeitAction value) forfeit,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DiscardToCrib value)? discardToCrib,
    TResult? Function(PlayCard value)? playCard,
    TResult? Function(CutDeck value)? cutDeck,
    TResult? Function(Go value)? go,
    TResult? Function(CountHand value)? countHand,
    TResult? Function(ForfeitAction value)? forfeit,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DiscardToCrib value)? discardToCrib,
    TResult Function(PlayCard value)? playCard,
    TResult Function(CutDeck value)? cutDeck,
    TResult Function(Go value)? go,
    TResult Function(CountHand value)? countHand,
    TResult Function(ForfeitAction value)? forfeit,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Serializes this GameAction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameActionCopyWith<GameAction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameActionCopyWith<$Res> {
  factory $GameActionCopyWith(
    GameAction value,
    $Res Function(GameAction) then,
  ) = _$GameActionCopyWithImpl<$Res, GameAction>;
  @useResult
  $Res call({String playerId});
}

/// @nodoc
class _$GameActionCopyWithImpl<$Res, $Val extends GameAction>
    implements $GameActionCopyWith<$Res> {
  _$GameActionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? playerId = null}) {
    return _then(
      _value.copyWith(
            playerId: null == playerId
                ? _value.playerId
                : playerId // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DiscardToCribImplCopyWith<$Res>
    implements $GameActionCopyWith<$Res> {
  factory _$$DiscardToCribImplCopyWith(
    _$DiscardToCribImpl value,
    $Res Function(_$DiscardToCribImpl) then,
  ) = __$$DiscardToCribImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String playerId, PlayingCard card});

  $PlayingCardCopyWith<$Res> get card;
}

/// @nodoc
class __$$DiscardToCribImplCopyWithImpl<$Res>
    extends _$GameActionCopyWithImpl<$Res, _$DiscardToCribImpl>
    implements _$$DiscardToCribImplCopyWith<$Res> {
  __$$DiscardToCribImplCopyWithImpl(
    _$DiscardToCribImpl _value,
    $Res Function(_$DiscardToCribImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? playerId = null, Object? card = null}) {
    return _then(
      _$DiscardToCribImpl(
        playerId: null == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String,
        card: null == card
            ? _value.card
            : card // ignore: cast_nullable_to_non_nullable
                  as PlayingCard,
      ),
    );
  }

  /// Create a copy of GameAction
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
class _$DiscardToCribImpl implements DiscardToCrib {
  const _$DiscardToCribImpl({
    required this.playerId,
    required this.card,
    final String? $type,
  }) : $type = $type ?? 'DiscardToCrib';

  factory _$DiscardToCribImpl.fromJson(Map<String, dynamic> json) =>
      _$$DiscardToCribImplFromJson(json);

  @override
  final String playerId;
  @override
  final PlayingCard card;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'GameAction.discardToCrib(playerId: $playerId, card: $card)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiscardToCribImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.card, card) || other.card == card));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, playerId, card);

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiscardToCribImplCopyWith<_$DiscardToCribImpl> get copyWith =>
      __$$DiscardToCribImplCopyWithImpl<_$DiscardToCribImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String playerId, PlayingCard card) discardToCrib,
    required TResult Function(String playerId, PlayingCard card) playCard,
    required TResult Function(String playerId) cutDeck,
    required TResult Function(String playerId) go,
    required TResult Function(String playerId) countHand,
    required TResult Function(String playerId, String reason) forfeit,
  }) {
    return discardToCrib(playerId, card);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String playerId, PlayingCard card)? discardToCrib,
    TResult? Function(String playerId, PlayingCard card)? playCard,
    TResult? Function(String playerId)? cutDeck,
    TResult? Function(String playerId)? go,
    TResult? Function(String playerId)? countHand,
    TResult? Function(String playerId, String reason)? forfeit,
  }) {
    return discardToCrib?.call(playerId, card);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String playerId, PlayingCard card)? discardToCrib,
    TResult Function(String playerId, PlayingCard card)? playCard,
    TResult Function(String playerId)? cutDeck,
    TResult Function(String playerId)? go,
    TResult Function(String playerId)? countHand,
    TResult Function(String playerId, String reason)? forfeit,
    required TResult orElse(),
  }) {
    if (discardToCrib != null) {
      return discardToCrib(playerId, card);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DiscardToCrib value) discardToCrib,
    required TResult Function(PlayCard value) playCard,
    required TResult Function(CutDeck value) cutDeck,
    required TResult Function(Go value) go,
    required TResult Function(CountHand value) countHand,
    required TResult Function(ForfeitAction value) forfeit,
  }) {
    return discardToCrib(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DiscardToCrib value)? discardToCrib,
    TResult? Function(PlayCard value)? playCard,
    TResult? Function(CutDeck value)? cutDeck,
    TResult? Function(Go value)? go,
    TResult? Function(CountHand value)? countHand,
    TResult? Function(ForfeitAction value)? forfeit,
  }) {
    return discardToCrib?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DiscardToCrib value)? discardToCrib,
    TResult Function(PlayCard value)? playCard,
    TResult Function(CutDeck value)? cutDeck,
    TResult Function(Go value)? go,
    TResult Function(CountHand value)? countHand,
    TResult Function(ForfeitAction value)? forfeit,
    required TResult orElse(),
  }) {
    if (discardToCrib != null) {
      return discardToCrib(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$DiscardToCribImplToJson(this);
  }
}

abstract class DiscardToCrib implements GameAction {
  const factory DiscardToCrib({
    required final String playerId,
    required final PlayingCard card,
  }) = _$DiscardToCribImpl;

  factory DiscardToCrib.fromJson(Map<String, dynamic> json) =
      _$DiscardToCribImpl.fromJson;

  @override
  String get playerId;
  PlayingCard get card;

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiscardToCribImplCopyWith<_$DiscardToCribImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PlayCardImplCopyWith<$Res>
    implements $GameActionCopyWith<$Res> {
  factory _$$PlayCardImplCopyWith(
    _$PlayCardImpl value,
    $Res Function(_$PlayCardImpl) then,
  ) = __$$PlayCardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String playerId, PlayingCard card});

  $PlayingCardCopyWith<$Res> get card;
}

/// @nodoc
class __$$PlayCardImplCopyWithImpl<$Res>
    extends _$GameActionCopyWithImpl<$Res, _$PlayCardImpl>
    implements _$$PlayCardImplCopyWith<$Res> {
  __$$PlayCardImplCopyWithImpl(
    _$PlayCardImpl _value,
    $Res Function(_$PlayCardImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? playerId = null, Object? card = null}) {
    return _then(
      _$PlayCardImpl(
        playerId: null == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String,
        card: null == card
            ? _value.card
            : card // ignore: cast_nullable_to_non_nullable
                  as PlayingCard,
      ),
    );
  }

  /// Create a copy of GameAction
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
class _$PlayCardImpl implements PlayCard {
  const _$PlayCardImpl({
    required this.playerId,
    required this.card,
    final String? $type,
  }) : $type = $type ?? 'PlayCard';

  factory _$PlayCardImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayCardImplFromJson(json);

  @override
  final String playerId;
  @override
  final PlayingCard card;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'GameAction.playCard(playerId: $playerId, card: $card)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayCardImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.card, card) || other.card == card));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, playerId, card);

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayCardImplCopyWith<_$PlayCardImpl> get copyWith =>
      __$$PlayCardImplCopyWithImpl<_$PlayCardImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String playerId, PlayingCard card) discardToCrib,
    required TResult Function(String playerId, PlayingCard card) playCard,
    required TResult Function(String playerId) cutDeck,
    required TResult Function(String playerId) go,
    required TResult Function(String playerId) countHand,
    required TResult Function(String playerId, String reason) forfeit,
  }) {
    return playCard(playerId, card);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String playerId, PlayingCard card)? discardToCrib,
    TResult? Function(String playerId, PlayingCard card)? playCard,
    TResult? Function(String playerId)? cutDeck,
    TResult? Function(String playerId)? go,
    TResult? Function(String playerId)? countHand,
    TResult? Function(String playerId, String reason)? forfeit,
  }) {
    return playCard?.call(playerId, card);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String playerId, PlayingCard card)? discardToCrib,
    TResult Function(String playerId, PlayingCard card)? playCard,
    TResult Function(String playerId)? cutDeck,
    TResult Function(String playerId)? go,
    TResult Function(String playerId)? countHand,
    TResult Function(String playerId, String reason)? forfeit,
    required TResult orElse(),
  }) {
    if (playCard != null) {
      return playCard(playerId, card);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DiscardToCrib value) discardToCrib,
    required TResult Function(PlayCard value) playCard,
    required TResult Function(CutDeck value) cutDeck,
    required TResult Function(Go value) go,
    required TResult Function(CountHand value) countHand,
    required TResult Function(ForfeitAction value) forfeit,
  }) {
    return playCard(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DiscardToCrib value)? discardToCrib,
    TResult? Function(PlayCard value)? playCard,
    TResult? Function(CutDeck value)? cutDeck,
    TResult? Function(Go value)? go,
    TResult? Function(CountHand value)? countHand,
    TResult? Function(ForfeitAction value)? forfeit,
  }) {
    return playCard?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DiscardToCrib value)? discardToCrib,
    TResult Function(PlayCard value)? playCard,
    TResult Function(CutDeck value)? cutDeck,
    TResult Function(Go value)? go,
    TResult Function(CountHand value)? countHand,
    TResult Function(ForfeitAction value)? forfeit,
    required TResult orElse(),
  }) {
    if (playCard != null) {
      return playCard(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayCardImplToJson(this);
  }
}

abstract class PlayCard implements GameAction {
  const factory PlayCard({
    required final String playerId,
    required final PlayingCard card,
  }) = _$PlayCardImpl;

  factory PlayCard.fromJson(Map<String, dynamic> json) =
      _$PlayCardImpl.fromJson;

  @override
  String get playerId;
  PlayingCard get card;

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayCardImplCopyWith<_$PlayCardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CutDeckImplCopyWith<$Res>
    implements $GameActionCopyWith<$Res> {
  factory _$$CutDeckImplCopyWith(
    _$CutDeckImpl value,
    $Res Function(_$CutDeckImpl) then,
  ) = __$$CutDeckImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String playerId});
}

/// @nodoc
class __$$CutDeckImplCopyWithImpl<$Res>
    extends _$GameActionCopyWithImpl<$Res, _$CutDeckImpl>
    implements _$$CutDeckImplCopyWith<$Res> {
  __$$CutDeckImplCopyWithImpl(
    _$CutDeckImpl _value,
    $Res Function(_$CutDeckImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? playerId = null}) {
    return _then(
      _$CutDeckImpl(
        playerId: null == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CutDeckImpl implements CutDeck {
  const _$CutDeckImpl({required this.playerId, final String? $type})
    : $type = $type ?? 'CutDeck';

  factory _$CutDeckImpl.fromJson(Map<String, dynamic> json) =>
      _$$CutDeckImplFromJson(json);

  @override
  final String playerId;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'GameAction.cutDeck(playerId: $playerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CutDeckImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, playerId);

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CutDeckImplCopyWith<_$CutDeckImpl> get copyWith =>
      __$$CutDeckImplCopyWithImpl<_$CutDeckImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String playerId, PlayingCard card) discardToCrib,
    required TResult Function(String playerId, PlayingCard card) playCard,
    required TResult Function(String playerId) cutDeck,
    required TResult Function(String playerId) go,
    required TResult Function(String playerId) countHand,
    required TResult Function(String playerId, String reason) forfeit,
  }) {
    return cutDeck(playerId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String playerId, PlayingCard card)? discardToCrib,
    TResult? Function(String playerId, PlayingCard card)? playCard,
    TResult? Function(String playerId)? cutDeck,
    TResult? Function(String playerId)? go,
    TResult? Function(String playerId)? countHand,
    TResult? Function(String playerId, String reason)? forfeit,
  }) {
    return cutDeck?.call(playerId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String playerId, PlayingCard card)? discardToCrib,
    TResult Function(String playerId, PlayingCard card)? playCard,
    TResult Function(String playerId)? cutDeck,
    TResult Function(String playerId)? go,
    TResult Function(String playerId)? countHand,
    TResult Function(String playerId, String reason)? forfeit,
    required TResult orElse(),
  }) {
    if (cutDeck != null) {
      return cutDeck(playerId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DiscardToCrib value) discardToCrib,
    required TResult Function(PlayCard value) playCard,
    required TResult Function(CutDeck value) cutDeck,
    required TResult Function(Go value) go,
    required TResult Function(CountHand value) countHand,
    required TResult Function(ForfeitAction value) forfeit,
  }) {
    return cutDeck(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DiscardToCrib value)? discardToCrib,
    TResult? Function(PlayCard value)? playCard,
    TResult? Function(CutDeck value)? cutDeck,
    TResult? Function(Go value)? go,
    TResult? Function(CountHand value)? countHand,
    TResult? Function(ForfeitAction value)? forfeit,
  }) {
    return cutDeck?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DiscardToCrib value)? discardToCrib,
    TResult Function(PlayCard value)? playCard,
    TResult Function(CutDeck value)? cutDeck,
    TResult Function(Go value)? go,
    TResult Function(CountHand value)? countHand,
    TResult Function(ForfeitAction value)? forfeit,
    required TResult orElse(),
  }) {
    if (cutDeck != null) {
      return cutDeck(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CutDeckImplToJson(this);
  }
}

abstract class CutDeck implements GameAction {
  const factory CutDeck({required final String playerId}) = _$CutDeckImpl;

  factory CutDeck.fromJson(Map<String, dynamic> json) = _$CutDeckImpl.fromJson;

  @override
  String get playerId;

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CutDeckImplCopyWith<_$CutDeckImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GoImplCopyWith<$Res> implements $GameActionCopyWith<$Res> {
  factory _$$GoImplCopyWith(_$GoImpl value, $Res Function(_$GoImpl) then) =
      __$$GoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String playerId});
}

/// @nodoc
class __$$GoImplCopyWithImpl<$Res>
    extends _$GameActionCopyWithImpl<$Res, _$GoImpl>
    implements _$$GoImplCopyWith<$Res> {
  __$$GoImplCopyWithImpl(_$GoImpl _value, $Res Function(_$GoImpl) _then)
    : super(_value, _then);

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? playerId = null}) {
    return _then(
      _$GoImpl(
        playerId: null == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GoImpl implements Go {
  const _$GoImpl({required this.playerId, final String? $type})
    : $type = $type ?? 'Go';

  factory _$GoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GoImplFromJson(json);

  @override
  final String playerId;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'GameAction.go(playerId: $playerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, playerId);

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GoImplCopyWith<_$GoImpl> get copyWith =>
      __$$GoImplCopyWithImpl<_$GoImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String playerId, PlayingCard card) discardToCrib,
    required TResult Function(String playerId, PlayingCard card) playCard,
    required TResult Function(String playerId) cutDeck,
    required TResult Function(String playerId) go,
    required TResult Function(String playerId) countHand,
    required TResult Function(String playerId, String reason) forfeit,
  }) {
    return go(playerId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String playerId, PlayingCard card)? discardToCrib,
    TResult? Function(String playerId, PlayingCard card)? playCard,
    TResult? Function(String playerId)? cutDeck,
    TResult? Function(String playerId)? go,
    TResult? Function(String playerId)? countHand,
    TResult? Function(String playerId, String reason)? forfeit,
  }) {
    return go?.call(playerId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String playerId, PlayingCard card)? discardToCrib,
    TResult Function(String playerId, PlayingCard card)? playCard,
    TResult Function(String playerId)? cutDeck,
    TResult Function(String playerId)? go,
    TResult Function(String playerId)? countHand,
    TResult Function(String playerId, String reason)? forfeit,
    required TResult orElse(),
  }) {
    if (go != null) {
      return go(playerId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DiscardToCrib value) discardToCrib,
    required TResult Function(PlayCard value) playCard,
    required TResult Function(CutDeck value) cutDeck,
    required TResult Function(Go value) go,
    required TResult Function(CountHand value) countHand,
    required TResult Function(ForfeitAction value) forfeit,
  }) {
    return go(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DiscardToCrib value)? discardToCrib,
    TResult? Function(PlayCard value)? playCard,
    TResult? Function(CutDeck value)? cutDeck,
    TResult? Function(Go value)? go,
    TResult? Function(CountHand value)? countHand,
    TResult? Function(ForfeitAction value)? forfeit,
  }) {
    return go?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DiscardToCrib value)? discardToCrib,
    TResult Function(PlayCard value)? playCard,
    TResult Function(CutDeck value)? cutDeck,
    TResult Function(Go value)? go,
    TResult Function(CountHand value)? countHand,
    TResult Function(ForfeitAction value)? forfeit,
    required TResult orElse(),
  }) {
    if (go != null) {
      return go(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$GoImplToJson(this);
  }
}

abstract class Go implements GameAction {
  const factory Go({required final String playerId}) = _$GoImpl;

  factory Go.fromJson(Map<String, dynamic> json) = _$GoImpl.fromJson;

  @override
  String get playerId;

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GoImplCopyWith<_$GoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CountHandImplCopyWith<$Res>
    implements $GameActionCopyWith<$Res> {
  factory _$$CountHandImplCopyWith(
    _$CountHandImpl value,
    $Res Function(_$CountHandImpl) then,
  ) = __$$CountHandImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String playerId});
}

/// @nodoc
class __$$CountHandImplCopyWithImpl<$Res>
    extends _$GameActionCopyWithImpl<$Res, _$CountHandImpl>
    implements _$$CountHandImplCopyWith<$Res> {
  __$$CountHandImplCopyWithImpl(
    _$CountHandImpl _value,
    $Res Function(_$CountHandImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? playerId = null}) {
    return _then(
      _$CountHandImpl(
        playerId: null == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CountHandImpl implements CountHand {
  const _$CountHandImpl({required this.playerId, final String? $type})
    : $type = $type ?? 'CountHand';

  factory _$CountHandImpl.fromJson(Map<String, dynamic> json) =>
      _$$CountHandImplFromJson(json);

  @override
  final String playerId;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'GameAction.countHand(playerId: $playerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CountHandImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, playerId);

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CountHandImplCopyWith<_$CountHandImpl> get copyWith =>
      __$$CountHandImplCopyWithImpl<_$CountHandImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String playerId, PlayingCard card) discardToCrib,
    required TResult Function(String playerId, PlayingCard card) playCard,
    required TResult Function(String playerId) cutDeck,
    required TResult Function(String playerId) go,
    required TResult Function(String playerId) countHand,
    required TResult Function(String playerId, String reason) forfeit,
  }) {
    return countHand(playerId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String playerId, PlayingCard card)? discardToCrib,
    TResult? Function(String playerId, PlayingCard card)? playCard,
    TResult? Function(String playerId)? cutDeck,
    TResult? Function(String playerId)? go,
    TResult? Function(String playerId)? countHand,
    TResult? Function(String playerId, String reason)? forfeit,
  }) {
    return countHand?.call(playerId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String playerId, PlayingCard card)? discardToCrib,
    TResult Function(String playerId, PlayingCard card)? playCard,
    TResult Function(String playerId)? cutDeck,
    TResult Function(String playerId)? go,
    TResult Function(String playerId)? countHand,
    TResult Function(String playerId, String reason)? forfeit,
    required TResult orElse(),
  }) {
    if (countHand != null) {
      return countHand(playerId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DiscardToCrib value) discardToCrib,
    required TResult Function(PlayCard value) playCard,
    required TResult Function(CutDeck value) cutDeck,
    required TResult Function(Go value) go,
    required TResult Function(CountHand value) countHand,
    required TResult Function(ForfeitAction value) forfeit,
  }) {
    return countHand(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DiscardToCrib value)? discardToCrib,
    TResult? Function(PlayCard value)? playCard,
    TResult? Function(CutDeck value)? cutDeck,
    TResult? Function(Go value)? go,
    TResult? Function(CountHand value)? countHand,
    TResult? Function(ForfeitAction value)? forfeit,
  }) {
    return countHand?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DiscardToCrib value)? discardToCrib,
    TResult Function(PlayCard value)? playCard,
    TResult Function(CutDeck value)? cutDeck,
    TResult Function(Go value)? go,
    TResult Function(CountHand value)? countHand,
    TResult Function(ForfeitAction value)? forfeit,
    required TResult orElse(),
  }) {
    if (countHand != null) {
      return countHand(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CountHandImplToJson(this);
  }
}

abstract class CountHand implements GameAction {
  const factory CountHand({required final String playerId}) = _$CountHandImpl;

  factory CountHand.fromJson(Map<String, dynamic> json) =
      _$CountHandImpl.fromJson;

  @override
  String get playerId;

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CountHandImplCopyWith<_$CountHandImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ForfeitActionImplCopyWith<$Res>
    implements $GameActionCopyWith<$Res> {
  factory _$$ForfeitActionImplCopyWith(
    _$ForfeitActionImpl value,
    $Res Function(_$ForfeitActionImpl) then,
  ) = __$$ForfeitActionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String playerId, String reason});
}

/// @nodoc
class __$$ForfeitActionImplCopyWithImpl<$Res>
    extends _$GameActionCopyWithImpl<$Res, _$ForfeitActionImpl>
    implements _$$ForfeitActionImplCopyWith<$Res> {
  __$$ForfeitActionImplCopyWithImpl(
    _$ForfeitActionImpl _value,
    $Res Function(_$ForfeitActionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? playerId = null, Object? reason = null}) {
    return _then(
      _$ForfeitActionImpl(
        playerId: null == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ForfeitActionImpl implements ForfeitAction {
  const _$ForfeitActionImpl({
    required this.playerId,
    this.reason = 'RESIGN',
    final String? $type,
  }) : $type = $type ?? 'Forfeit';

  factory _$ForfeitActionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ForfeitActionImplFromJson(json);

  @override
  final String playerId;
  @override
  @JsonKey()
  final String reason;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'GameAction.forfeit(playerId: $playerId, reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ForfeitActionImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, playerId, reason);

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ForfeitActionImplCopyWith<_$ForfeitActionImpl> get copyWith =>
      __$$ForfeitActionImplCopyWithImpl<_$ForfeitActionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String playerId, PlayingCard card) discardToCrib,
    required TResult Function(String playerId, PlayingCard card) playCard,
    required TResult Function(String playerId) cutDeck,
    required TResult Function(String playerId) go,
    required TResult Function(String playerId) countHand,
    required TResult Function(String playerId, String reason) forfeit,
  }) {
    return forfeit(playerId, reason);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String playerId, PlayingCard card)? discardToCrib,
    TResult? Function(String playerId, PlayingCard card)? playCard,
    TResult? Function(String playerId)? cutDeck,
    TResult? Function(String playerId)? go,
    TResult? Function(String playerId)? countHand,
    TResult? Function(String playerId, String reason)? forfeit,
  }) {
    return forfeit?.call(playerId, reason);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String playerId, PlayingCard card)? discardToCrib,
    TResult Function(String playerId, PlayingCard card)? playCard,
    TResult Function(String playerId)? cutDeck,
    TResult Function(String playerId)? go,
    TResult Function(String playerId)? countHand,
    TResult Function(String playerId, String reason)? forfeit,
    required TResult orElse(),
  }) {
    if (forfeit != null) {
      return forfeit(playerId, reason);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DiscardToCrib value) discardToCrib,
    required TResult Function(PlayCard value) playCard,
    required TResult Function(CutDeck value) cutDeck,
    required TResult Function(Go value) go,
    required TResult Function(CountHand value) countHand,
    required TResult Function(ForfeitAction value) forfeit,
  }) {
    return forfeit(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DiscardToCrib value)? discardToCrib,
    TResult? Function(PlayCard value)? playCard,
    TResult? Function(CutDeck value)? cutDeck,
    TResult? Function(Go value)? go,
    TResult? Function(CountHand value)? countHand,
    TResult? Function(ForfeitAction value)? forfeit,
  }) {
    return forfeit?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DiscardToCrib value)? discardToCrib,
    TResult Function(PlayCard value)? playCard,
    TResult Function(CutDeck value)? cutDeck,
    TResult Function(Go value)? go,
    TResult Function(CountHand value)? countHand,
    TResult Function(ForfeitAction value)? forfeit,
    required TResult orElse(),
  }) {
    if (forfeit != null) {
      return forfeit(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ForfeitActionImplToJson(this);
  }
}

abstract class ForfeitAction implements GameAction {
  const factory ForfeitAction({
    required final String playerId,
    final String reason,
  }) = _$ForfeitActionImpl;

  factory ForfeitAction.fromJson(Map<String, dynamic> json) =
      _$ForfeitActionImpl.fromJson;

  @override
  String get playerId;
  String get reason;

  /// Create a copy of GameAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ForfeitActionImplCopyWith<_$ForfeitActionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
