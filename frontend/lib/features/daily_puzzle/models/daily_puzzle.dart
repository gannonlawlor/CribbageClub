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

  Map<String, dynamic> toJson() => {
    'keep': keep.map((c) => c.toJson()).toList(),
    'discard': discard.map((c) => c.toJson()).toList(),
    'averageHandScore': averageHandScore,
    'averageCribScore': averageCribScore,
    'netScore': netScore,
    'rank': rank,
  };

  factory KeepOption.fromJson(Map<String, dynamic> json) => KeepOption(
    keep: (json['keep'] as List)
        .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
        .toList(),
    discard: (json['discard'] as List)
        .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
        .toList(),
    averageHandScore: (json['averageHandScore'] as num).toDouble(),
    averageCribScore: (json['averageCribScore'] as num).toDouble(),
    netScore: (json['netScore'] as num).toDouble(),
    rank: json['rank'] as int,
  );
}
