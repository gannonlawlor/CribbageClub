import 'package:flutter/services.dart';
import '../../features/game/animation/animation_event.dart';

/// Provides audio (SystemSound) and haptic feedback in response to game events.
/// Zero external dependencies — uses Flutter's built-in services only.
class GameFeedbackService {
  bool soundEnabled;
  bool hapticsEnabled;

  GameFeedbackService({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
  });

  /// Process an animation event and trigger appropriate feedback.
  void onEvent(AnimationEvent event) {
    switch (event) {
      case CardPlayedAnimEvent():
        _playSound();
        _haptic(HapticFeedback.lightImpact);
      case ScoreChangedEvent():
        _playSound();
        _haptic(HapticFeedback.mediumImpact);
      case StageChangedEvent(:final newStage):
        if (newStage == 'gameOver') {
          _haptic(HapticFeedback.heavyImpact);
        } else {
          _haptic(HapticFeedback.selectionClick);
        }
      case CutCardRevealedEvent():
        _playSound();
        _haptic(HapticFeedback.lightImpact);
      case CardsDealtEvent():
        _haptic(HapticFeedback.selectionClick);
      case _:
        break;
    }
  }

  void _playSound() {
    if (!soundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  void _haptic(Future<void> Function() method) {
    if (!hapticsEnabled) return;
    method();
  }
}
