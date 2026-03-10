import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../../features/game/animation/animation_event.dart';

/// Provides audio and haptic feedback in response to game events.
/// Uses audioplayers package for per-event custom sounds.
class GameFeedbackService {
  bool soundEnabled;
  bool hapticsEnabled;

  // Separate players to allow overlapping sounds (lazy to avoid plugin errors in tests)
  AudioPlayer? _cardPlayer;
  AudioPlayer? _scorePlayer;
  AudioPlayer? _uiPlayer;

  AudioPlayer get _card => _cardPlayer ??= AudioPlayer();
  AudioPlayer get _score => _scorePlayer ??= AudioPlayer();
  AudioPlayer get _ui => _uiPlayer ??= AudioPlayer();

  GameFeedbackService({this.soundEnabled = true, this.hapticsEnabled = true});

  /// Process an animation event and trigger appropriate feedback.
  void onEvent(AnimationEvent event) {
    switch (event) {
      case CardPlayedAnimEvent():
        _playSound(() => _card, 'card_play.wav');
        _haptic(HapticFeedback.lightImpact);
      case CardsDealtEvent():
        _playSound(() => _card, 'card_deal.wav');
        _haptic(HapticFeedback.selectionClick);
      case CardsDiscardedEvent():
        _playSound(() => _card, 'discard.wav');
        _haptic(HapticFeedback.lightImpact);
      case CutCardRevealedEvent():
        _playSound(() => _ui, 'cut_card.wav');
        _haptic(HapticFeedback.lightImpact);
      case CribRevealedEvent():
        _playSound(() => _ui, 'stage_change.wav');
        _haptic(HapticFeedback.selectionClick);
      case ScoreChangedEvent():
        _playSound(() => _score, 'score.wav');
        _haptic(HapticFeedback.mediumImpact);
      case StageChangedEvent(:final newStage):
        if (newStage == 'gameOver') {
          _playSound(() => _ui, 'game_over.wav');
          _haptic(HapticFeedback.heavyImpact);
        } else {
          _playSound(() => _ui, 'stage_change.wav');
          _haptic(HapticFeedback.selectionClick);
        }
    }
  }

  void _playSound(AudioPlayer Function() getPlayer, String filename) {
    if (!soundEnabled) return;
    getPlayer().play(AssetSource('sounds/$filename'));
  }

  void _haptic(Future<void> Function() method) {
    if (!hapticsEnabled) return;
    method();
  }

  void dispose() {
    _cardPlayer?.dispose();
    _scorePlayer?.dispose();
    _uiPlayer?.dispose();
  }
}
