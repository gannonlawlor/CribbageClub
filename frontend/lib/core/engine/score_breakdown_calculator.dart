import '../models/card.dart';
import '../models/score_breakdown.dart';
import 'hand_counting.dart';

class ScoreBreakdownCalculator {
  ScoreBreakdownCalculator._();

  static ScoreBreakdown calculate(
    List<PlayingCard> hand,
    PlayingCard cutCard, {
    bool isCrib = false,
  }) {
    final allCards = [...hand, cutCard];
    return ScoreBreakdown(
      fifteens: HandCounting.count15s(allCards),
      pairs: HandCounting.countPairs(allCards),
      runs: HandCounting.countRuns(allCards),
      flushes: HandCounting.countFlushes(hand, cutCard, isCrib),
      nobs: HandCounting.countNobs(hand, cutCard),
    );
  }
}
