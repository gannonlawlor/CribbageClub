import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../core/models/card.dart';

class CardUtils {
  CardUtils._();

  static Color suitColor(Suit suit, AppColors colors) {
    return suit.isRed ? colors.suitRed : colors.suitBlack;
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
