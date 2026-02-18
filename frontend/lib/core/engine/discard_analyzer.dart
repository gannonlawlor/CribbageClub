import 'dart:isolate';
import '../models/card.dart';
import '../models/game_analysis.dart';
import 'ai/ai_utils.dart';
import 'hand_counting.dart';

/// Dart port of backend DiscardAnalyzer.
/// Analyzes all 15 possible discard options from a 6-card hand.
class DiscardAnalyzer {
  DiscardAnalyzer._();

  static final List<PlayingCard> _allCards = [
    for (final rank in Rank.values)
      for (final suit in Suit.values) PlayingCard(rank: rank, suit: suit),
  ];

  /// Analyzes all 15 discard options, sorted by expected combined value desc.
  /// Runs in an isolate to avoid blocking the UI.
  static Future<List<DiscardOption>> analyzeAllDiscards(
    List<PlayingCard> hand,
    bool isDealer,
  ) async {
    return Isolate.run(() => _analyzeAllDiscardsSync(hand, isDealer));
  }

  /// Synchronous version for use inside isolates or tests.
  static List<DiscardOption> _analyzeAllDiscardsSync(
    List<PlayingCard> hand,
    bool isDealer,
  ) {
    assert(hand.length == 6, 'Hand must have exactly 6 cards');
    final handSet = hand.toSet();

    final options = AIUtils.combinations(hand, 4).map((keep) {
      final discard = hand.where((c) => !keep.contains(c)).toList();
      final expectedHand = _expectedHandValue(keep, handSet);
      final expectedCrib = _expectedCribValue(discard, handSet);
      final combined = isDealer
          ? expectedHand + expectedCrib
          : expectedHand - expectedCrib;

      return DiscardOption(
        keep: keep,
        discard: discard,
        expectedHandValue: expectedHand,
        expectedCribValue: expectedCrib,
        expectedCombinedValue: combined,
      );
    }).toList();

    options.sort(
      (a, b) => b.expectedCombinedValue.compareTo(a.expectedCombinedValue),
    );
    return options;
  }

  /// Expected hand score across all possible cut cards (46 remaining).
  static double _expectedHandValue(
    List<PlayingCard> keep,
    Set<PlayingCard> knownCards,
  ) {
    var totalScore = 0;
    var cutCount = 0;

    for (final card in _allCards) {
      if (knownCards.contains(card)) continue;
      totalScore += HandCounting.calculateHandScore(keep, card);
      cutCount++;
    }

    return cutCount > 0 ? totalScore / cutCount : 0.0;
  }

  /// Expected crib value via full enumeration.
  /// C(46,2) opponent pairs x 44 cuts = 45,540 evaluations per option.
  static double _expectedCribValue(
    List<PlayingCard> discard,
    Set<PlayingCard> knownCards,
  ) {
    final remaining = _allCards.where((c) => !knownCards.contains(c)).toList();

    var totalScore = 0;
    var count = 0;

    for (var i = 0; i < remaining.length; i++) {
      for (var j = i + 1; j < remaining.length; j++) {
        final crib = [discard[0], discard[1], remaining[i], remaining[j]];
        for (var k = 0; k < remaining.length; k++) {
          if (k == i || k == j) continue;
          totalScore += HandCounting.calculateHandScore(
            crib,
            remaining[k],
            isCrib: true,
          );
          count++;
        }
      }
    }

    return count > 0 ? totalScore / count : 0.0;
  }
}
