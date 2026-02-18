import 'package:flutter/foundation.dart';
import '../../../core/models/game_history_event.dart';
import '../../../core/models/game_state.dart';
import 'animation_event.dart';

/// Diffs GameState.history between old and new states, mapping new
/// GameHistoryEvents to AnimationEvents that widgets consume.
///
/// Widgets listen to [events] and trigger their own AnimationControllers.
class GameAnimationController extends ChangeNotifier {
  List<AnimationEvent> _events = [];
  int _lastHistoryLength = 0;
  Map<String, int> _lastScores = {};

  /// Current batch of animation events to process.
  List<AnimationEvent> get events => _events;

  /// Call when a new GameState arrives. Diffs history and emits events.
  void processStateUpdate(GameState newState) {
    final newHistory = newState.history;
    final newEvents = <AnimationEvent>[];

    // Detect score changes
    for (final player in newState.players) {
      final oldScore = _lastScores[player.id] ?? 0;
      if (player.score != oldScore) {
        newEvents.add(ScoreChangedEvent(
          playerId: player.id,
          oldScore: oldScore,
          newScore: player.score,
        ));
      }
    }
    _lastScores = {for (final p in newState.players) p.id: p.score};

    // Diff history to find new events
    if (newHistory.length > _lastHistoryLength) {
      final additions = newHistory.sublist(_lastHistoryLength);

      // Queue overflow safety: if too many events, skip animations
      if (additions.length > 5) {
        _lastHistoryLength = newHistory.length;
        _events = [];
        notifyListeners();
        return;
      }

      for (final event in additions) {
        final animEvent = _mapHistoryEvent(event);
        if (animEvent != null) {
          newEvents.add(animEvent);
        }
      }
    }

    _lastHistoryLength = newHistory.length;
    _events = newEvents;
    notifyListeners();
  }

  AnimationEvent? _mapHistoryEvent(GameHistoryEvent event) {
    return switch (event) {
      CardsDealt() => const CardsDealtEvent(cardCount: 6),
      DeckCut(:final cutCard) => CutCardRevealedEvent(card: cutCard),
      CardPlayed(:final playerId, :final card) =>
        CardPlayedAnimEvent(playerId: playerId, card: card),
      CribCounted() => const CribRevealedEvent(),
      RoundStarted() => null,
      GoAnnounced() => null,
      PeggingEnded() => null,
      HandCounted() => null,
      GameEnded() => null,
    };
  }

  /// Reset state (e.g., when switching games).
  void reset() {
    _events = [];
    _lastHistoryLength = 0;
    _lastScores = {};
  }
}
