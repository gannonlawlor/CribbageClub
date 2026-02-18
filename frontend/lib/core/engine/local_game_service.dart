import 'dart:convert';
import 'dart:math';

import '../models/card.dart';
import '../models/game_action.dart';
import '../models/game_state.dart';
import '../../src/rust/api/simple.dart' as rust;

class LocalGameService {
  rust.RustGameEngine? _engine;
  String? _aiPlayerId;
  String? _difficulty;

  static const _maxAIIterations = 10;

  Future<GameState> createGame({
    required String humanPlayerId,
    required String humanPlayerName,
    required String difficulty,
  }) async {
    final gameId =
        'local_${DateTime.now().millisecondsSinceEpoch}_'
        '${Random().nextInt(9000) + 1000}';
    final aiPlayerId = 'ai_${Random().nextInt(9000) + 1000}';

    final aiName = switch (difficulty) {
      'medium' => 'AI (Medium)',
      'hard' => 'AI (Hard)',
      _ => 'AI (Easy)',
    };
    final rustDifficulty = switch (difficulty) {
      'medium' => 'medium',
      'hard' => 'hard',
      _ => 'easy',
    };

    _engine = await rust.engineNew(
      gameId: gameId,
      player1Id: humanPlayerId,
      player1Name: humanPlayerName,
      player2Id: aiPlayerId,
      player2Name: aiName,
      seed: null,
    );
    _aiPlayerId = aiPlayerId;
    _difficulty = rustDifficulty;

    return _processAIActions();
  }

  Future<GameState> applyHumanAction(GameAction action) async {
    final actionJson = jsonEncode(action.toJson());
    await rust.engineApplyActionJson(
      engine: _engine!,
      actionJson: actionJson,
    );
    return _processAIActions();
  }

  bool get hasActiveGame => _engine != null;

  GameState? get currentState {
    if (_engine == null) return null;
    final json = rust.engineCurrentStateJson(engine: _engine!);
    return GameState.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  /// DEV ONLY: Set a player's score.
  Future<void> devSetScore(String playerId, int score) async {
    if (_engine == null) return;
    await rust.engineDevSetScore(
      engine: _engine!,
      playerId: playerId,
      score: score,
    );
  }

  /// DEV ONLY: Queue specific hands for next deal.
  Future<void> devSetNextHands(Map<String, List<PlayingCard>> hands) async {
    if (_engine == null) return;
    final rustHands = hands.map(
      (playerId, cards) => MapEntry(playerId, cards.map((c) => c.toJson()).toList()),
    );
    await rust.engineDevSetNextHandsJson(
      engine: _engine!,
      handsJson: jsonEncode(rustHands),
    );
  }

  Future<GameState> _processAIActions() async {
    final stateJson = await rust.engineProcessAiJson(
      engine: _engine!,
      aiPlayerId: _aiPlayerId!,
      difficulty: _difficulty!,
      maxIterations: _maxAIIterations,
    );
    return GameState.fromJson(jsonDecode(stateJson) as Map<String, dynamic>);
  }
}
