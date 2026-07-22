import 'package:flutter/foundation.dart';

import '../api/rest_client.dart';
import '../models/import_games.dart';
import 'local_game_history_service.dart';

class GameUploadService {
  final RestClient _restClient;
  final LocalGameHistoryService _historyService;

  GameUploadService({
    required RestClient restClient,
    required LocalGameHistoryService historyService,
  }) : _restClient = restClient,
       _historyService = historyService;

  /// Uploads all local games to the server, then clears successfully
  /// imported and duplicate games from local storage.
  /// Best-effort: catches errors silently so auth/login is never blocked.
  Future<void> uploadAllLocalGames() async {
    try {
      final games = await _historyService.exportAllForUpload();
      if (games.isEmpty) return;

      final response = await _restClient.importLocalGames(games);

      if (response.errors.isNotEmpty) {
        debugPrint('[GameUpload] Server rejected: ${response.errors}');
      }

      // Clear both successfully imported and duplicate games from local storage
      final idsToRemove = [
        ...response.imported.map((m) => m.localGameId),
        ...response.duplicates,
      ];
      if (idsToRemove.isNotEmpty) {
        await _historyService.clearUploadedGames(idsToRemove);
      }

      debugPrint(
        '[GameUpload] Complete: ${response.imported.length} imported, '
        '${response.duplicates.length} duplicates, '
        '${response.errors.length} errors',
      );
    } catch (e) {
      debugPrint('[GameUpload] Failed to upload local games: $e');
    }
  }

  /// Uploads a single game immediately. On failure, the game stays
  /// in local storage for later retry.
  ///
  /// Returns true when the server took the game — the caller uses that to
  /// refresh anything derived from server-side stats.
  Future<bool> uploadSingleGame({
    required String gameId,
    required String stateJson,
    required String completedAt,
  }) async {
    try {
      final request = ImportGameRequest(
        localGameId: gameId,
        stateJson: stateJson,
        completedAt: completedAt,
      );
      final response = await _restClient.importLocalGames([request]);

      // A rejected game comes back in `errors` with a 200, so this is the
      // only place the reason is visible.
      if (response.errors.isNotEmpty) {
        debugPrint('[GameUpload] Server rejected $gameId: ${response.errors}');
      }

      final idsToRemove = [
        ...response.imported.map((m) => m.localGameId),
        ...response.duplicates,
      ];
      if (idsToRemove.isNotEmpty) {
        await _historyService.clearUploadedGames(idsToRemove);
      }
      return response.imported.isNotEmpty;
    } catch (e) {
      debugPrint('[GameUpload] Failed to upload game $gameId: $e');
      return false;
    }
  }
}
