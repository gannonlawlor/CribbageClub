import '../../models/card.dart';
import '../../models/game_action.dart';
import '../../models/game_state.dart';

abstract class AIPlayer {
  String get playerId;
  String get playerName;

  GameAction? getNextAction(GameState gameState);
  List<PlayingCard> chooseCardsToDiscard(List<PlayingCard> hand, bool isDealer);
  PlayingCard? chooseCardToPlay(
    List<PlayingCard> hand,
    List<PlayingCard> playedCards,
    int currentCount,
  );

  bool isDealer(GameState gameState) {
    final idx = gameState.dealerIndex;
    return idx >= 0 &&
        idx < gameState.players.length &&
        gameState.players[idx].id == playerId;
  }
}
