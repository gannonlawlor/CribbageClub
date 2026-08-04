import '../../../core/models/card.dart';
import '../models/keep_explanation.dart';

class InsightGenerator {
  InsightGenerator._();

  static List<String> generateInsights(
    KeepExplanation explanation,
    List<PlayingCard> keep,
    List<PlayingCard> discard,
  ) {
    final insights = <String>[];

    // Guaranteed hand patterns
    _addGuaranteedInsights(insights, explanation.guaranteedPoints, keep);

    // Cut card potential
    _addCutInsights(insights, explanation.cutScores, keep);

    // Crib impact
    _addCribInsights(insights, explanation, keep, discard);

    // Cap at 6 insights
    if (insights.length > 6) {
      return insights.sublist(0, 6);
    }
    return insights;
  }

  static void _addGuaranteedInsights(
    List<String> insights,
    HandPatterns patterns,
    List<PlayingCard> keep,
  ) {
    if (patterns.pairs > 0) {
      final pairDescs = _describePairs(keep);
      for (final desc in pairDescs) {
        insights.add(desc);
      }
    }

    if (patterns.fifteens > 0) {
      final count = patterns.fifteens ~/ 2;
      if (count == 1) {
        insights.add('15 for 2 guaranteed');
      } else {
        insights.add('$count fifteens (${patterns.fifteens} pts guaranteed)');
      }
    }

    if (patterns.runs > 0) {
      final runDesc = _describeRun(keep, patterns.runs);
      if (runDesc != null) {
        insights.add(runDesc);
      }
    }

    if (patterns.flush) {
      insights.add('Four-card flush (4 pts guaranteed)');
    }
  }

  static void _addCutInsights(
    List<String> insights,
    List<CutScore> cutScores,
    List<PlayingCard> keep,
  ) {
    if (cutScores.isEmpty) return;

    // Best cut
    final best = cutScores.first;
    insights.add(
      'Best cut: ${best.card.rank.display}${best.card.suit.symbol}'
      ' (${best.totalScore} pts)',
    );

    // Count cuts scoring 8+
    final strongCuts = cutScores.where((c) => c.totalScore >= 8).length;
    if (strongCuts > 0) {
      insights.add('$strongCuts of 46 cuts score 8+');
    }

    // Nobs potential: if keep contains a Jack
    final jacks = keep.where((c) => c.rank == Rank.jack).toList();
    if (jacks.isNotEmpty) {
      final suitCount = cutScores
          .where((c) => c.card.suit == jacks.first.suit)
          .length;
      if (suitCount > 0) {
        insights.add(
          'Nobs potential \u2014 J${jacks.first.suit.symbol}'
          ' scores +1 on $suitCount cuts',
        );
      }
    }
  }

  static void _addCribInsights(
    List<String> insights,
    KeepExplanation explanation,
    List<PlayingCard> keep,
    List<PlayingCard> discard,
  ) {
    final avgCrib = explanation.averageCribScore;
    final isDealer = explanation.isDealer;

    if (isDealer) {
      insights.add('Your crib gains avg ${avgCrib.toStringAsFixed(1)} pts');
    } else {
      insights.add(
        "Opponent's crib gets avg ${avgCrib.toStringAsFixed(1)} pts",
      );
    }

    // Check for 5 in discard
    final hasFiveInDiscard = discard.any((c) => c.rank == Rank.five);
    if (hasFiveInDiscard && !isDealer) {
      insights.add("5 in opponent's crib risks easy 15s");
    } else if (!hasFiveInDiscard && !isDealer) {
      insights.add("Avoids giving a 5 to opponent's crib");
    }

    // Pair in own crib
    if (isDealer && discard.length == 2 && discard[0].rank == discard[1].rank) {
      insights.add('Pair in your crib adds guaranteed points');
    }
  }

  /// Describe pairs found in the kept cards.
  static List<String> _describePairs(List<PlayingCard> keep) {
    final rankCounts = <Rank, int>{};
    for (final card in keep) {
      rankCounts[card.rank] = (rankCounts[card.rank] ?? 0) + 1;
    }

    final descs = <String>[];
    for (final entry in rankCounts.entries) {
      if (entry.value == 2) {
        descs.add('Pair of ${entry.key.display}s (2 pts guaranteed)');
      } else if (entry.value == 3) {
        descs.add('Three ${entry.key.display}s (6 pts guaranteed)');
      } else if (entry.value == 4) {
        descs.add('Four ${entry.key.display}s (12 pts guaranteed)');
      }
    }
    return descs;
  }

  /// Describe a run found in the kept cards.
  static String? _describeRun(List<PlayingCard> keep, int runPoints) {
    // Sort by ordinal to find consecutive sequences
    final sorted = List<PlayingCard>.from(keep)
      ..sort((a, b) => a.rank.index.compareTo(b.rank.index));

    // Find the longest consecutive run
    var bestRun = <PlayingCard>[sorted.first];
    var currentRun = <PlayingCard>[sorted.first];

    for (var i = 1; i < sorted.length; i++) {
      final diff = sorted[i].rank.index - sorted[i - 1].rank.index;
      if (diff == 1) {
        currentRun.add(sorted[i]);
      } else if (diff == 0) {
        // Duplicate rank, part of double run
        continue;
      } else {
        if (currentRun.length > bestRun.length) {
          bestRun = currentRun;
        }
        currentRun = [sorted[i]];
      }
    }
    if (currentRun.length > bestRun.length) {
      bestRun = currentRun;
    }

    if (bestRun.length >= 3) {
      final rankStr = bestRun.map((c) => c.rank.display).join('-');
      return 'Run of $rankStr ($runPoints pts guaranteed)';
    }
    return null;
  }
}
