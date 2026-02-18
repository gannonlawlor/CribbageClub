import '../../../core/models/card.dart';

/// Events emitted by the animation controller when game state changes.
/// Widgets consume these to trigger their own AnimationControllers.
sealed class AnimationEvent {
  const AnimationEvent();
}

class CardsDealtEvent extends AnimationEvent {
  final int cardCount;
  const CardsDealtEvent({required this.cardCount});
}

class CardPlayedAnimEvent extends AnimationEvent {
  final String playerId;
  final PlayingCard card;
  const CardPlayedAnimEvent({required this.playerId, required this.card});
}

class CutCardRevealedEvent extends AnimationEvent {
  final PlayingCard card;
  const CutCardRevealedEvent({required this.card});
}

class CribRevealedEvent extends AnimationEvent {
  const CribRevealedEvent();
}

class ScoreChangedEvent extends AnimationEvent {
  final String playerId;
  final int oldScore;
  final int newScore;
  const ScoreChangedEvent({
    required this.playerId,
    required this.oldScore,
    required this.newScore,
  });
}

class StageChangedEvent extends AnimationEvent {
  final String oldStage;
  final String newStage;
  const StageChangedEvent({required this.oldStage, required this.newStage});
}

class CardsDiscardedEvent extends AnimationEvent {
  final String playerId;
  const CardsDiscardedEvent({required this.playerId});
}
