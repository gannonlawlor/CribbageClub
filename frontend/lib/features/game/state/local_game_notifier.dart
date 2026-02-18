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
  })  : _service = service,
        _playerId = playerId,
        _feedbackService = feedbackService,
        super(GameNotifierState(
          gameState: service.currentState,
        )) {
    _notifyAnimation(service.currentState);
  }

  void _notifyAnimation(GameState newState) {
    animationController.processStateUpdate(newState);
    for (final event in animationController.events) {
      _feedbackService.onEvent(event);
    }
  }

  void _applyAction(GameAction action) {
    try {
      final newState = _service.applyHumanAction(action);
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
        newState = _service.applyHumanAction(
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
    _applyAction(GameAction.playCard(playerId: _playerId, card: card));
  }

  Future<void> cutDeck() async {
    _applyAction(GameAction.cutDeck(playerId: _playerId));
  }

  Future<void> sayGo() async {
    _applyAction(GameAction.go(playerId: _playerId));
  }

  Future<void> countHand() async {
    _applyAction(GameAction.countHand(playerId: _playerId));
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}
