import '../../../core/models/card.dart';

class DailyPuzzle {
  final DateTime date;
  final int index;
  final List<PlayingCard> hand;
  final bool isDealer;
  List<KeepOption>? results;

  DailyPuzzle({
    required this.date,
    required this.index,
    required this.hand,
    required this.isDealer,
    this.results,
  });
}

class DailyPuzzleSet {
  final DateTime date;
  final List<DailyPuzzle> puzzles;

  const DailyPuzzleSet({required this.date, required this.puzzles});
}

class KeepOption {
  final List<PlayingCard> keep;
  final List<PlayingCard> discard;
  final double averageHandScore;
  final double averageCribScore;
  final double netScore;
  final int rank;

  const KeepOption({
    required this.keep,
    required this.discard,
    required this.averageHandScore,
    required this.averageCribScore,
    required this.netScore,
    required this.rank,
  });
}
