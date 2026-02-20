import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/leaderboard_entry.dart';

final _leaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>(
  (ref) async {
    final restClient = ref.read(restClientProvider);
    return restClient.getLeaderboard();
  },
);

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final leaderboard = ref.watch(_leaderboardProvider);
    final auth = ref.watch(authProvider);

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          title: const Text('Leaderboard'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 48, color: colors.textDisabled),
              const SizedBox(height: 16),
              Text(
                'Log in to see the leaderboard',
                style: TextStyle(color: colors.textTertiary, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Leaderboard'),
      ),
      body: leaderboard.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Text(
                'No players yet',
                style: TextStyle(color: colors.textTertiary, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isCurrentUser = entry.playerId == auth.userId;
              final rank = index + 1;

              return GestureDetector(
                onTap: () => context.push('/profile/${entry.playerId}'),
                child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? colors.accent.withValues(alpha: 0.15)
                      : colors.surfaceDim,
                  borderRadius: BorderRadius.circular(8),
                  border: isCurrentUser
                      ? Border.all(
                          color: colors.accent.withValues(alpha: 0.5),
                        )
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            color: rank <= 3
                                ? colors.accent
                                : colors.textTertiary,
                            fontWeight: rank <= 3
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.displayName,
                              style: TextStyle(
                                color: isCurrentUser
                                    ? colors.accent
                                    : colors.textPrimary,
                                fontSize: 14,
                                fontWeight: isCurrentUser
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            Text(
                              '${entry.gamesPlayed} games played',
                              style: TextStyle(
                                color: colors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${entry.rating.round()}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${(entry.winRate * 100).toStringAsFixed(0)}% win',
                            style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
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
            'Failed to load leaderboard: $error',
            style: TextStyle(color: colors.error),
          ),
        ),
      ),
    );
  }
}
