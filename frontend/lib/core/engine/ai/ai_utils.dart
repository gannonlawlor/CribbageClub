import '../../models/card.dart';

class AIUtils {
  AIUtils._();

  static List<List<T>> combinations<T>(List<T> list, int size) {
    if (size == 0) return [[]];
    if (list.isEmpty) return [];
    final head = list.first;
    final tail = list.sublist(1);
    final withHead = combinations(
      tail,
      size - 1,
    ).map((c) => [head, ...c]).toList();
    final withoutHead = combinations(tail, size);
    return [...withHead, ...withoutHead];
  }

  static PlayingCard? findRunContinuation(
    List<PlayingCard> playableCards,
    List<PlayingCard> playedCards,
  ) {
    final recentCards = playedCards.length > 3
        ? playedCards.sublist(playedCards.length - 3)
        : playedCards;
    if (recentCards.length < 2) return null;

    final recentRanks = recentCards.map((c) => c.rank.index).toList()..sort();
    final isConsecutive = () {
      for (var i = 1; i < recentRanks.length; i++) {
        if (recentRanks[i] - recentRanks[i - 1] != 1) return false;
      }
      return true;
    }();

    if (isConsecutive) {
      final minRank = recentRanks.first;
      final maxRank = recentRanks.last;
      for (final card in playableCards) {
        final rank = card.rank.index;
        if (rank == minRank - 1 || rank == maxRank + 1) return card;
      }
    }
    return null;
  }
}
