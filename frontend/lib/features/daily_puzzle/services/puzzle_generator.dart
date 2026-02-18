import 'dart:math';

import '../../../core/engine/ai/ai_utils.dart';
import '../../../core/engine/hand_counting.dart';
import '../../../core/models/card.dart';
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
  static List<KeepOption> evaluateAllKeeps(
    List<PlayingCard> hand,
    bool isDealer,
  ) {
    final keeps = AIUtils.combinations(hand, 4);
    final handSet = hand.toSet();
    final options = <_ScoredOption>[];

    for (final keep in keeps) {
      final keepSet = keep.toSet();
      final discard = handSet.difference(keepSet).toList();
      final handAvg = _averageHandScore(keep);
      final cribAvg = _averageCribScore(discard);
      final netScore = isDealer ? handAvg + cribAvg : handAvg - cribAvg;

      options.add(
        _ScoredOption(
          keep: keep,
          discard: discard,
          averageHandScore: handAvg,
          averageCribScore: cribAvg,
          netScore: netScore,
        ),
      );
    }

    // Sort descending by net score
    options.sort((a, b) => b.netScore.compareTo(a.netScore));

    return [
      for (var i = 0; i < options.length; i++)
        KeepOption(
          keep: options[i].keep,
          discard: options[i].discard,
          averageHandScore: options[i].averageHandScore,
          averageCribScore: options[i].averageCribScore,
          netScore: options[i].netScore,
          rank: i + 1,
        ),
    ];
  }

  /// Average hand score across all possible cut cards not in the keep.
  static double _averageHandScore(List<PlayingCard> keep) {
    var totalScore = 0;
    var cutCount = 0;

    for (final rank in Rank.values) {
      for (final suit in Suit.values) {
        final cutCard = PlayingCard(rank: rank, suit: suit);
        if (keep.contains(cutCard)) continue;
        totalScore += HandCounting.calculateHandScore(keep, cutCard);
        cutCount++;
      }
    }

    return cutCount > 0 ? totalScore / cutCount : 0.0;
  }

  /// Average crib contribution from the 2 discarded cards.
  static double _averageCribScore(List<PlayingCard> discard) {
    if (discard.length != 2) return 0.0;

    var totalScore = 0;
    var count = 0;

    for (final rank in Rank.values) {
      for (final suit in Suit.values) {
        final cutCard = PlayingCard(rank: rank, suit: suit);
        if (discard.contains(cutCard)) continue;

        final allCards = [...discard, cutCard];
        var score = 0;

        // 15s
        final values = allCards.map((c) => c.rank.peggingValue).toList();
        for (var i = 1; i < (1 << allCards.length); i++) {
          var sum = 0;
          for (var j = 0; j < allCards.length; j++) {
            if ((i >> j) & 1 == 1) sum += values[j];
          }
          if (sum == 15) score += 2;
        }

        // Pair between discards
        if (discard[0].rank == discard[1].rank) score += 2;

        totalScore += score;
        count++;
      }
    }

    return count > 0 ? totalScore / count : 0.0;
  }
}

class _ScoredOption {
  final List<PlayingCard> keep;
  final List<PlayingCard> discard;
  final double averageHandScore;
  final double averageCribScore;
  final double netScore;

  const _ScoredOption({
    required this.keep,
    required this.discard,
    required this.averageHandScore,
    required this.averageCribScore,
    required this.netScore,
  });
}
