import 'dart:math';

import '../models/card.dart';

class Deck {
  final List<PlayingCard> _cards;

  Deck([List<PlayingCard>? existingCards])
      : _cards = existingCards != null
            ? List.of(existingCards)
            : _createShuffledDeck();

  PlayingCard draw() => _cards.removeAt(0);

  List<PlayingCard> drawN(int n) => List.generate(n, (_) => draw());

  PlayingCard cut() => _cards.removeAt(_cards.length ~/ 2);

  List<PlayingCard> remainingCards() => List.unmodifiable(_cards);

  void shuffle() => _cards.shuffle(Random());

  void reset() {
    _cards
      ..clear()
      ..addAll(_createShuffledDeck());
  }

  static List<PlayingCard> _createShuffledDeck() {
    final deck = <PlayingCard>[
      for (final suit in Suit.values)
        for (final rank in Rank.values) PlayingCard(rank: rank, suit: suit),
    ];
    deck.shuffle(Random());
    return deck;
  }
}
