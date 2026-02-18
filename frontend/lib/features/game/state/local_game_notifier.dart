import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> _applyAction(GameAction action) async {
    try {
      final newState = await _service.applyHumanAction(action);
      state = GameNotifierState(gameState: newState);
      _notifyAnimation(newState);
    } catch (e) {
      state = state.copyWith(error: 'Action failed: $e');
    }
  }

  Future<void> discardCards(List<PlayingCard> cards) async {
    if (state.isDiscarding) return;
    state = state.copyWith(isDiscarding: true, error: null);
    try {
      GameState? newState;
      for (final card in cards) {
        newState = await _service.applyHumanAction(
          GameAction.discardToCrib(playerId: _playerId, card: card),
        );
      }
      if (newState != null) {
        state = GameNotifierState(gameState: newState);
        _notifyAnimation(newState);
      }
    } catch (e) {
      state = state.copyWith(isDiscarding: false, error: 'Discard failed: $e');
    }
  }

  Future<void> playCard(PlayingCard card) async {
    await _applyAction(GameAction.playCard(playerId: _playerId, card: card));
  }

  Future<void> cutDeck() async {
    await _applyAction(GameAction.cutDeck(playerId: _playerId));
  }

  Future<void> sayGo() async {
    await _applyAction(GameAction.go(playerId: _playerId));
  }

  Future<void> countHand() async {
    await _applyAction(GameAction.countHand(playerId: _playerId));
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// DEV ONLY: Set a player's score directly.
  Future<void> devSetScore(String playerId, int score) async {
    await _service.devSetScore(playerId, score);
    final newState = _service.currentState;
    if (newState != null) {
      state = GameNotifierState(gameState: newState);
    }
  }

  /// DEV ONLY: Queue specific hands for the next deal.
  Future<void> devSetNextHands(Map<String, List<PlayingCard>> hands) async {
    await _service.devSetNextHands(hands);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}
