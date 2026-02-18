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
  String? _lastStage;

  /// Current batch of animation events to process.
  List<AnimationEvent> get events => _events;

  /// Call when a new GameState arrives. Diffs history and emits events.
  void processStateUpdate(GameState newState) {
    final newHistory = newState.history;
    final newEvents = <AnimationEvent>[];

    // Detect stage changes
    final currentStage = newState.stage.name;
    if (_lastStage != null && _lastStage != currentStage) {
      newEvents.add(
        StageChangedEvent(oldStage: _lastStage!, newStage: currentStage),
      );
    }
    _lastStage = currentStage;

    // Collect scoring context from new history events for enriching score changes
    final scoringContext = <String, _ScoringContext>{};
    if (newHistory.length > _lastHistoryLength) {
      final additions = newHistory.sublist(_lastHistoryLength);

      // Queue overflow safety: if too many events, skip animations
      if (additions.length > 5) {
        _lastHistoryLength = newHistory.length;
        _lastScores = {for (final p in newState.players) p.id: p.score};
        _events = newEvents; // still emit stage change if present
        notifyListeners();
        return;
      }

      // First pass: extract scoring context from history events
      for (final event in additions) {
        switch (event) {
          case CardPlayed(
            :final playerId,
            :final pointsScored,
            :final scoringReason,
          ):
            if (pointsScored > 0) {
              scoringContext[playerId] = _ScoringContext(
                source: ScoreSource.pegging,
                reason: scoringReason,
              );
            }
          case DeckCut(:final cuttingPlayerId, :final dealerScoredNobs):
            if (dealerScoredNobs) {
              // Nobs are scored by the dealer, not the cutter
              // Find the dealer: they're the player who is NOT the cutter
              for (final p in newState.players) {
                if (p.id != cuttingPlayerId) {
                  scoringContext[p.id] = _ScoringContext(
                    source: ScoreSource.nobs,
                    reason: 'His Nobs',
                  );
                }
              }
            }
          case GoAnnounced(:final playerId, :final pointsScored):
            if (pointsScored > 0) {
              scoringContext[playerId] = _ScoringContext(
                source: ScoreSource.go,
                reason: 'Last card',
              );
            }
          case HandCounted(:final playerId, :final scoreBreakdown):
            scoringContext[playerId] = _ScoringContext(
              source: ScoreSource.hand,
              reason: _formatBreakdown(scoreBreakdown),
              breakdown: scoreBreakdown,
            );
          case CribCounted(:final dealerPlayerId, :final scoreBreakdown):
            scoringContext[dealerPlayerId] = _ScoringContext(
              source: ScoreSource.crib,
              reason: _formatBreakdown(scoreBreakdown),
              breakdown: scoreBreakdown,
            );
          default:
            break;
        }
      }

      // Second pass: map history events to animation events
      for (final event in additions) {
        final animEvent = _mapHistoryEvent(event);
        if (animEvent != null) {
          newEvents.add(animEvent);
        }
      }
    }

    // Detect score changes and enrich with context
    for (final player in newState.players) {
      final oldScore = _lastScores[player.id] ?? 0;
      if (player.score != oldScore) {
        final ctx = scoringContext[player.id];
        newEvents.add(
          ScoreChangedEvent(
            playerId: player.id,
            oldScore: oldScore,
            newScore: player.score,
            reason: ctx?.reason,
            breakdown: ctx?.breakdown,
            source: ctx?.source,
          ),
        );
      }
    }
    _lastScores = {for (final p in newState.players) p.id: p.score};

    _lastHistoryLength = newHistory.length;
    _events = newEvents;
    notifyListeners();
  }

  AnimationEvent? _mapHistoryEvent(GameHistoryEvent event) {
    return switch (event) {
      CardsDealt() => const CardsDealtEvent(cardCount: 6),
      DeckCut(:final cutCard) => CutCardRevealedEvent(card: cutCard),
      CardPlayed(:final playerId, :final card) => CardPlayedAnimEvent(
        playerId: playerId,
        card: card,
      ),
      CribCounted() => const CribRevealedEvent(),
      RoundStarted() => null,
      GoAnnounced() => null,
      PeggingEnded() => null,
      HandCounted() => null,
      GameEnded() => null,
      GameForfeited() => null,
    };
  }

  String _formatBreakdown(dynamic breakdown) {
    final parts = <String>[];
    if (breakdown.fifteens > 0) parts.add('${breakdown.fifteens} fifteens');
    if (breakdown.pairs > 0) parts.add('${breakdown.pairs} pairs');
    if (breakdown.runs > 0) parts.add('${breakdown.runs} runs');
    if (breakdown.flushes > 0) parts.add('${breakdown.flushes} flush');
    if (breakdown.nobs > 0) parts.add('${breakdown.nobs} nobs');
    return parts.isEmpty ? '' : parts.join(', ');
  }

  /// Reset state (e.g., when switching games).
  void reset() {
    _events = [];
    _lastHistoryLength = 0;
    _lastScores = {};
    _lastStage = null;
  }
}

class _ScoringContext {
  final ScoreSource source;
  final String? reason;
  final dynamic breakdown;

  const _ScoringContext({required this.source, this.reason, this.breakdown});
}
