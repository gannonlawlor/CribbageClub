import 'package:freezed_annotation/freezed_annotation.dart';

part 'card.freezed.dart';
part 'card.g.dart';

enum Rank {
  @JsonValue('ACE')
  ace,
  @JsonValue('TWO')
  two,
  @JsonValue('THREE')
  three,
  @JsonValue('FOUR')
  four,
  @JsonValue('FIVE')
  five,
  @JsonValue('SIX')
  six,
  @JsonValue('SEVEN')
  seven,
  @JsonValue('EIGHT')
  eight,
  @JsonValue('NINE')
  nine,
  @JsonValue('TEN')
  ten,
  @JsonValue('JACK')
  jack,
  @JsonValue('QUEEN')
  queen,
  @JsonValue('KING')
  king;

  int get peggingValue {
    switch (this) {
      case Rank.ace:
        return 1;
      case Rank.two:
        return 2;
      case Rank.three:
        return 3;
      case Rank.four:
        return 4;
      case Rank.five:
        return 5;
      case Rank.six:
        return 6;
      case Rank.seven:
        return 7;
      case Rank.eight:
        return 8;
      case Rank.nine:
        return 9;
      case Rank.ten:
      case Rank.jack:
      case Rank.queen:
      case Rank.king:
        return 10;
    }
  }

  String get display {
    switch (this) {
      case Rank.ace:
        return 'A';
      case Rank.two:
        return '2';
      case Rank.three:
        return '3';
      case Rank.four:
        return '4';
      case Rank.five:
        return '5';
      case Rank.six:
        return '6';
      case Rank.seven:
        return '7';
      case Rank.eight:
        return '8';
      case Rank.nine:
        return '9';
      case Rank.ten:
        return '10';
      case Rank.jack:
        return 'J';
      case Rank.queen:
        return 'Q';
      case Rank.king:
        return 'K';
    }
  }
}

enum Suit {
  @JsonValue('CLUBS')
  clubs,
  @JsonValue('DIAMONDS')
  diamonds,
  @JsonValue('HEARTS')
  hearts,
  @JsonValue('SPADES')
  spades;

  String get symbol {
    switch (this) {
      case Suit.clubs:
        return '\u2663';
      case Suit.diamonds:
        return '\u2666';
      case Suit.hearts:
        return '\u2665';
      case Suit.spades:
        return '\u2660';
    }
  }

  bool get isRed => this == Suit.hearts || this == Suit.diamonds;
}

@freezed
class PlayingCard with _$PlayingCard {
  const factory PlayingCard({
    required Rank rank,
    required Suit suit,
  }) = _PlayingCard;

  factory PlayingCard.fromJson(Map<String, dynamic> json) =>
      _$PlayingCardFromJson(json);
}
