import '../../models/card.dart';
import '../../models/game_action.dart';
import '../../models/game_state.dart';
import '../hand_counting.dart';
import 'ai_player.dart';
import 'ai_utils.dart';

class HardAIPlayer extends AIPlayer {
  @override
  final String playerId;
  @override
  final String playerName;

  HardAIPlayer({
    required this.playerId,
    this.playerName = 'AI Player (Hard)',
  });

  @override
  GameAction? getNextAction(GameState gameState) {
    if (gameState.currentPlayerId != playerId) return null;
    final player = gameState.players.firstWhere((p) => p.id == playerId);

    return switch (gameState.stage) {
      GameStage.discardingToCrib => () {
          if (player.hand.length > 4) {
            final cardsToDiscard =
                chooseCardsToDiscard(player.hand, isDealer(gameState));
            if (cardsToDiscard.isNotEmpty) {
              return GameAction.discardToCrib(
                playerId: playerId,
                card: cardsToDiscard.first,
              );
            }
          }
          return null;
        }(),
      GameStage.cutting => GameAction.cutDeck(playerId: playerId),
      GameStage.pegging => () {
          final card = chooseCardToPlay(
            player.hand,
            gameState.playedCards,
            gameState.peggingCount,
          );
          return card != null
              ? GameAction.playCard(playerId: playerId, card: card)
              : GameAction.go(playerId: playerId);
        }(),
      GameStage.counting => GameAction.countHand(playerId: playerId),
      _ => null,
    };
  }

  @override
  List<PlayingCard> chooseCardsToDiscard(
    List<PlayingCard> hand,
    bool isDealer,
  ) {
    if (hand.length <= 4) return [];

    var bestDiscard = hand.take(2).toList();
    var bestNetScore = -1e9;

    for (final keep in AIUtils.combinations(hand, 4)) {
      final keepSet = keep.toSet();
      final discard = hand.where((c) => !keepSet.contains(c)).toList();
      final handAvg = _averageHandScore(keep);
      final cribAvg = _averageCribScore(discard);

      final netScore = isDealer ? handAvg + cribAvg : handAvg - cribAvg;

      if (netScore > bestNetScore) {
        bestNetScore = netScore;
        bestDiscard = discard;
      }
    }

    return bestDiscard;
  }

  @override
  PlayingCard? chooseCardToPlay(
    List<PlayingCard> hand,
    List<PlayingCard> playedCards,
    int currentCount,
  ) {
    final playable =
        hand.where((c) => currentCount + c.rank.peggingValue <= 31).toList();
    if (playable.isEmpty) return null;

    PlayingCard? best;
    var bestScore = -1e9;

    for (final card in playable) {
      final score =
          _evaluatePeggingPlay(card, playable, playedCards, currentCount);
      if (score > bestScore) {
        bestScore = score;
        best = card;
      }
    }

    return best;
  }

  double _evaluatePeggingPlay(
    PlayingCard card,
    List<PlayingCard> allPlayable,
    List<PlayingCard> playedCards,
    int currentCount,
  ) {
    final newCount = currentCount + card.rank.peggingValue;
    var score = 0.0;

    // Immediate scoring
    if (newCount == 31) score += 20.0;
    if (newCount == 15) score += 20.0;

    // Pair scoring
    if (playedCards.isNotEmpty && playedCards.last.rank == card.rank) {
      final weHaveAnother =
          allPlayable.where((c) => c.rank == card.rank).length >= 2;
      score += weHaveAnother ? 15.0 : 10.0;
    }

    // Run scoring
    if (playedCards.length >= 2) {
      final runLength = _checkRunLength([...playedCards, card]);
      if (runLength >= 3) score += runLength * 4.0;
    }

    // Trap play: pair in hand, bait for trips
    final pairsInHand = <Rank, int>{};
    for (final c in allPlayable) {
      pairsInHand[c.rank] = (pairsInHand[c.rank] ?? 0) + 1;
    }
    if ((pairsInHand[card.rank] ?? 0) >= 2 && playedCards.isEmpty) {
      score += 3.0;
    }

    // Defensive
    if (newCount == 5) score -= 8.0;
    if (newCount == 21) score -= 6.0;
    if (newCount == 16) score -= 3.0;

    if (newCount >= 22 && newCount <= 27) score += 1.0;

    if (currentCount < 10) score += card.rank.peggingValue * 0.1;

    return score;
  }

  int _checkRunLength(List<PlayingCard> cards) {
    final maxCheck = cards.length < 7 ? cards.length : 7;
    for (var length = maxCheck; length >= 3; length--) {
      final recent = cards.sublist(cards.length - length);
      final ranks = recent.map((c) => c.rank.index).toList()..sort();
      var isRun = true;
      for (var i = 1; i < ranks.length; i++) {
        if (ranks[i] - ranks[i - 1] != 1) {
          isRun = false;
          break;
        }
      }
      if (isRun) return length;
    }
    return 0;
  }

  double _averageHandScore(List<PlayingCard> keep) {
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

  double _averageCribScore(List<PlayingCard> discard) {
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
