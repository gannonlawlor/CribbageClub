import '../models/card.dart';

class HandCounting {
  HandCounting._();

  static int calculateHandScore(
    List<PlayingCard> hand,
    PlayingCard cutCard, {
    bool isCrib = false,
  }) {
    final allCards = [...hand, cutCard];
    var score = 0;
    score += count15s(allCards);
    score += countPairs(allCards);
    score += countRuns(allCards);
    score += countFlushes(hand, cutCard, isCrib);
    score += countNobs(hand, cutCard);
    return score;
  }

  static int count15s(List<PlayingCard> cards) {
    var count = 0;
    final values = cards.map((c) => c.rank.peggingValue).toList();
    final n = cards.length;
    for (var i = 1; i < (1 << n); i++) {
      var sum = 0;
      for (var j = 0; j < n; j++) {
        if ((i >> j) & 1 == 1) {
          sum += values[j];
        }
      }
      if (sum == 15) count++;
    }
    return count * 2;
  }

  static int countPairs(List<PlayingCard> cards) {
    final rankCounts = <Rank, int>{};
    for (final card in cards) {
      rankCounts[card.rank] = (rankCounts[card.rank] ?? 0) + 1;
    }
    var score = 0;
    for (final count in rankCounts.values) {
      if (count >= 2) {
        score += count * (count - 1); // n choose 2 pairs, each worth 2
      }
    }
    return score;
  }

  static int countRuns(List<PlayingCard> cards) {
    final rankCounts = <Rank, int>{};
    for (final card in cards) {
      rankCounts[card.rank] = (rankCounts[card.rank] ?? 0) + 1;
    }
    final sortedRanks = rankCounts.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    if (sortedRanks.length < 3) return 0;

    var longestRunLength = 1;
    var currentRunLength = 1;
    var runStart = 0;

    for (var i = 1; i < sortedRanks.length; i++) {
      if (sortedRanks[i].index == sortedRanks[i - 1].index + 1) {
        currentRunLength++;
      } else {
        if (currentRunLength > longestRunLength) {
          longestRunLength = currentRunLength;
          runStart = i - currentRunLength;
        }
        currentRunLength = 1;
      }
    }

    if (currentRunLength > longestRunLength) {
      longestRunLength = currentRunLength;
      runStart = sortedRanks.length - currentRunLength;
    }

    if (longestRunLength >= 3) {
      var multiplier = 1;
      for (var i = runStart; i < runStart + longestRunLength; i++) {
        multiplier *= rankCounts[sortedRanks[i]]!;
      }
      return longestRunLength * multiplier;
    }
    return 0;
  }

  static int countFlushes(
    List<PlayingCard> hand,
    PlayingCard cutCard,
    bool isCrib,
  ) {
    if (hand.isEmpty) return 0;
    final handSuit = hand.first.suit;
    final handFlush = hand.every((c) => c.suit == handSuit);

    if (handFlush && cutCard.suit == handSuit) {
      return 5;
    } else if (handFlush && !isCrib) {
      return 4;
    }
    return 0;
  }

  static int countNobs(List<PlayingCard> hand, PlayingCard cutCard) {
    return hand.any((c) => c.rank == Rank.jack && c.suit == cutCard.suit)
        ? 1
        : 0;
  }
}
