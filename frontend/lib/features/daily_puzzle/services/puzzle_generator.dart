import 'dart:convert';
import 'dart:math';

import '../../../core/models/card.dart';
import '../../../core/models/game_analysis.dart';
import '../../../src/rust/api/simple.dart' as rust;
import '../models/daily_puzzle.dart';

class PuzzleGenerator {
  PuzzleGenerator._();

  /// Generate a deterministic puzzle for the given date.
  static DailyPuzzle generate(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final rng = Random(seed);

    // Build full deck and Fisher-Yates shuffle
    final deck = <PlayingCard>[];
    for (final rank in Rank.values) {
      for (final suit in Suit.values) {
        deck.add(PlayingCard(rank: rank, suit: suit));
      }
    }
    for (var i = deck.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = deck[i];
      deck[i] = deck[j];
      deck[j] = temp;
    }

    final hand = deck.sublist(0, 6);
    final isDealer = seed % 2 == 0;

    return DailyPuzzle(date: date, hand: hand, isDealer: isDealer);
  }

  /// Evaluate all 15 possible keeps and return them ranked best-to-worst.
  static Future<List<KeepOption>> evaluateAllKeeps(
    List<PlayingCard> hand,
    bool isDealer,
  ) async {
    final handJson = jsonEncode(hand.map((c) => c.toJson()).toList());
    final resultJson = await rust.analyzeDiscardsJson(
      handJson: handJson,
      isDealer: isDealer,
    );
    final allOptions = (jsonDecode(resultJson) as List)
        .map((o) => DiscardOption.fromJson(o as Map<String, dynamic>))
        .toList();

    return [
      for (var i = 0; i < allOptions.length; i++)
        KeepOption(
          keep: allOptions[i].keep,
          discard: allOptions[i].discard,
          averageHandScore: allOptions[i].expectedHandValue,
          averageCribScore: allOptions[i].expectedCribValue,
          netScore: allOptions[i].expectedCombinedValue,
          rank: i + 1,
        ),
    ];
  }
}
