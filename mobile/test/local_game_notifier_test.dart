import 'package:flutter_test/flutter_test.dart';
import 'package:cribbage_club/core/engine/local_game_service.dart';
import 'package:cribbage_club/core/models/card.dart';
import 'package:cribbage_club/core/models/game_state.dart';
import 'package:cribbage_club/core/services/game_feedback_service.dart';
import 'package:cribbage_club/features/game/animation/game_animation_controller.dart';
import 'package:cribbage_club/features/game/state/local_game_notifier.dart';
import 'package:cribbage_club/src/rust/frb_generated.dart';

/// Creates a notifier with fresh animation controller and feedback service.
/// The caller is responsible for calling notifier.dispose() which also
/// disposes the animation controller.
LocalGameNotifier _createNotifier({
  required String gameId,
  required LocalGameService service,
  required String playerId,
}) {
  return LocalGameNotifier(
    gameId: gameId,
    service: service,
    playerId: playerId,
    animationController: GameAnimationController(),
    feedbackService: GameFeedbackService(
      soundEnabled: false,
      hapticsEnabled: false,
    ),
    getAiDelay: () => Duration.zero,
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await RustLib.init();
  });

  group('LocalGameNotifier', () {
    test('starts with error state when service has no active game', () {
      final service = LocalGameService();
      // Service has no game — currentState is null

      final notifier = _createNotifier(
        gameId: 'local_stale_12345',
        service: service,
        playerId: 'local_player',
      );

      expect(notifier.debugState.gameState, isNull);
      expect(notifier.debugState.error, isNotNull);
      expect(notifier.debugState.error, contains('Game not found'));

      notifier.dispose();
    });

    test('starts with valid game state when service has active game', () async {
      final service = LocalGameService();
      final created = await service.createGame(
        humanPlayerId: 'player1',
        humanPlayerName: 'Player',
        difficulty: 'basic',
      );

      final notifier = _createNotifier(
        gameId: created.gameId,
        service: service,
        playerId: 'player1',
      );

      expect(notifier.debugState.gameState, isNotNull);
      expect(notifier.debugState.error, isNull);
      expect(notifier.debugState.gameState!.gameId, created.gameId);
      expect(notifier.debugState.gameState!.stage, GameStage.discardingToCrib);

      notifier.dispose();
    });

    test('clearError removes error from state', () async {
      final service = LocalGameService();
      await service.createGame(
        humanPlayerId: 'player1',
        humanPlayerName: 'Player',
        difficulty: 'basic',
      );

      final notifier = _createNotifier(
        gameId: 'local_test',
        service: service,
        playerId: 'player1',
      );

      // Force an error by trying to play a card not in hand
      notifier.playCard(const PlayingCard(rank: Rank.ace, suit: Suit.spades));
      // Whether or not it errors, clearError should reset it
      notifier.clearError();
      expect(notifier.debugState.error, isNull);

      notifier.dispose();
    });

    test('discardCards updates state after valid discard', () async {
      final service = LocalGameService();
      final created = await service.createGame(
        humanPlayerId: 'player1',
        humanPlayerName: 'Player',
        difficulty: 'basic',
      );

      final notifier = _createNotifier(
        gameId: created.gameId,
        service: service,
        playerId: 'player1',
      );

      final hand = notifier.debugState.gameState!.players[0].hand;
      expect(hand.length, 6);

      // Discard 2 cards
      notifier.discardCards([hand[0], hand[1]]);

      final updated = notifier.debugState.gameState!;
      // After discarding 2, hand should have 4
      // (AI also discards, so stage may have advanced)
      final playerHand = updated.players
          .firstWhere((p) => p.id == 'player1')
          .hand;
      expect(playerHand.length, 4);

      notifier.dispose();
    });
  });
}
