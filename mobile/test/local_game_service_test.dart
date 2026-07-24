import 'package:flutter_test/flutter_test.dart';
import 'package:cribbage_club/core/engine/local_game_service.dart';
import 'package:cribbage_club/core/models/game_action.dart';
import 'package:cribbage_club/core/models/game_state.dart';
import 'package:cribbage_club/src/rust/frb_generated.dart';

void main() {
  group('LocalGameService', () {
    late LocalGameService service;

    setUpAll(() async {
      await RustLib.init();
    });

    setUp(() {
      service = LocalGameService();
    });

    test('hasActiveGame is false before creating a game', () {
      expect(service.hasActiveGame, isFalse);
    });

    test('currentState is null before creating a game', () {
      expect(service.currentState, isNull);
    });

    test('hasActiveGame is true after creating a game', () async {
      await service.createGame(
        humanPlayerId: 'player1',
        humanPlayerName: 'Player',
        difficulty: 'basic',
      );
      expect(service.hasActiveGame, isTrue);
    });

    test('currentState is non-null after creating a game', () async {
      await service.createGame(
        humanPlayerId: 'player1',
        humanPlayerName: 'Player',
        difficulty: 'basic',
      );
      expect(service.currentState, isNotNull);
    });

    test('createGame returns valid initial state', () async {
      final state = await service.createGame(
        humanPlayerId: 'player1',
        humanPlayerName: 'Player',
        difficulty: 'basic',
      );

      expect(state.gameId, startsWith('local_'));
      expect(state.players.length, 2);
      // Seat order is randomized so the first dealer is a coin flip; find
      // each player by id rather than position.
      final human = state.players.firstWhere((p) => p.id == 'player1');
      final ai = state.players.firstWhere((p) => p.id.startsWith('ai_'));
      expect(human.name, 'Player');
      expect(ai.id, startsWith('ai_'));
      expect(state.stage, GameStage.discardingToCrib);
      expect(state.currentPlayerId, isNotNull);
      // Human player has 6 cards to start
      expect(human.hand.length, 6);
    });

    test(
      'createGame with different difficulties sets correct AI name',
      () async {
        final easyService = LocalGameService();
        await easyService.createGame(
          humanPlayerId: 'p',
          humanPlayerName: 'P',
          difficulty: 'basic',
        );
        expect(
          easyService.currentState!.players
              .firstWhere((p) => p.id.startsWith('ai_'))
              .name,
          'AI (Easy)',
        );

        final mediumService = LocalGameService();
        await mediumService.createGame(
          humanPlayerId: 'p',
          humanPlayerName: 'P',
          difficulty: 'medium',
        );
        expect(
          mediumService.currentState!.players
              .firstWhere((p) => p.id.startsWith('ai_'))
              .name,
          'AI (Medium)',
        );

        final hardService = LocalGameService();
        await hardService.createGame(
          humanPlayerId: 'p',
          humanPlayerName: 'P',
          difficulty: 'hard',
        );
        expect(
          hardService.currentState!.players
              .firstWhere((p) => p.id.startsWith('ai_'))
              .name,
          'AI (Hard)',
        );
      },
    );

    test('currentState matches last created game', () async {
      final state = await service.createGame(
        humanPlayerId: 'player1',
        humanPlayerName: 'Player',
        difficulty: 'basic',
      );

      final current = service.currentState!;
      expect(current.gameId, state.gameId);
      expect(current.players.length, state.players.length);
      expect(current.stage, state.stage);
    });

    test('applyHumanAction works after creating a game', () async {
      final state = await service.createGame(
        humanPlayerId: 'player1',
        humanPlayerName: 'Player',
        difficulty: 'basic',
      );

      // Discard first card from the human's hand
      final card = state.players.firstWhere((p) => p.id == 'player1').hand[0];
      final newState = await service.applyHumanAction(
        GameAction.discardToCrib(playerId: 'player1', card: card),
      );

      // After discarding one card, hand should have 5
      final human = newState.players.firstWhere((p) => p.id == 'player1');
      expect(human.hand.length, 5);
      expect(human.hand.contains(card), isFalse);
    });
  });
}
