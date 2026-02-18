import '../../models/card.dart';
import '../../models/game_action.dart';
import '../../models/game_state.dart';
import 'ai_player.dart';
import 'ai_utils.dart';

class BasicAIPlayer extends AIPlayer {
  @override
  final String playerId;
  @override
  final String playerName;

  BasicAIPlayer({required this.playerId, this.playerName = 'AI Player'});

  @override
  GameAction? getNextAction(GameState gameState) {
    if (gameState.currentPlayerId != playerId) return null;
    final player = gameState.players.firstWhere((p) => p.id == playerId);

    return switch (gameState.stage) {
      GameStage.discardingToCrib => () {
        if (player.hand.length > 4) {
          final cardsToDiscard = chooseCardsToDiscard(
            player.hand,
            isDealer(gameState),
          );
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
    if (hand.length < 2) return hand;
    return isDealer
        ? _chooseDealerDiscards(hand)
        : _chooseNonDealerDiscards(hand);
  }

  List<PlayingCard> _chooseDealerDiscards(List<PlayingCard> hand) {
    final sortedByValue = List.of(hand)
      ..sort((a, b) => a.rank.peggingValue.compareTo(b.rank.peggingValue));

    // Keep pairs
    final rankGroups = <Rank, List<PlayingCard>>{};
    for (final c in hand) {
      (rankGroups[c.rank] ??= []).add(c);
    }
    final pairs = rankGroups.entries.where((e) => e.value.length >= 2);
    if (pairs.isNotEmpty) {
      final pairCards = pairs.expand((e) => e.value).toSet();
      final nonPairCards = hand.where((c) => !pairCards.contains(c)).toList();
      return nonPairCards.take(2).toList();
    }

    // Keep 15-combos
    final fifteenCombos = _findFifteenCombinations(hand);
    if (fifteenCombos.isNotEmpty) {
      final keepCards = fifteenCombos.first.toSet();
      final discardCards = hand.where((c) => !keepCards.contains(c)).toList();
      return discardCards.take(2).toList();
    }

    return sortedByValue.take(2).toList();
  }

  List<PlayingCard> _chooseNonDealerDiscards(List<PlayingCard> hand) {
    final sortedByValue = List.of(hand)
      ..sort((a, b) => b.rank.peggingValue.compareTo(a.rank.peggingValue));

    final candidates = <PlayingCard>[];
    for (final card in sortedByValue) {
      if (candidates.length >= 2) break;
      final wouldMakePair = candidates.any((c) => c.rank == card.rank);
      final wouldMake15 = candidates.any(
        (c) => c.rank.peggingValue + card.rank.peggingValue == 15,
      );
      if (!wouldMakePair && !wouldMake15) {
        candidates.add(card);
      }
    }

    return candidates.length >= 2
        ? candidates.take(2).toList()
        : sortedByValue.take(2).toList();
  }

  @override
  PlayingCard? chooseCardToPlay(
    List<PlayingCard> hand,
    List<PlayingCard> playedCards,
    int currentCount,
  ) {
    final playable = hand
        .where((c) => currentCount + c.rank.peggingValue <= 31)
        .toList();
    if (playable.isEmpty) return null;

    // Try 31
    final c31 = playable.where((c) => currentCount + c.rank.peggingValue == 31);
    if (c31.isNotEmpty) return c31.first;

    // Try 15
    final c15 = playable.where((c) => currentCount + c.rank.peggingValue == 15);
    if (c15.isNotEmpty) return c15.first;

    // Try pair
    if (playedCards.isNotEmpty) {
      final lastRank = playedCards.last.rank;
      final pairCard = playable.where((c) => c.rank == lastRank);
      if (pairCard.isNotEmpty) return pairCard.first;
    }

    // Try run
    if (playedCards.length >= 2) {
      final runCard = AIUtils.findRunContinuation(playable, playedCards);
      if (runCard != null) return runCard;
    }

    // Avoid dangerous counts
    final safe = playable.where((c) {
      final nc = currentCount + c.rank.peggingValue;
      return nc != 5 && nc != 16 && nc != 21;
    }).toList();

    if (safe.isNotEmpty) {
      return safe.reduce(
        (a, b) => a.rank.peggingValue >= b.rank.peggingValue ? a : b,
      );
    }

    return playable.reduce(
      (a, b) => a.rank.peggingValue <= b.rank.peggingValue ? a : b,
    );
  }

  List<List<PlayingCard>> _findFifteenCombinations(List<PlayingCard> cards) {
    final result = <List<PlayingCard>>[];
    for (var size = 2; size <= cards.length && size <= 5; size++) {
      for (final combo in AIUtils.combinations(cards, size)) {
        if (combo.fold<int>(0, (s, c) => s + c.rank.peggingValue) == 15) {
          result.add(combo);
        }
      }
    }
    return result;
  }
}
