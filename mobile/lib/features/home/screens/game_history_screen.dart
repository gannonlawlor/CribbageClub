import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/game_state.dart';
import '../../../core/services/local_game_history_provider.dart';
import '../../../shared/widgets/cc_screen.dart';
import '../../../shared/widgets/game_history_row.dart';
import '../../../shared/widgets/cc_swipe_back.dart';

class GameHistoryScreen extends ConsumerWidget {
  const GameHistoryScreen({super.key});

  Future<void> _refresh(WidgetRef ref, bool isLoggedIn) async {
    ref.invalidate(localGameHistoryProvider);
    if (isLoggedIn) {
      ref.invalidate(serverGameHistoryProvider);
      await ref.read(serverGameHistoryProvider.future);
    } else {
      await ref.read(localGameHistoryProvider.future);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final auth = ref.watch(authProvider);
    final localHistory = ref.watch(localGameHistoryProvider);
    final serverHistory = auth.isLoggedIn
        ? ref.watch(serverGameHistoryProvider)
        : const AsyncValue<List<GameState>>.data([]);

    final local = localHistory.valueOrNull ?? const [];
    final server = serverHistory.valueOrNull ?? const [];
    final loading = localHistory.isLoading || serverHistory.isLoading;
    final total = local.length + server.length;

    // On-device games that haven't reached the server yet get their own
    // section — they're the ones a signed-in player might wonder about.
    final pending = auth.isLoggedIn
        ? [
            for (final r in local)
              GameSummary.fromLocal(r, subtitle: 'Engine · not uploaded'),
          ]
        : const <GameSummary>[];
    final played = [
      for (final g in server) GameSummary.fromGameState(g, auth.userId ?? ''),
      if (!auth.isLoggedIn)
        for (final r in local) GameSummary.fromLocal(r),
    ];

    return CcSwipeBack(
      onBack: () => context.go('/'),
      child: Scaffold(
        backgroundColor: colors.scaffoldBg,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  CcScreenHeader(
                    title: 'Game history',
                    subtitle: loading
                        ? null
                        : '$total game${total == 1 ? '' : 's'}',
                    onBack: () => context.go('/'),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: colors.accent,
                      onRefresh: () => _refresh(ref, auth.isLoggedIn),
                      child: loading && total == 0
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                              children: [
                                if (pending.isNotEmpty) ...[
                                  const CcSectionCaption('Waiting to upload'),
                                  GameHistoryList(games: pending),
                                  const SizedBox(height: 20),
                                ],
                                const CcSectionCaption('Played'),
                                GameHistoryList(
                                  games: played,
                                  emptyMessage: auth.isLoggedIn
                                      ? 'No games yet. Your first rated game sets your rating.'
                                      : 'No games yet. Play the engine to get started.',
                                ),
                                if (serverHistory.hasError) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Your online games could not be loaded.',
                                    style: TextStyle(
                                      color: colors.textTertiary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
