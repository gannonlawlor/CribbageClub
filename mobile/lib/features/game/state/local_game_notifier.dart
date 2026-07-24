import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/local_game_service.dart';
import '../../../core/models/card.dart';
import '../../../core/models/game_action.dart';
import '../../../core/models/game_history_event.dart';
import '../../../core/models/game_state.dart';
import '../../../core/services/game_feedback_service.dart';
import '../animation/animation_event.dart';
import '../animation/game_animation_controller.dart';
import 'game_providers.dart';

class LocalGameNotifier extends StateNotifier<GameNotifierState> {
  final String gameId;
  final LocalGameService _service;
  final String _playerId;
  final GameAnimationController animationController;
  final GameFeedbackService _feedbackService;
  final Duration Function() _getAiDelay;
  final Duration Function() _getScorePause;
  final Duration Function() _getSetupDelay;
  bool _disposed = false;

  LocalGameNotifier({
    required this.gameId,
    required LocalGameService service,
    required String playerId,
    required this.animationController,
    required GameFeedbackService feedbackService,
    required Duration Function() getAiDelay,
    required Duration Function() getScorePause,
    required Duration Function() getSetupDelay,
  }) : _service = service,
       _playerId = playerId,
       _feedbackService = feedbackService,
       _getAiDelay = getAiDelay,
       _getScorePause = getScorePause,
       _getSetupDelay = getSetupDelay,
       super(
         service.currentState != null
             ? GameNotifierState(gameState: service.currentState)
             : const GameNotifierState(
                 error:
                     'Game not found. It may have been lost after a page refresh.',
               ),
       ) {
    final cs = service.currentState;
    if (cs != null) _notifyAnimation(cs);
  }

  void _notifyAnimation(GameState newState) {
    animationController.processStateUpdate(newState);
    for (final event in animationController.events) {
      _feedbackService.onEvent(event);
    }
  }

  /// True when the update just handed to the animation controller scored —
  /// the score pill is on screen and needs a moment before anything lands on
  /// top of it.
  bool get _lastUpdateScored =>
      animationController.events.any((e) => e is ScoreChangedEvent);

  /// How long to hold before the engine's next move. Pegging and counting get
  /// a full beat each — they're the moves you actually read — while dealing,
  /// discarding and cutting stay brisk.
  Duration _pauseBeforeAi(GameState current) {
    switch (current.stage) {
      case GameStage.pegging:
      case GameStage.counting:
        final base = _getAiDelay();
        return _lastUpdateScored ? base + _getScorePause() : base;
      case GameStage.dealing:
      case GameStage.discardingToCrib:
      case GameStage.cutting:
      case GameStage.gameOver:
        return _getSetupDelay();
    }
  }

  /// Play the engine's turn one action at a time, pausing between each, so a
  /// run of pegging plays reads as separate moves rather than arriving all at
  /// once. Stops as soon as the turn is back with the player.
  Future<void> _runAiTurn() async {
    // Enough for a full pegging round plus the counts; the no-progress check
    // below is what actually ends the loop.
    for (var step = 0; step < 16; step++) {
      final current = state.gameState;
      if (current == null || current.stage == GameStage.gameOver) return;
      if (current.currentPlayerId?.startsWith('ai_') != true) return;

      await Future.delayed(_pauseBeforeAi(current));
      if (_disposed) return;

      final next = _service.processAIStep();
      // The engine had nothing left to apply — stop rather than spin.
      if (next == current) return;

      state = GameNotifierState(gameState: next);
      _notifyAnimation(next);
    }
  }

  /// Apply a human action, show the result, then let the engine answer at a
  /// readable pace.
  Future<void> _applyActionWithDelay(GameAction action) async {
    try {
      // Apply the human action and show intermediate state immediately
      final intermediate = _service.applyActionOnly(action);
      state = GameNotifierState(gameState: intermediate);
      _notifyAnimation(intermediate);

      await _runAiTurn();
    } catch (e) {
      if (!_disposed) {
        debugPrint('[LocalGame] Action failed for $gameId: $e');
        state = state.copyWith(error: 'Action failed: $e');
      }
    }
  }

  void discardCards(List<PlayingCard> cards) async {
    if (state.isDiscarding) return;
    state = state.copyWith(isDiscarding: true, error: null);
    try {
      // Apply both discards without AI processing
      GameState? intermediate;
      for (final card in cards) {
        intermediate = _service.applyActionOnly(
          GameAction.discardToCrib(playerId: _playerId, card: card),
        );
      }
      if (intermediate != null) {
        state = GameNotifierState(gameState: intermediate);
        _notifyAnimation(intermediate);

        // If AI needs to act (discard + possibly cut), let it play out
        await _runAiTurn();
      }
    } catch (e) {
      if (!_disposed) {
        debugPrint('[LocalGame] Discard failed for $gameId: $e');
        state = state.copyWith(
          isDiscarding: false,
          error: 'Discard failed: $e',
        );
      }
    }
  }

  void playCard(PlayingCard card) {
    _applyActionWithDelay(GameAction.playCard(playerId: _playerId, card: card));
  }

  void cutDeck() {
    _applyActionWithDelay(GameAction.cutDeck(playerId: _playerId));
  }

  void sayGo() {
    _applyActionWithDelay(GameAction.go(playerId: _playerId));
  }

  void countHand() {
    _applyActionWithDelay(GameAction.countHand(playerId: _playerId));
  }

  void countCrib() {
    _applyActionWithDelay(GameAction.countCrib(playerId: _playerId));
  }

  /// Advance past the dealing stage (used when auto-deal is OFF).
  void deal() {
    try {
      final finalState = _service.processAI();
      state = GameNotifierState(gameState: finalState);
      _notifyAnimation(finalState);
    } catch (e) {
      if (!_disposed) {
        debugPrint('[LocalGame] Deal failed for $gameId: $e');
        state = state.copyWith(error: 'Deal failed: $e');
      }
    }
  }

  /// Concede the game on the spot. The Rust engine has no forfeit action —
  /// it only ever ends a game by reaching 121 — so the terminal state is
  /// assembled here: the same GameForfeited + GameEnded pair the server
  /// writes, which is what the game-over panel and history already read.
  void resign() {
    final gs = state.gameState;
    if (gs == null || gs.stage == GameStage.gameOver) return;

    final winner = gs.players.firstWhere(
      (p) => p.id != _playerId,
      orElse: () => gs.players.first,
    );
    final now = DateTime.now().toUtc().toIso8601String();

    final ended = gs.copyWith(
      stage: GameStage.gameOver,
      currentPlayerId: null,
      history: [
        ...gs.history,
        GameHistoryEvent.gameForfeited(
          timestamp: now,
          forfeitingPlayerId: _playerId,
          reason: 'RESIGN',
        ),
        GameHistoryEvent.gameEnded(
          timestamp: now,
          winnerPlayerId: winner.id,
          finalScore: winner.score,
        ),
      ],
    );

    state = GameNotifierState(gameState: ended);
    _notifyAnimation(ended);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// DEV ONLY: Set a player's score directly.
  void devSetScore(String playerId, int score) {
    _service.devSetScore(playerId, score);
    final newState = _service.currentState;
    if (newState != null) {
      state = GameNotifierState(gameState: newState);
    }
  }

  /// DEV ONLY: Queue specific hands for the next deal.
  void devSetNextHands(Map<String, List<PlayingCard>> hands) {
    _service.devSetNextHands(hands);
  }

  @override
  void dispose() {
    _disposed = true;
    animationController.dispose();
    super.dispose();
  }
}
