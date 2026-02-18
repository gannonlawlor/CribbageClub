import '../../../core/models/card.dart';

class HandPatterns {
  final int fifteens;
  final int pairs;
  final int runs;
  final bool flush;
  final int total;

  const HandPatterns({
    required this.fifteens,
    required this.pairs,
    required this.runs,
    required this.flush,
    required this.total,
  });

  factory HandPatterns.fromJson(Map<String, dynamic> json) => HandPatterns(
    fifteens: json['fifteens'] as int,
    pairs: json['pairs'] as int,
    runs: json['runs'] as int,
    flush: json['flush'] as bool,
    total: json['total'] as int,
  );
}

class CutScore {
  final PlayingCard card;
  final int totalScore;

  const CutScore({required this.card, required this.totalScore});

  factory CutScore.fromJson(Map<String, dynamic> json) => CutScore(
    card: PlayingCard.fromJson(json['card'] as Map<String, dynamic>),
    totalScore: json['totalScore'] as int,
  );
}

class KeepExplanation {
  final HandPatterns guaranteedPoints;
  final List<CutScore> cutScores;
  final double averageHandScore;
  final double averageCribScore;
  final bool isDealer;

  const KeepExplanation({
    required this.guaranteedPoints,
    required this.cutScores,
    required this.averageHandScore,
    required this.averageCribScore,
    required this.isDealer,
  });

  factory KeepExplanation.fromJson(Map<String, dynamic> json) =>
      KeepExplanation(
        guaranteedPoints: HandPatterns.fromJson(
          json['guaranteedPoints'] as Map<String, dynamic>,
        ),
        cutScores: (json['cutScores'] as List)
            .map((e) => CutScore.fromJson(e as Map<String, dynamic>))
            .toList(),
        averageHandScore: (json['averageHandScore'] as num).toDouble(),
        averageCribScore: (json['averageCribScore'] as num).toDouble(),
        isDealer: json['isDealer'] as bool,
      );
}
