import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/game_state.dart';
import '../../../shared/widgets/loading_overlay.dart';

final _isCreatingGameProvider = StateProvider<bool>((ref) => false);

// Active games provider — fetches from /api/games/me
final _activeGamesProvider = FutureProvider.autoDispose<List<GameState>>((ref) async {
  final restClient = ref.read(restClientProvider);
  return restClient.getMyActiveGames();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isCreating = ref.watch(_isCreatingGameProvider);
    final activeGames = ref.watch(_activeGamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cribbage Club'),
        actions: [
          if (auth.username != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  auth.username!,
                  style: const TextStyle(color: AppTheme.goldAccent),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: isCreating,
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Guest upgrade banner
                    if (auth.isGuest) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.goldAccent),
                          color: AppTheme.goldAccent.withValues(alpha: 0.1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppTheme.goldAccent),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Create an account to save your progress and stats.',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => context.go('/upgrade'),
                              child: const Text(
                                'Upgrade',
                                style: TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Active games section
                    activeGames.when(
                      data: (games) {
                        if (games.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Continue Game',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...games.map((game) => _ActiveGameTile(game: game)),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    const Icon(
                      Icons.style,
                      size: 100,
                      color: AppTheme.goldAccent,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isCreating
                            ? null
                            : () => _createAIGame(context, ref),
                        icon: const Icon(Icons.smart_toy, size: 24),
                        label: const Text(
                          'Play vs AI',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: isCreating
                            ? null
                            : () => _createPrivateGame(context, ref),
                        icon: const Icon(Icons.lock, size: 24),
                        label: const Text(
                          'Create Private Game',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: isCreating
                            ? null
                            : () => _showJoinByCodeDialog(context, ref),
                        icon: const Icon(Icons.vpn_key, size: 24),
                        label: const Text(
                          'Join by Code',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => context.go('/history'),
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('History'),
                          style: TextButton.styleFrom(foregroundColor: Colors.white70),
                        ),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          onPressed: () => context.go('/leaderboard'),
                          icon: const Icon(Icons.leaderboard, size: 18),
                          label: const Text('Leaderboard'),
                          style: TextButton.styleFrom(foregroundColor: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createAIGame(BuildContext context, WidgetRef ref) async {
    ref.read(_isCreatingGameProvider.notifier).state = true;
    try {
      final restClient = ref.read(restClientProvider);
      final gameState = await restClient.createAIGame();
      if (context.mounted) {
        context.go('/game/${gameState.gameId}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create game: $e')),
        );
      }
    } finally {
      ref.read(_isCreatingGameProvider.notifier).state = false;
    }
  }

  Future<void> _createPrivateGame(BuildContext context, WidgetRef ref) async {
    ref.read(_isCreatingGameProvider.notifier).state = true;
    try {
      final auth = ref.read(authProvider);
      final restClient = ref.read(restClientProvider);
      final lobby = await restClient.createLobby(
        '${auth.username}\'s game',
        isPrivate: true,
      );
      if (context.mounted) {
        context.go('/lobby/${lobby.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create lobby: $e')),
        );
      }
    } finally {
      ref.read(_isCreatingGameProvider.notifier).state = false;
    }
  }

  void _showJoinByCodeDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.feltGreenDark,
        title: const Text('Join by Code', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: codeController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Enter invite code',
            hintStyle: TextStyle(color: Colors.white38),
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white10,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 4,
          ),
          textAlign: TextAlign.center,
          onSubmitted: (_) => _joinByCode(dialogContext, context, ref, codeController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _joinByCode(dialogContext, context, ref, codeController),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinByCode(
    BuildContext dialogContext,
    BuildContext homeContext,
    WidgetRef ref,
    TextEditingController controller,
  ) async {
    final code = controller.text.trim();
    if (code.isEmpty) return;
    Navigator.of(dialogContext).pop();
    ref.read(_isCreatingGameProvider.notifier).state = true;
    try {
      final restClient = ref.read(restClientProvider);
      final result = await restClient.joinByCode(code);
      if (homeContext.mounted) {
        if (result.gameState != null) {
          homeContext.go('/game/${result.gameState!.gameId}');
        } else {
          homeContext.go('/lobby/${result.lobby.id}');
        }
      }
    } catch (e) {
      if (homeContext.mounted) {
        ScaffoldMessenger.of(homeContext).showSnackBar(
          SnackBar(content: Text('Failed to join: $e')),
        );
      }
    } finally {
      ref.read(_isCreatingGameProvider.notifier).state = false;
    }
  }
}

class _ActiveGameTile extends ConsumerWidget {
  final GameState game;

  const _ActiveGameTile({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final playerId = auth.userId ?? '';
    final playerIndex = game.players.indexWhere((p) => p.id == playerId);
    final player = playerIndex >= 0 ? game.players[playerIndex] : game.players[0];
    final opponent = game.players[playerIndex >= 0 ? 1 - playerIndex : 1];

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
                const Icon(Icons.play_arrow, color: AppTheme.goldAccent, size: 20),
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
                        '${game.stage.displayName} — ${player.score} to ${opponent.score}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
