import '../../../core/models/card.dart';
import '../../../core/models/score_breakdown.dart';

/// Source of a score change for contextual popups.
enum ScoreSource { pegging, nobs, hand, crib, go }

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
  final String? reason;
  final ScoreBreakdown? breakdown;
  final ScoreSource? source;
  const ScoreChangedEvent({
    required this.playerId,
    required this.oldScore,
    required this.newScore,
    this.reason,
    this.breakdown,
    this.source,
  });

  int get points => newScore - oldScore;
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
