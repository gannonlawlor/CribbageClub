import 'package:flutter_test/flutter_test.dart';
import 'package:cribbage_club/core/engine/local_game_service.dart';
import 'package:cribbage_club/core/models/game_action.dart';
import 'package:cribbage_club/core/models/game_state.dart';

void main() {
  group('LocalGameService', () {
    late LocalGameService service;

    setUp(() {
      service = LocalGameService();
    });

    test('hasActiveGame is false before creating a game', () {
      expect(service.hasActiveGame, isFalse);
    });

    test('currentState is null before creating a game', () {
      expect(service.currentState, isNull);
    });

    test('hasActiveGame is true after creating a game', () {
      service.createGame(
        humanPlayerId: 'player1',
        humanPlayerName: 'Player',
        difficulty: 'basic',
      );
      expect(service.hasActiveGame, isTrue);
    });

    test('currentState is non-null after creating a game', () {
      service.createGame(
        humanPlayerId: 'player1',
        humanPlayerName: 'Player',
        difficulty: 'basic',
      );
      expect(service.currentState, isNotNull);
    });

    test('createGame returns valid initial state', () {
      final state = service.createGame(
        humanPlayerId: 'player1',
        humanPlayerName: 'Player',
        difficulty: 'basic',
      );

      expect(state.gameId, startsWith('local_'));
      expect(state.players.length, 2);
      expect(state.players[0].id, 'player1');
      expect(state.players[0].name, 'Player');
      expect(state.players[1].id, startsWith('ai_'));
      expect(state.stage, GameStage.discardingToCrib);
      expect(state.currentPlayerId, isNotNull);
      // Human player has 6 cards to start
      expect(state.players[0].hand.length, 6);
    });

    test('createGame with different difficulties sets correct AI name', () {
      final easy = LocalGameService()..createGame(
        humanPlayerId: 'p', humanPlayerName: 'P', difficulty: 'basic',
      );
      expect(easy.currentState!.players[1].name, 'AI (Easy)');

      final medium = LocalGameService()..createGame(
        humanPlayerId: 'p', humanPlayerName: 'P', difficulty: 'medium',
      );
      expect(medium.currentState!.players[1].name, 'AI (Medium)');

      final hard = LocalGameService()..createGame(
        humanPlayerId: 'p', humanPlayerName: 'P', difficulty: 'hard',
      );
      expect(hard.currentState!.players[1].name, 'AI (Hard)');
    });

    test('currentState matches last created game', () {
      final state = service.createGame(
        humanPlayerId: 'player1',
        humanPlayerName: 'Player',
        difficulty: 'basic',
      );

      final current = service.currentState!;
      expect(current.gameId, state.gameId);
      expect(current.players.length, state.players.length);
      expect(current.stage, state.stage);
    });

    test('applyHumanAction works after creating a game', () {
      final state = service.createGame(
        humanPlayerId: 'player1',
        humanPlayerName: 'Player',
        difficulty: 'basic',
      );

      // Discard first card from hand
      final card = state.players[0].hand[0];
      final newState = service.applyHumanAction(
        GameAction.discardToCrib(playerId: 'player1', card: card),
      );

      // After discarding one card, hand should have 5
      expect(newState.players[0].hand.length, 5);
      expect(newState.players[0].hand.contains(card), isFalse);
    });
  });
}
