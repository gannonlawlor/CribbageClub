import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../core/models/card.dart';

class CardUtils {
  CardUtils._();

  static Color suitColor(Suit suit) {
    return suit.isRed ? AppTheme.suitRed : AppTheme.suitBlack;
  }

  static String cardLabel(PlayingCard card) {
    return '${card.rank.display}${card.suit.symbol}';
  }

  static int compareCards(PlayingCard a, PlayingCard b) {
    final rankCompare = a.rank.index.compareTo(b.rank.index);
    if (rankCompare != 0) return rankCompare;
    return a.suit.index.compareTo(b.suit.index);
  }

  static List<PlayingCard> sorted(List<PlayingCard> cards) {
    return List.of(cards)..sort(compareCards);
  }
}
