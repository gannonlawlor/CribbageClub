import '../../core/models/card.dart';
import 'card_utils.dart';

class ScoringCombination {
  final List<PlayingCard> cards;
  final String type;
  final int points;
  final String description;

  const ScoringCombination({
    required this.cards,
    required this.type,
    required this.points,
    required this.description,
  });
}

class DetailedScoreBreakdown {
  final List<ScoringCombination> combinations;
  final int totalScore;

  const DetailedScoreBreakdown({
    required this.combinations,
    required this.totalScore,
  });
}

DetailedScoreBreakdown calculateDetailedBreakdown(
  List<PlayingCard> hand,
  PlayingCard cutCard, {
  bool isCrib = false,
}) {
  final allCards = [...hand, cutCard];
  final combinations = <ScoringCombination>[];

  combinations.addAll(_findFifteens(allCards));
  combinations.addAll(_findPairs(allCards));
  combinations.addAll(_findRuns(allCards));
  combinations.addAll(_checkFlush(hand, cutCard, isCrib));
  combinations.addAll(_checkNobs(hand, cutCard));

  final total = combinations.fold(0, (sum, c) => sum + c.points);
  return DetailedScoreBreakdown(combinations: combinations, totalScore: total);
}

String _cardLabel(PlayingCard card) => CardUtils.cardLabel(card);

String _cardsLabel(List<PlayingCard> cards) =>
    cards.map(_cardLabel).join(' + ');

/// Enumerate all subsets of 5 cards that sum to 15.
List<ScoringCombination> _findFifteens(List<PlayingCard> allCards) {
  final results = <ScoringCombination>[];
  final n = allCards.length;
  // Enumerate all non-empty subsets via bitmask
  for (int mask = 1; mask < (1 << n); mask++) {
    int sum = 0;
    final subset = <PlayingCard>[];
    for (int i = 0; i < n; i++) {
      if (mask & (1 << i) != 0) {
        sum += allCards[i].rank.peggingValue;
        subset.add(allCards[i]);
      }
    }
    if (sum == 15) {
      results.add(ScoringCombination(
        cards: subset,
        type: 'fifteen',
        points: 2,
        description: '${_cardsLabel(subset)} = 15',
      ));
    }
  }
  return results;
}

/// Find all pairs (two cards of same rank).
List<ScoringCombination> _findPairs(List<PlayingCard> allCards) {
  final results = <ScoringCombination>[];
  for (int i = 0; i < allCards.length; i++) {
    for (int j = i + 1; j < allCards.length; j++) {
      if (allCards[i].rank == allCards[j].rank) {
        results.add(ScoringCombination(
          cards: [allCards[i], allCards[j]],
          type: 'pair',
          points: 2,
          description: '${_cardLabel(allCards[i])} + ${_cardLabel(allCards[j])} = Pair',
        ));
      }
    }
  }
  return results;
}

/// Find all runs of 3+ consecutive ranks, accounting for duplicates.
List<ScoringCombination> _findRuns(List<PlayingCard> allCards) {
  // Group cards by rank index
  final byRank = <int, List<PlayingCard>>{};
  for (final card in allCards) {
    byRank.putIfAbsent(card.rank.index, () => []).add(card);
  }

  final sortedRanks = byRank.keys.toList()..sort();
  final results = <ScoringCombination>[];

  // Find the longest consecutive sequences first
  // Start from each rank and extend as far as possible
  int i = 0;
  while (i < sortedRanks.length) {
    // Find the end of this consecutive run
    int end = i;
    while (end + 1 < sortedRanks.length &&
        sortedRanks[end + 1] == sortedRanks[end] + 1) {
      end++;
    }

    final runLength = end - i + 1;
    if (runLength >= 3) {
      // Check all sub-runs of length >= 3, starting from the longest
      // Only use the longest run length (standard cribbage rules)
      // But we need to find the longest runs and enumerate all Cartesian products
      _addRunCombinations(results, byRank, sortedRanks, i, end);
      i = end + 1;
    } else {
      i++;
    }
  }

  return results;
}

/// Given a consecutive sequence of ranks from sortedRanks[start] to sortedRanks[end],
/// find the longest sub-run that exists and enumerate all Cartesian products of
/// duplicate cards within that run.
void _addRunCombinations(
  List<ScoringCombination> results,
  Map<int, List<PlayingCard>> byRank,
  List<int> sortedRanks,
  int start,
  int end,
) {
  final runLength = end - start + 1;

  // In cribbage, you only score the longest possible run length.
  // E.g., if you have 3-4-5-6, you score one run of 4, not two runs of 3.
  // But with duplicates (e.g., 3-4-4-5), you score two runs of 3.

  // Try from longest to shortest sub-run
  for (int len = runLength; len >= 3; len--) {
    bool found = false;
    for (int s = start; s + len - 1 <= end; s++) {
      final rankIndices = <int>[];
      for (int r = s; r < s + len; r++) {
        rankIndices.add(sortedRanks[r]);
      }

      // Get lists of cards for each rank in this run
      final cardLists = rankIndices.map((r) => byRank[r]!).toList();

      // Cartesian product of all cards at each rank
      final combos = _cartesianProduct(cardLists);
      if (combos.isNotEmpty) {
        found = true;
        for (final combo in combos) {
          results.add(ScoringCombination(
            cards: combo,
            type: 'run',
            points: len,
            description: '${_cardsLabel(combo)} = Run of $len',
          ));
        }
      }
    }
    // If we found runs of this length, don't look for shorter ones
    if (found) break;
  }
}

/// Compute Cartesian product of a list of lists.
List<List<PlayingCard>> _cartesianProduct(List<List<PlayingCard>> lists) {
  if (lists.isEmpty) return [[]];
  var result = <List<PlayingCard>>[[]];
  for (final list in lists) {
    final newResult = <List<PlayingCard>>[];
    for (final existing in result) {
      for (final item in list) {
        newResult.add([...existing, item]);
      }
    }
    result = newResult;
  }
  return result;
}

/// Check for flush: 4-card hand flush (not in crib) or 5-card flush.
List<ScoringCombination> _checkFlush(
  List<PlayingCard> hand,
  PlayingCard cutCard,
  bool isCrib,
) {
  if (hand.length < 4) return [];
  final suit = hand[0].suit;
  final allHandMatch = hand.every((c) => c.suit == suit);
  if (!allHandMatch) return [];

  if (cutCard.suit == suit) {
    // 5-card flush (always counts, even in crib)
    final allCards = [...hand, cutCard];
    return [
      ScoringCombination(
        cards: allCards,
        type: 'flush',
        points: 5,
        description: '${_cardsLabel(allCards)} = Flush of 5',
      ),
    ];
  }

  if (!isCrib) {
    // 4-card hand flush (not allowed in crib)
    return [
      ScoringCombination(
        cards: hand,
        type: 'flush',
        points: 4,
        description: '${_cardsLabel(hand)} = Flush of 4',
      ),
    ];
  }

  return [];
}

/// Check for nobs: Jack in hand matching cut card's suit.
List<ScoringCombination> _checkNobs(
  List<PlayingCard> hand,
  PlayingCard cutCard,
) {
  final results = <ScoringCombination>[];
  for (final card in hand) {
    if (card.rank == Rank.jack && card.suit == cutCard.suit) {
      results.add(ScoringCombination(
        cards: [card],
        type: 'nobs',
        points: 1,
        description: '${_cardLabel(card)} = His Nobs',
      ));
    }
  }
  return results;
}
