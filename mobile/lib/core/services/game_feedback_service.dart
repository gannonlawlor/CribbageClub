import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../../features/game/animation/animation_event.dart';

/// Provides audio and haptic feedback in response to game events.
/// Uses audioplayers package for per-event custom sounds.
class GameFeedbackService {
  bool soundEnabled;
  bool hapticsEnabled;

  // Separate players to allow overlapping sounds
  final AudioPlayer _cardPlayer = AudioPlayer();
  final AudioPlayer _scorePlayer = AudioPlayer();
  final AudioPlayer _uiPlayer = AudioPlayer();

  GameFeedbackService({this.soundEnabled = true, this.hapticsEnabled = true});

  /// Process an animation event and trigger appropriate feedback.
  void onEvent(AnimationEvent event) {
    switch (event) {
      case CardPlayedAnimEvent():
        _playSound(_cardPlayer, 'card_play.wav');
        _haptic(HapticFeedback.lightImpact);
      case CardsDealtEvent():
        _playSound(_cardPlayer, 'card_deal.wav');
        _haptic(HapticFeedback.selectionClick);
      case CardsDiscardedEvent():
        _playSound(_cardPlayer, 'discard.wav');
        _haptic(HapticFeedback.lightImpact);
      case CutCardRevealedEvent():
        _playSound(_uiPlayer, 'cut_card.wav');
        _haptic(HapticFeedback.lightImpact);
      case ScoreChangedEvent():
        _playSound(_scorePlayer, 'score.wav');
        _haptic(HapticFeedback.mediumImpact);
      case StageChangedEvent(:final newStage):
        if (newStage == 'gameOver') {
          _playSound(_uiPlayer, 'game_over.wav');
          _haptic(HapticFeedback.heavyImpact);
        } else {
          _playSound(_uiPlayer, 'stage_change.wav');
          _haptic(HapticFeedback.selectionClick);
        }
      case _:
        break;
    }
  }

  void _playSound(AudioPlayer player, String filename) {
    if (!soundEnabled) return;
    player.play(AssetSource('sounds/$filename'));
  }

  void _haptic(Future<void> Function() method) {
    if (!hapticsEnabled) return;
    method();
  }

  void dispose() {
    _cardPlayer.dispose();
    _scorePlayer.dispose();
    _uiPlayer.dispose();
  }
}
