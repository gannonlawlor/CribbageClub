// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PlayingCard _$PlayingCardFromJson(Map<String, dynamic> json) {
  return _PlayingCard.fromJson(json);
}

/// @nodoc
mixin _$PlayingCard {
  Rank get rank => throw _privateConstructorUsedError;
  Suit get suit => throw _privateConstructorUsedError;

  /// Serializes this PlayingCard to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayingCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayingCardCopyWith<PlayingCard> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayingCardCopyWith<$Res> {
  factory $PlayingCardCopyWith(
    PlayingCard value,
    $Res Function(PlayingCard) then,
  ) = _$PlayingCardCopyWithImpl<$Res, PlayingCard>;
  @useResult
  $Res call({Rank rank, Suit suit});
}

/// @nodoc
class _$PlayingCardCopyWithImpl<$Res, $Val extends PlayingCard>
    implements $PlayingCardCopyWith<$Res> {
  _$PlayingCardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayingCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? rank = null, Object? suit = null}) {
    return _then(
      _value.copyWith(
            rank: null == rank
                ? _value.rank
                : rank // ignore: cast_nullable_to_non_nullable
                      as Rank,
            suit: null == suit
                ? _value.suit
                : suit // ignore: cast_nullable_to_non_nullable
                      as Suit,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlayingCardImplCopyWith<$Res>
    implements $PlayingCardCopyWith<$Res> {
  factory _$$PlayingCardImplCopyWith(
    _$PlayingCardImpl value,
    $Res Function(_$PlayingCardImpl) then,
  ) = __$$PlayingCardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Rank rank, Suit suit});
}

/// @nodoc
class __$$PlayingCardImplCopyWithImpl<$Res>
    extends _$PlayingCardCopyWithImpl<$Res, _$PlayingCardImpl>
    implements _$$PlayingCardImplCopyWith<$Res> {
  __$$PlayingCardImplCopyWithImpl(
    _$PlayingCardImpl _value,
    $Res Function(_$PlayingCardImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlayingCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? rank = null, Object? suit = null}) {
    return _then(
      _$PlayingCardImpl(
        rank: null == rank
            ? _value.rank
            : rank // ignore: cast_nullable_to_non_nullable
                  as Rank,
        suit: null == suit
            ? _value.suit
            : suit // ignore: cast_nullable_to_non_nullable
                  as Suit,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayingCardImpl implements _PlayingCard {
  const _$PlayingCardImpl({required this.rank, required this.suit});

  factory _$PlayingCardImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayingCardImplFromJson(json);

  @override
  final Rank rank;
  @override
  final Suit suit;

  @override
  String toString() {
    return 'PlayingCard(rank: $rank, suit: $suit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayingCardImpl &&
            (identical(other.rank, rank) || other.rank == rank) &&
            (identical(other.suit, suit) || other.suit == suit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, rank, suit);

  /// Create a copy of PlayingCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayingCardImplCopyWith<_$PlayingCardImpl> get copyWith =>
      __$$PlayingCardImplCopyWithImpl<_$PlayingCardImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayingCardImplToJson(this);
  }
}

abstract class _PlayingCard implements PlayingCard {
  const factory _PlayingCard({
    required final Rank rank,
    required final Suit suit,
  }) = _$PlayingCardImpl;

  factory _PlayingCard.fromJson(Map<String, dynamic> json) =
      _$PlayingCardImpl.fromJson;

  @override
  Rank get rank;
  @override
  Suit get suit;

  /// Create a copy of PlayingCard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayingCardImplCopyWith<_$PlayingCardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
