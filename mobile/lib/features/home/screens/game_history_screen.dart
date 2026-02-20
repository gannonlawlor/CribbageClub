import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/local_game_record.dart';
import '../../../core/services/local_game_history_provider.dart';

final _serverGameHistoryProvider = FutureProvider.autoDispose<List<GameState>>((
  ref,
) async {
  final auth = ref.read(authProvider);
  if (!auth.isLoggedIn) return [];
  final restClient = ref.read(restClientProvider);
  return restClient.getMyGameHistory();
});

class GameHistoryScreen extends ConsumerWidget {
  const GameHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final localHistory = ref.watch(localGameHistoryProvider);

    // When logged in, show unified server history with optional pending-upload section
    if (auth.isLoggedIn) {
      final serverHistory = ref.watch(_serverGameHistoryProvider);

      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          title: const Text('Game History'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Pending upload section (local games that haven't been uploaded yet)
            localHistory.when(
              data: (records) {
                if (records.isEmpty) return const SizedBox.shrink();
                return _PendingUploadSection(records: records);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Server game history (unified list)
            serverHistory.when(
              data: (games) {
                if (games.isEmpty) {
                  return const _SectionEmpty(
                    message: 'No games yet. Play vs AI or online to get started!',
                  );
                }
                return _ServerGamesSection(
                  games: games,
                  playerId: auth.userId ?? '',
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _SectionEmpty(
                message: 'Failed to load game history: $error',
              ),
            ),
          ],
        ),
      );
    }

    // Not logged in: show local games only
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Game History'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          localHistory.when(
            data: (records) {
              if (records.isEmpty) {
                return const _SectionEmpty(
                  message: 'No local games yet. Play vs AI to get started!',
                );
              }
              return _LocalGamesSection(records: records);
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => _SectionEmpty(
              message: 'Failed to load local history: $error',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  final String message;

  const _SectionEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _PendingUploadSection extends StatelessWidget {
  final List<LocalGameRecord> records;

  const _PendingUploadSection({required this.records});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cloud_upload, color: Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(
              'Pending Upload (${records.length})',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final record in records)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _LocalGameRow(record: record),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _LocalGamesSection extends StatelessWidget {
  final List<LocalGameRecord> records;

  const _LocalGamesSection({required this.records});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Local Games'),
        const SizedBox(height: 8),
        for (final record in records)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LocalGameRow(record: record),
          ),
      ],
    );
  }
}

class _LocalGameRow extends StatelessWidget {
  final LocalGameRecord record;

  const _LocalGameRow({required this.record});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              record.isWin ? Icons.emoji_events : Icons.close,
              color: record.isWin ? AppTheme.goldAccent : Colors.redAccent,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'vs AI (${record.difficulty})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${record.playerScore} - ${record.opponentScore}  ·  ${_formatDate(record.completedAt)}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.analytics,
                size: 20,
                color: Colors.white38,
              ),
              tooltip: 'Analyze',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: () => context.go('/analysis/${record.gameId}'),
            ),
            IconButton(
              icon: const Icon(
                Icons.replay,
                size: 20,
                color: Colors.white38,
              ),
              tooltip: 'Replay',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: () => context.go('/replay/${record.gameId}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerGamesSection extends StatelessWidget {
  final List<GameState> games;
  final String playerId;

  const _ServerGamesSection({required this.games, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final game in games)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ServerGameRow(game: game, playerId: playerId),
          ),
      ],
    );
  }
}

class _ServerGameRow extends StatelessWidget {
  final GameState game;
  final String playerId;

  const _ServerGameRow({required this.game, required this.playerId});

  @override
  Widget build(BuildContext context) {
    final playerIndex = game.players.indexWhere((p) => p.id == playerId);
    final player = playerIndex >= 0 ? game.players[playerIndex] : game.players[0];
    final opponent = game.players[playerIndex >= 0 ? 1 - playerIndex : 1];
    final isWinner = player.score > opponent.score;

    return Material(
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${player.score} - ${opponent.score}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
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
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.analytics,
                  size: 20,
                  color: Colors.white38,
                ),
                tooltip: 'Analyze',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => context.go('/analysis/${game.gameId}'),
              ),
              IconButton(
                icon: const Icon(
                  Icons.replay,
                  size: 20,
                  color: Colors.white38,
                ),
                tooltip: 'Replay',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => context.go('/replay/${game.gameId}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
