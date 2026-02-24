import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/game_state.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/auth_required.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../daily_puzzle/state/puzzle_provider.dart';
import '../../daily_puzzle/widgets/streak_badge.dart';
import '../../game/state/game_providers.dart';

final _isCreatingGameProvider = StateProvider<bool>((ref) => false);

// Active games provider — fetches from /api/games/me (only when logged in)
final _activeGamesProvider = FutureProvider.autoDispose<List<GameState>>((
  ref,
) async {
  final auth = ref.read(authProvider);
  if (!auth.isLoggedIn) return [];
  final restClient = ref.read(restClientProvider);
  return restClient.getMyActiveGames();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final auth = ref.watch(authProvider);
    final isCreating = ref.watch(_isCreatingGameProvider);
    final activeGames = ref.watch(_activeGamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cribbage Club'),
        actions: [
          if (auth.isLoggedIn && auth.isGuest)
            TextButton(
              onPressed: () => context.go('/upgrade'),
              child: Text(
                'Upgrade',
                style: TextStyle(color: colors.accent),
              ),
            ),
          if (auth.isLoggedIn && auth.username != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: GestureDetector(
                  onTap: auth.userId != null
                      ? () => context.push('/profile/${auth.userId}')
                      : null,
                  child: Text(
                    auth.username!,
                    style: TextStyle(color: colors.accent),
                  ),
                ),
              ),
            ),
          if (auth.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
          if (!auth.isLoggedIn)
            TextButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Log In'),
              style: TextButton.styleFrom(foregroundColor: colors.accent),
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: isCreating,
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.isTabletLandscape(context) ? 700 : 400,
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Guest upgrade banner
                    if (auth.isLoggedIn && auth.isGuest) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.accent),
                          color: colors.accent.withValues(alpha: 0.1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colors.accent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Create an account to save your progress and stats.',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => context.go('/upgrade'),
                              child: Text(
                                'Upgrade',
                                style: TextStyle(
                                  color: colors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Active games section (only when logged in)
                    if (auth.isLoggedIn)
                      activeGames.when(
                        data: (games) {
                          if (games.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Continue Game',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...games.map(
                                (game) => _ActiveGameTile(game: game),
                              ),
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

                    Icon(
                      Icons.style,
                      size: 100,
                      color: colors.accent,
                    ),
                    const SizedBox(height: 32),

                    // Main action buttons — 2x2 grid on tablet landscape, stacked on phone
                    if (Responsive.isTabletLandscape(context)) ...[
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: isCreating
                                    ? null
                                    : () => _showDifficultyPicker(context, ref),
                                icon: const Icon(Icons.smart_toy, size: 24),
                                label: const Text('Play vs AI', style: TextStyle(fontSize: 18)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: isCreating
                                    ? null
                                    : () => _showOnlineOptions(context, ref),
                                icon: const Icon(Icons.people, size: 24),
                                label: const Text('Play Online', style: TextStyle(fontSize: 18)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: () => context.go('/daily-puzzle'),
                                icon: const Icon(Icons.calendar_today, size: 24),
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Daily Challenge', style: TextStyle(fontSize: 18)),
                                    Consumer(
                                      builder: (context, ref, _) {
                                        final streak = ref.watch(dailyPuzzleProvider).streak;
                                        if (streak <= 0) return const SizedBox.shrink();
                                        return Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: StreakBadge(streak: streak, fontSize: 12),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colors.textPrimary,
                                  side: BorderSide(color: colors.warning, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: () => context.go('/practice-puzzle'),
                                icon: const Icon(Icons.all_inclusive, size: 24),
                                label: const Text('Practice Puzzles', style: TextStyle(fontSize: 18)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colors.textPrimary,
                                  side: BorderSide(color: colors.textDisabled),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: isCreating
                              ? null
                              : () => _showDifficultyPicker(context, ref),
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
                        child: ElevatedButton.icon(
                          onPressed: isCreating
                              ? null
                              : () => _showOnlineOptions(context, ref),
                          icon: const Icon(Icons.people, size: 24),
                          label: const Text(
                            'Play Online',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/daily-puzzle'),
                          icon: const Icon(Icons.calendar_today, size: 24),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Daily Challenge',
                                style: TextStyle(fontSize: 18),
                              ),
                              Consumer(
                                builder: (context, ref, _) {
                                  final streak = ref
                                      .watch(dailyPuzzleProvider)
                                      .streak;
                                  if (streak <= 0) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: StreakBadge(
                                      streak: streak,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.textPrimary,
                            side: BorderSide(
                              color: colors.warning,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/practice-puzzle'),
                          icon: const Icon(Icons.all_inclusive, size: 24),
                          label: const Text(
                            'Practice Puzzles',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.textPrimary,
                            side: BorderSide(color: colors.textDisabled),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (auth.isLoggedIn && !auth.isGuest)
                          Flexible(child: _FriendsButton()),
                        Flexible(
                          child: TextButton.icon(
                            onPressed: () => context.go('/history'),
                            icon: const Icon(Icons.history, size: 18),
                            label: const Text('History'),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.textSecondary,
                            ),
                          ),
                        ),
                        Flexible(
                          child: TextButton.icon(
                            onPressed: () => context.go('/leaderboard'),
                            icon: const Icon(Icons.leaderboard, size: 18),
                            label: const Text('Leaderboard'),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.textSecondary,
                            ),
                          ),
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

  void _showDifficultyPicker(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Choose Difficulty',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _DifficultyTile(
              label: 'Easy',
              description: 'Basic heuristics',
              icon: Icons.sentiment_satisfied,
              onTap: () {
                Navigator.pop(ctx);
                _createLocalAIGame(context, ref, 'basic');
              },
            ),
            _DifficultyTile(
              label: 'Medium',
              description: 'Optimizes hand scoring',
              icon: Icons.psychology,
              onTap: () {
                Navigator.pop(ctx);
                _createLocalAIGame(context, ref, 'medium');
              },
            ),
            _DifficultyTile(
              label: 'Hard',
              description: 'Hand + crib optimization, advanced pegging',
              icon: Icons.local_fire_department,
              onTap: () {
                Navigator.pop(ctx);
                _createLocalAIGame(context, ref, 'hard');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showOnlineOptions(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Play Online',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.flash_on, color: colors.accent),
              title: Text('Quick Game',
                  style: TextStyle(color: colors.textPrimary)),
              subtitle: Text('Find a match instantly',
                  style: TextStyle(color: colors.textTertiary, fontSize: 12)),
              trailing:
                  Icon(Icons.chevron_right, color: colors.textDisabled),
              onTap: () {
                Navigator.pop(ctx);
                _quickMatch(context, ref);
              },
            ),
            ListTile(
              leading: Icon(Icons.list, color: colors.accent),
              title: Text('Browse Lobbies',
                  style: TextStyle(color: colors.textPrimary)),
              subtitle: Text('Join an open lobby',
                  style: TextStyle(color: colors.textTertiary, fontSize: 12)),
              trailing:
                  Icon(Icons.chevron_right, color: colors.textDisabled),
              onTap: () {
                Navigator.pop(ctx);
                _browseLobbies(context, ref);
              },
            ),
            ListTile(
              leading: Icon(Icons.lock, color: colors.accent),
              title: Text('Create Private Game',
                  style: TextStyle(color: colors.textPrimary)),
              subtitle: Text('Invite a friend by code',
                  style: TextStyle(color: colors.textTertiary, fontSize: 12)),
              trailing:
                  Icon(Icons.chevron_right, color: colors.textDisabled),
              onTap: () {
                Navigator.pop(ctx);
                _createPrivateGame(context, ref);
              },
            ),
            ListTile(
              leading: Icon(Icons.vpn_key, color: colors.accent),
              title: Text('Join by Code',
                  style: TextStyle(color: colors.textPrimary)),
              subtitle: Text('Enter an invite code',
                  style: TextStyle(color: colors.textTertiary, fontSize: 12)),
              trailing:
                  Icon(Icons.chevron_right, color: colors.textDisabled),
              onTap: () {
                Navigator.pop(ctx);
                _showJoinByCodeDialog(context, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _createLocalAIGame(
    BuildContext context,
    WidgetRef ref,
    String difficulty,
  ) {
    final auth = ref.read(authProvider);
    final service = ref.read(localGameServiceProvider);
    final state = service.createGame(
      humanPlayerId: auth.userId ?? 'local_player',
      humanPlayerName: auth.username ?? 'Player',
      difficulty: difficulty,
    );
    if (context.mounted) {
      context.go('/game/${state.gameId}');
    }
  }

  Future<void> _quickMatch(BuildContext context, WidgetRef ref) async {
    final authed = await AuthRequired.ensureAuthenticated(context, ref);
    if (!authed || !context.mounted) return;

    ref.read(_isCreatingGameProvider.notifier).state = true;
    try {
      final restClient = ref.read(restClientProvider);
      final result = await restClient.quickMatch();
      if (context.mounted) {
        if (result.gameState != null) {
          context.go('/game/${result.gameState!.gameId}');
        } else {
          context.go('/lobby/${result.lobby.id}');
        }
      }
    } catch (e) {
      debugPrint('[Home] Quick match failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Quick match failed: $e')));
      }
    } finally {
      ref.read(_isCreatingGameProvider.notifier).state = false;
    }
  }

  Future<void> _browseLobbies(BuildContext context, WidgetRef ref) async {
    final authed = await AuthRequired.ensureAuthenticated(context, ref);
    if (!authed || !context.mounted) return;
    context.go('/lobbies');
  }

  Future<void> _createPrivateGame(BuildContext context, WidgetRef ref) async {
    final authed = await AuthRequired.ensureAuthenticated(context, ref);
    if (!authed || !context.mounted) return;

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
      debugPrint('[Home] Failed to create lobby: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create lobby: $e')));
      }
    } finally {
      ref.read(_isCreatingGameProvider.notifier).state = false;
    }
  }

  void _showJoinByCodeDialog(BuildContext context, WidgetRef ref) async {
    final authed = await AuthRequired.ensureAuthenticated(context, ref);
    if (!authed || !context.mounted) return;

    final colors = context.appColors;
    final codeController = TextEditingController();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surfacePrimary,
        title: Text(
          'Join by Code',
          style: TextStyle(color: colors.textPrimary),
        ),
        content: TextField(
          controller: codeController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Enter invite code',
            hintStyle: TextStyle(color: colors.textDisabled),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: colors.surfaceDim,
          ),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            letterSpacing: 4,
          ),
          textAlign: TextAlign.center,
          onSubmitted: (_) =>
              _joinByCode(dialogContext, context, ref, codeController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                _joinByCode(dialogContext, context, ref, codeController),
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
      debugPrint('[Home] Failed to join by code: $e');
      if (homeContext.mounted) {
        ScaffoldMessenger.of(
          homeContext,
        ).showSnackBar(SnackBar(content: Text('Failed to join: $e')));
      }
    } finally {
      ref.read(_isCreatingGameProvider.notifier).state = false;
    }
  }
}

class _DifficultyTile extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _DifficultyTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListTile(
      leading: Icon(icon, color: colors.accent),
      title: Text(label, style: TextStyle(color: colors.textPrimary)),
      subtitle: Text(
        description,
        style: TextStyle(color: colors.textTertiary, fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: colors.textDisabled),
      onTap: onTap,
    );
  }
}

class _FriendsButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final notifCount = ref.watch(notificationCountProvider);
    final total = notifCount.whenOrNull(data: (n) => n.total) ?? 0;

    return TextButton.icon(
      onPressed: () => context.go('/friends'),
      icon: Badge(
        isLabelVisible: total > 0,
        label: Text('$total', style: const TextStyle(fontSize: 10)),
        backgroundColor: colors.error,
        child: const Icon(Icons.people, size: 18),
      ),
      label: const Text('Friends'),
      style: TextButton.styleFrom(foregroundColor: colors.textSecondary),
    );
  }
}

class _ActiveGameTile extends ConsumerWidget {
  final GameState game;

  const _ActiveGameTile({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final auth = ref.watch(authProvider);
    final playerId = auth.userId ?? '';
    final playerIndex = game.players.indexWhere((p) => p.id == playerId);
    final player = playerIndex >= 0
        ? game.players[playerIndex]
        : game.players[0];
    final opponent = game.players[playerIndex >= 0 ? 1 - playerIndex : 1];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surfaceDim,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go('/game/${game.gameId}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.play_arrow,
                  color: colors.accent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'vs ${opponent.name}',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${game.stage.displayName} — ${player.score} to ${opponent.score}',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
