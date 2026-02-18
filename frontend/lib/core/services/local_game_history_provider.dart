import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../models/local_game_record.dart';
import 'local_game_history_service.dart';

final localGameHistoryServiceProvider = Provider<LocalGameHistoryService>((ref) {
  return LocalGameHistoryService();
});

final localGameHistoryProvider =
    FutureProvider.autoDispose<List<LocalGameRecord>>((ref) async {
  final service = ref.read(localGameHistoryServiceProvider);
  return service.getGameRecords();
});

final persistedGameStateProvider =
    FutureProvider.family<GameState?, String>((ref, gameId) async {
  final service = ref.read(localGameHistoryServiceProvider);
  return service.getGameState(gameId);
});
