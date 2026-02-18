// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayingCardImpl _$$PlayingCardImplFromJson(Map<String, dynamic> json) =>
    _$PlayingCardImpl(
      rank: $enumDecode(_$RankEnumMap, json['rank']),
      suit: $enumDecode(_$SuitEnumMap, json['suit']),
    );

Map<String, dynamic> _$$PlayingCardImplToJson(_$PlayingCardImpl instance) =>
    <String, dynamic>{
      'rank': _$RankEnumMap[instance.rank]!,
      'suit': _$SuitEnumMap[instance.suit]!,
    };

const _$RankEnumMap = {
  Rank.ace: 'ACE',
  Rank.two: 'TWO',
  Rank.three: 'THREE',
  Rank.four: 'FOUR',
  Rank.five: 'FIVE',
  Rank.six: 'SIX',
  Rank.seven: 'SEVEN',
  Rank.eight: 'EIGHT',
  Rank.nine: 'NINE',
  Rank.ten: 'TEN',
  Rank.jack: 'JACK',
  Rank.queen: 'QUEEN',
  Rank.king: 'KING',
};

const _$SuitEnumMap = {
  Suit.clubs: 'CLUBS',
  Suit.diamonds: 'DIAMONDS',
  Suit.hearts: 'HEARTS',
  Suit.spades: 'SPADES',
};
