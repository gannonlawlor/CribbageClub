import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../models/game_state.dart';
import '../models/local_game_record.dart';
import 'game_upload_service.dart';
import 'local_game_history_service.dart';

final localGameHistoryServiceProvider = Provider<LocalGameHistoryService>((ref) {
  return LocalGameHistoryService();
});

// Kept alive (not autoDispose) so tab switches render cached data instantly
// instead of re-loading and shifting the layout. Invalidated after games
// complete and when leaving a game.
final localGameHistoryProvider =
    FutureProvider<List<LocalGameRecord>>((ref) async {
  final service = ref.read(localGameHistoryServiceProvider);
  return service.getGameRecords();
});

final persistedGameStateProvider =
    FutureProvider.family<GameState?, String>((ref, gameId) async {
  final service = ref.read(localGameHistoryServiceProvider);
  return service.getGameState(gameId);
});

final activeLocalGameProvider = FutureProvider<ActiveLocalGame?>((ref) async {
  final service = ref.read(localGameHistoryServiceProvider);
  return service.getActiveGame();
});

final gameUploadServiceProvider = Provider<GameUploadService>((ref) {
  return GameUploadService(
    restClient: ref.read(restClientProvider),
    historyService: ref.read(localGameHistoryServiceProvider),
  );
});
