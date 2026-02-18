import 'dart:math';

import '../models/game_action.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import 'ai/ai_player.dart';
import 'ai/basic_ai_player.dart';
import 'ai/hard_ai_player.dart';
import 'ai/medium_ai_player.dart';
import 'game_engine.dart';

class LocalGameService {
  GameEngine? _engine;
  AIPlayer? _aiPlayer;

  static const _maxAIIterations = 10;

  GameState createGame({
    required String humanPlayerId,
    required String humanPlayerName,
    required String difficulty,
  }) {
    final gameId = 'local_${DateTime.now().millisecondsSinceEpoch}_'
        '${Random().nextInt(9000) + 1000}';
    final aiPlayerId = 'ai_${Random().nextInt(9000) + 1000}';

    _aiPlayer = switch (difficulty) {
      'medium' => MediumAIPlayer(
          playerId: aiPlayerId, playerName: 'AI (Medium)'),
      'hard' => HardAIPlayer(
          playerId: aiPlayerId, playerName: 'AI (Hard)'),
      _ => BasicAIPlayer(
          playerId: aiPlayerId, playerName: 'AI (Easy)'),
    };

    _engine = GameEngine(
      id: gameId,
      players: [
        Player(id: humanPlayerId, name: humanPlayerName),
        Player(id: aiPlayerId, name: _aiPlayer!.playerName),
      ],
    );

    return _processAIActions();
  }

  GameState applyHumanAction(GameAction action) {
    _engine!.applyAction(action);
    return _processAIActions();
  }

  bool get hasActiveGame => _engine != null;

  GameState? get currentState => _engine?.currentState;

  /// DEV ONLY: Direct engine access for debug tools.
  GameEngine? get devEngine => _engine;

  GameState _processAIActions() {
    var state = _engine!.currentState;
    var iterations = 0;

    while (iterations < _maxAIIterations) {
      final ai = _aiPlayer;
      if (ai == null || state.currentPlayerId != ai.playerId) break;

      final action = ai.getNextAction(state);
      if (action == null) break;

      state = _engine!.applyAction(action);
      iterations++;
    }

    return state;
  }
}
