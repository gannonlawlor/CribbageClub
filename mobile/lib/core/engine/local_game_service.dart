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

  GameState createGame({
    required String humanPlayerId,
    required String humanPlayerName,
    required String difficulty,
  }) {
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

    _engine = rust.engineNew(
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

  GameState applyHumanAction(GameAction action) {
    final actionJson = jsonEncode(action.toJson());
    rust.engineApplyActionJson(engine: _engine!, actionJson: actionJson);
    return _processAIActions();
  }

  /// Apply a human action without processing AI responses.
  /// Returns the intermediate state after the action.
  GameState applyActionOnly(GameAction action) {
    final actionJson = jsonEncode(action.toJson());
    rust.engineApplyActionJson(engine: _engine!, actionJson: actionJson);
    final json = rust.engineCurrentStateJson(engine: _engine!);
    return GameState.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Process pending AI actions and return the resulting state.
  GameState processAI() {
    return _processAIActions();
  }

  /// Apply a single AI action. The caller paces the turn by stepping, so the
  /// player sees one card land at a time instead of the whole sequence at
  /// once. Returns the state unchanged when the AI has nothing left to do.
  GameState processAIStep() {
    return _processAIActions(maxIterations: 1);
  }

  GameState restoreGame({
    required String stateJson,
    required String aiPlayerId,
    required String difficulty,
  }) {
    _engine = rust.engineRestore(stateJson: stateJson);
    _aiPlayerId = aiPlayerId;
    _difficulty = difficulty;
    return currentState!;
  }

  String? get aiPlayerId => _aiPlayerId;
  String? get difficulty => _difficulty;

  bool get hasActiveGame => _engine != null;

  GameState? get currentState {
    if (_engine == null) return null;
    final json = rust.engineCurrentStateJson(engine: _engine!);
    return GameState.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  /// DEV ONLY: Set a player's score.
  void devSetScore(String playerId, int score) {
    if (_engine == null) return;
    rust.engineDevSetScore(engine: _engine!, playerId: playerId, score: score);
  }

  /// DEV ONLY: Queue specific hands for next deal.
  void devSetNextHands(Map<String, List<PlayingCard>> hands) {
    if (_engine == null) return;
    final rustHands = hands.map(
      (playerId, cards) =>
          MapEntry(playerId, cards.map((c) => c.toJson()).toList()),
    );
    rust.engineDevSetNextHandsJson(
      engine: _engine!,
      handsJson: jsonEncode(rustHands),
    );
  }

  GameState _processAIActions({int? maxIterations}) {
    final stateJson = rust.engineProcessAiJson(
      engine: _engine!,
      aiPlayerId: _aiPlayerId!,
      difficulty: _difficulty!,
      maxIterations: maxIterations ?? _maxAIIterations,
    );
    return GameState.fromJson(jsonDecode(stateJson) as Map<String, dynamic>);
  }
}
