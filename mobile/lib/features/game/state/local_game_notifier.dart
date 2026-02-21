import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants.dart';
import '../../../core/engine/local_game_service.dart';
import '../../../core/models/card.dart';
import '../../../core/models/game_action.dart';
import '../../../core/models/game_state.dart';
import '../../../core/services/game_feedback_service.dart';
import '../animation/game_animation_controller.dart';
import 'game_providers.dart';

class LocalGameNotifier extends StateNotifier<GameNotifierState> {
  final String gameId;
  final LocalGameService _service;
  final String _playerId;
  final GameAnimationController animationController;
  final GameFeedbackService _feedbackService;
  bool _disposed = false;

  LocalGameNotifier({
    required this.gameId,
    required LocalGameService service,
    required String playerId,
    required this.animationController,
    required GameFeedbackService feedbackService,
  }) : _service = service,
       _playerId = playerId,
       _feedbackService = feedbackService,
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

  /// Apply a human action, show the intermediate state, then delay before
  /// processing AI responses to simulate "thinking".
  Future<void> _applyActionWithDelay(GameAction action) async {
    try {
      // Apply the human action and show intermediate state immediately
      final intermediate = _service.applyActionOnly(action);
      state = GameNotifierState(gameState: intermediate);
      _notifyAnimation(intermediate);

      // If it's now the AI's turn, wait then process
      if (intermediate.currentPlayerId?.startsWith('ai_') == true) {
        await Future.delayed(AppConstants.aiThinkingDelay);
        if (_disposed) return;
        final finalState = _service.processAI();
        state = GameNotifierState(gameState: finalState);
        _notifyAnimation(finalState);
      }
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

        // If AI needs to act (discard + possibly cut), delay then process
        if (intermediate.currentPlayerId?.startsWith('ai_') == true) {
          await Future.delayed(AppConstants.aiThinkingDelay);
          if (_disposed) return;
          final finalState = _service.processAI();
          state = GameNotifierState(gameState: finalState);
          _notifyAnimation(finalState);
        }
      }
    } catch (e) {
      if (!_disposed) {
        debugPrint('[LocalGame] Discard failed for $gameId: $e');
        state = state.copyWith(isDiscarding: false, error: 'Discard failed: $e');
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
