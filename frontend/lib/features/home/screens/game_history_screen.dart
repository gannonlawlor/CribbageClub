import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/game_state.dart';

final _gameHistoryProvider = FutureProvider.autoDispose<List<GameState>>((ref) async {
  final restClient = ref.read(restClientProvider);
  return restClient.getMyGameHistory();
});

class GameHistoryScreen extends ConsumerWidget {
  const GameHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(_gameHistoryProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Game History')),
      body: history.when(
        data: (games) {
          if (games.isEmpty) {
            return const Center(
              child: Text(
                'No completed games yet',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              final playerId = auth.userId ?? '';
              final playerIndex = game.players.indexWhere((p) => p.id == playerId);
              final player = playerIndex >= 0 ? game.players[playerIndex] : game.players[0];
              final opponent = game.players[playerIndex >= 0 ? 1 - playerIndex : 1];
              final isWinner = player.score > opponent.score;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.go('/game/${game.gameId}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            isWinner ? Icons.emoji_events : Icons.close,
                            color: isWinner ? AppTheme.goldAccent : Colors.redAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'vs ${opponent.name}',
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                Text(
                                  '${player.score} - ${opponent.score}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            isWinner ? 'Won' : 'Lost',
                            style: TextStyle(
                              color: isWinner ? AppTheme.goldAccent : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Failed to load history: $error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}
