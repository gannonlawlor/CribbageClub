import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';
import '../models/import_games.dart';
import '../models/local_game_record.dart';

class LocalGameHistoryService {
  static const _indexKey = 'local_game_history_index';
  static const _stateKeyPrefix = 'local_game_state_';
  static const _maxGames = 50;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> saveCompletedGame(GameState gameState) async {
    final prefs = await _preferences;

    // Determine player vs AI
    final player = gameState.players.firstWhere(
      (p) => !p.id.startsWith('ai_'),
      orElse: () => gameState.players.first,
    );
    final opponent = gameState.players.firstWhere(
      (p) => p.id != player.id,
      orElse: () => gameState.players.last,
    );

    // Extract difficulty from AI name
    final difficulty = opponent.name.contains('Medium')
        ? 'Medium'
        : opponent.name.contains('Hard')
            ? 'Hard'
            : 'Easy';

    final record = LocalGameRecord(
      gameId: gameState.gameId,
      playerName: player.name,
      opponentName: opponent.name,
      playerScore: player.score,
      opponentScore: opponent.score,
      isWin: player.score > opponent.score,
      difficulty: difficulty,
      completedAt: DateTime.now(),
    );

    // Load existing index
    final records = await getGameRecords();

    // Skip if already saved
    if (records.any((r) => r.gameId == gameState.gameId)) return;

    // Add new record at the front
    records.insert(0, record);

    // Prune oldest if over cap
    while (records.length > _maxGames) {
      final removed = records.removeLast();
      await prefs.remove('$_stateKeyPrefix${removed.gameId}');
    }

    // Save index
    final indexJson = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_indexKey, indexJson);

    // Save full game state
    final stateJson = jsonEncode(gameState.toJson());
    await prefs.setString('$_stateKeyPrefix${gameState.gameId}', stateJson);
  }

  Future<List<LocalGameRecord>> getGameRecords() async {
    final prefs = await _preferences;
    final indexStr = prefs.getString(_indexKey);
    if (indexStr == null) return [];

    final List<dynamic> decoded = jsonDecode(indexStr) as List<dynamic>;
    return decoded
        .map((e) => LocalGameRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GameState?> getGameState(String gameId) async {
    final prefs = await _preferences;
    final stateStr = prefs.getString('$_stateKeyPrefix$gameId');
    if (stateStr == null) return null;
    return GameState.fromJson(
      jsonDecode(stateStr) as Map<String, dynamic>,
    );
  }

  Future<void> deleteGame(String gameId) async {
    final prefs = await _preferences;

    final records = await getGameRecords();
    records.removeWhere((r) => r.gameId == gameId);

    final indexJson = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_indexKey, indexJson);
    await prefs.remove('$_stateKeyPrefix$gameId');
  }

  /// Exports all saved local games as [ImportGameRequest]s for server upload.
  Future<List<ImportGameRequest>> exportAllForUpload() async {
    final prefs = await _preferences;
    final records = await getGameRecords();
    final result = <ImportGameRequest>[];

    for (final record in records) {
      final stateStr = prefs.getString('$_stateKeyPrefix${record.gameId}');
      if (stateStr == null) continue;
      result.add(
        ImportGameRequest(
          localGameId: record.gameId,
          stateJson: stateStr,
          completedAt: record.completedAt.toUtc().toIso8601String(),
        ),
      );
    }

    return result;
  }

  /// Removes specific games from local storage (after successful upload).
  Future<void> clearUploadedGames(List<String> localGameIds) async {
    final prefs = await _preferences;
    final records = await getGameRecords();

    final idsToRemove = localGameIds.toSet();
    records.removeWhere((r) => idsToRemove.contains(r.gameId));

    final indexJson = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_indexKey, indexJson);

    for (final id in localGameIds) {
      await prefs.remove('$_stateKeyPrefix$id');
    }
  }
}
