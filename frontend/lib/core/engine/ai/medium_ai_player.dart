import '../../models/card.dart';
import '../../models/game_action.dart';
import '../../models/game_state.dart';
import '../hand_counting.dart';
import 'ai_player.dart';
import 'ai_utils.dart';

class MediumAIPlayer extends AIPlayer {
  @override
  final String playerId;
  @override
  final String playerName;

  MediumAIPlayer({
    required this.playerId,
    this.playerName = 'AI Player (Medium)',
  });

  @override
  GameAction? getNextAction(GameState gameState) {
    if (gameState.currentPlayerId != playerId) return null;
    final player = gameState.players.firstWhere((p) => p.id == playerId);

    return switch (gameState.stage) {
      GameStage.discardingToCrib => () {
          final discarded = 6 - player.hand.length;
          if (discarded < 2) {
            final cardsToDiscard =
                chooseCardsToDiscard(player.hand, isDealer(gameState));
            if (discarded < cardsToDiscard.length) {
              return GameAction.discardToCrib(
                playerId: playerId,
                card: cardsToDiscard[discarded],
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
    var bestScore = -1.0;

    for (final keep in AIUtils.combinations(hand, 4)) {
      final avgScore = _averageHandScore(keep);
      if (avgScore > bestScore) {
        bestScore = avgScore;
        final keepSet = keep.toSet();
        bestDiscard = hand.where((c) => !keepSet.contains(c)).toList();
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

    // Priority 1: Make 31
    for (final c in playable) {
      if (currentCount + c.rank.peggingValue == 31) return c;
    }

    // Priority 2: Make 15
    for (final c in playable) {
      if (currentCount + c.rank.peggingValue == 15) return c;
    }

    // Priority 3: Pair (with trips check)
    if (playedCards.isNotEmpty) {
      final lastRank = playedCards.last.rank;
      final pairCard = playable.where((c) => c.rank == lastRank).firstOrNull;
      if (pairCard != null) {
        final weHaveTrips =
            playable.where((c) => c.rank == lastRank).length >= 2;
        final lastPlayed =
            playedCards.where((c) => c.rank == lastRank).length;
        if (weHaveTrips || lastPlayed == 1) return pairCard;
      }
    }

    // Priority 4: Run continuation
    if (playedCards.length >= 2) {
      final runCard = AIUtils.findRunContinuation(playable, playedCards);
      if (runCard != null) return runCard;
    }

    // Priority 5: Safe play
    final safe = playable.where((c) {
      final nc = currentCount + c.rank.peggingValue;
      return nc != 5 && nc != 16 && nc != 21;
    }).toList();

    if (safe.isNotEmpty) {
      return safe.reduce(
          (a, b) => a.rank.peggingValue >= b.rank.peggingValue ? a : b);
    }

    return playable.reduce(
        (a, b) => a.rank.peggingValue <= b.rank.peggingValue ? a : b);
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
}
