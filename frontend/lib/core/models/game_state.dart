import 'package:freezed_annotation/freezed_annotation.dart';
import 'card.dart';
import 'game_history_event.dart';
import 'player.dart';

part 'game_state.freezed.dart';
part 'game_state.g.dart';

enum GameStage {
  @JsonValue('DEALING')
  dealing,
  @JsonValue('DISCARDING_TO_CRIB')
  discardingToCrib,
  @JsonValue('CUTTING')
  cutting,
  @JsonValue('PEGGING')
  pegging,
  @JsonValue('COUNTING')
  counting,
  @JsonValue('GAME_OVER')
  gameOver;

  String get displayName {
    switch (this) {
      case GameStage.dealing:
        return 'Dealing';
      case GameStage.discardingToCrib:
        return 'Discard to Crib';
      case GameStage.cutting:
        return 'Cut the Deck';
      case GameStage.pegging:
        return 'Pegging';
      case GameStage.counting:
        return 'Counting';
      case GameStage.gameOver:
        return 'Game Over';
    }
  }
}

@freezed
class GameState with _$GameState {
  const factory GameState({
    required String gameId,
    required List<Player> players,
    @Default([]) List<PlayingCard> crib,
    PlayingCard? cutCard,
    String? currentPlayerId,
    @Default(GameStage.dealing) GameStage stage,
    @Default([]) List<PlayingCard> playedCards,
    @Default(0) int peggingCount,
    @Default(false) bool lastPlayWasGo,
    @Default({}) Map<String, List<PlayingCard>> handsForCounting,
    @Default([]) List<GameHistoryEvent> history,
    @Default(0) int dealerIndex,
    @Default([]) List<PlayingCard> remainingDeck,
  }) = _GameState;

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);
}
