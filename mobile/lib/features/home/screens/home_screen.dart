import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/local_game_record.dart';
import '../../../shared/widgets/auth_required.dart';
import '../../../shared/widgets/cc_bottom_nav.dart';
import '../../../shared/widgets/cc_buttons.dart';
import '../../../shared/widgets/cc_dialog.dart';
import '../../../shared/widgets/cc_list.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../daily_puzzle/state/puzzle_provider.dart';
import '../../game/widgets/game_settings_sheet.dart';
import '../../profile/state/my_profile_provider.dart';
import '../../../core/services/local_game_history_provider.dart';
import '../../../core/services/local_game_history_service.dart';
import '../../game/state/game_providers.dart';

final _isCreatingGameProvider = StateProvider<bool>((ref) => false);

// Active games provider — fetches from /api/games/me (only when logged in).
// Kept alive so returning to the Play tab doesn't re-load and shift layout.
final _activeGamesProvider = FutureProvider<List<GameState>>((
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
    final auth = ref.watch(authProvider);
    final isCreating = ref.watch(_isCreatingGameProvider);
    final activeGames = ref.watch(_activeGamesProvider);
    final activeLocalGame = ref.watch(activeLocalGameProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LoadingOverlay(
          isLoading: isCreating,
          child: Column(
            children: [
              _Header(auth: auth),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Guest upgrade banner
                            if (auth.isLoggedIn && auth.isGuest) ...[
                              _GuestBanner(),
                              const SizedBox(height: 14),
                            ],

                            // Active games (online + local in-progress)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              alignment: Alignment.topCenter,
                              child: _ContinueGameSection(
                                activeGames: activeGames,
                                activeLocalGame: activeLocalGame,
                                isLoggedIn: auth.isLoggedIn,
                              ),
                            ),

                            CcPrimaryButton(
                              label: 'Play · Rated',
                              onPressed: isCreating
                                  ? null
                                  : () => _quickMatch(context, ref),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: CcSecondaryButton(
                                    label: 'Play a friend',
                                    onPressed: isCreating
                                        ? null
                                        : () => _showOnlineOptions(context, ref),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: CcSecondaryButton(
                                    label: 'Play the engine',
                                    onPressed: isCreating
                                        ? null
                                        : () =>
                                            _showDifficultyPicker(context, ref),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const _PuzzleGroup(),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: CcSecondaryButton(
                                    label: 'Game history',
                                    icon: Icons.history,
                                    height: 40,
                                    fontSize: 13,
                                    onPressed: () => context.go('/history'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: CcSecondaryButton(
                                    label: 'Game settings',
                                    icon: Icons.tune,
                                    height: 40,
                                    fontSize: 13,
                                    onPressed: () =>
                                        showGameSettingsDialog(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const _RecentGamesSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CcBottomNav(active: CcTab.play),
    );
  }

  void _showDifficultyPicker(BuildContext context, WidgetRef ref) {
    showCcDialog(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: 'Choose difficulty',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CcOptionRow(
              icon: Icons.sentiment_satisfied,
              title: 'Easy',
              subtitle: 'Basic heuristics',
              showChevron: false,
              onTap: () {
                Navigator.pop(dialogContext);
                _createLocalAIGame(context, ref, 'basic');
              },
            ),
            const SizedBox(height: 8),
            CcOptionRow(
              icon: Icons.psychology,
              title: 'Medium',
              subtitle: 'Optimizes hand scoring',
              showChevron: false,
              onTap: () {
                Navigator.pop(dialogContext);
                _createLocalAIGame(context, ref, 'medium');
              },
            ),
            const SizedBox(height: 8),
            CcOptionRow(
              icon: Icons.local_fire_department,
              title: 'Hard',
              subtitle: 'Hand + crib optimization, advanced pegging',
              showChevron: false,
              onTap: () {
                Navigator.pop(dialogContext);
                _createLocalAIGame(context, ref, 'hard');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOnlineOptions(BuildContext context, WidgetRef ref) {
    showCcDialog(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: 'Play online',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CcOptionRow(
              icon: Icons.flash_on,
              title: 'Quick game',
              subtitle: 'Find a match instantly',
              onTap: () {
                Navigator.pop(dialogContext);
                _quickMatch(context, ref);
              },
            ),
            const SizedBox(height: 8),
            CcOptionRow(
              icon: Icons.list,
              title: 'Browse lobbies',
              subtitle: 'Join an open lobby',
              onTap: () {
                Navigator.pop(dialogContext);
                _browseLobbies(context, ref);
              },
            ),
            const SizedBox(height: 8),
            CcOptionRow(
              icon: Icons.lock,
              title: 'Create private game',
              subtitle: 'Invite a friend by code',
              onTap: () {
                Navigator.pop(dialogContext);
                _createPrivateGame(context, ref);
              },
            ),
            const SizedBox(height: 8),
            CcOptionRow(
              icon: Icons.vpn_key,
              title: 'Join by code',
              subtitle: 'Enter an invite code',
              onTap: () {
                Navigator.pop(dialogContext);
                _showJoinByCodeDialog(context, ref);
              },
            ),
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
    ref.invalidate(activeLocalGameProvider);
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

    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color, width: width),
        );

    showCcDialog(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: 'Join by code',
        actions: [
          CcSecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          CcPrimaryButton(
            label: 'Join',
            height: 44,
            fontSize: 14,
            onPressed: () =>
                _joinByCode(dialogContext, context, ref, codeController),
          ),
        ],
        child: TextField(
          controller: codeController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'INVITE CODE',
            hintStyle: TextStyle(
              color: colors.textDisabled,
              fontSize: 15,
              letterSpacing: 2,
            ),
            filled: true,
            fillColor: colors.surfaceDim,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: border(colors.borderStrong),
            focusedBorder: border(colors.selectedBorder, width: 2),
          ),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          textAlign: TextAlign.center,
          onSubmitted: (_) =>
              _joinByCode(dialogContext, context, ref, codeController),
        ),
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

/// App header: logo mark, wordmark, rating/identity chip (comp 3a).
class _Header extends ConsumerWidget {
  final AuthState auth;

  const _Header({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final rating = ref.watch(myProfileProvider).valueOrNull?.rating;

    final Widget chip;
    if (rating != null) {
      chip = _HeaderChip(
        label: '${rating.round()}',
        labelColor: colors.ratingGold,
        onTap: () => context.go('/me'),
      );
    } else if (auth.isLoggedIn && auth.username != null) {
      chip = _HeaderChip(
        label: auth.username!,
        labelColor: colors.textPrimary,
        onTap: () => context.go('/me'),
      );
    } else {
      chip = _HeaderChip(
        label: 'Sign in',
        labelColor: colors.accent,
        onTap: () => context.go('/login'),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.accent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                'CC',
                style: TextStyle(
                  color: colors.accentOnSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cribbage Club',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          chip,
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final Color labelColor;
  final VoidCallback? onTap;

  const _HeaderChip({
    required this.label,
    required this.labelColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surfaceChrome,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: labelColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GuestBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.accentBorder),
        color: colors.accentSubtle,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "You're playing as a guest. Create an account to keep your rating and history.",
              style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/upgrade'),
            child: Text(
              'Upgrade',
              style: TextStyle(
                color: colors.accent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Caption label — 12/600, +0.06em, uppercase (design language "caption").
class _Caption extends StatelessWidget {
  final String text;

  const _Caption(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.7,
      ),
    );
  }
}

/// Grouped puzzle card (comp 3a): today's puzzle row over the practice row,
/// one bordered container with a hairline divider.
class _PuzzleGroup extends StatelessWidget {
  const _PuzzleGroup();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            const _DailyPuzzleRow(),
            Divider(height: 1, color: colors.border),
            const _PracticePuzzleRow(),
          ],
        ),
      ),
    );
  }
}

class _DailyPuzzleRow extends ConsumerWidget {
  const _DailyPuzzleRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final status = ref.watch(dailyPuzzleStatusProvider);
    final completedToday = status.valueOrNull?.completedToday ?? false;
    final completedCount = status.valueOrNull?.completedCount ?? 0;
    final streak = status.valueOrNull?.streak ?? 0;

    final subtitle = [
      if (completedToday)
        'Solved today'
      else if (completedCount > 0)
        '$completedCount/5 solved'
      else
        '5 puzzles',
      if (streak > 0) 'streak $streak day${streak == 1 ? '' : 's'}',
    ].join(' · ');

    return InkWell(
      onTap: () => context.go('/daily-puzzle'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _MysteryCard(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's puzzle: pick the discard",
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              completedToday ? 'Done' : 'Solve',
              style: TextStyle(
                color: completedToday ? colors.textTertiary : colors.accent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small face-down "?" card used on the daily puzzle card.
class _MysteryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 40,
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.cardFace,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Text(
            '?',
            style: TextStyle(
              color: colors.suitRed,
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '♥',
              style: TextStyle(color: colors.suitRed, fontSize: 15, height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticePuzzleRow extends StatelessWidget {
  const _PracticePuzzleRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surfaceChrome,
      child: InkWell(
        onTap: () => context.go('/practice-puzzle'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Puzzle practice',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Discards · pegging traps · counting drills',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Open',
                style: TextStyle(
                  color: colors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentGamesSection extends ConsumerWidget {
  const _RecentGamesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final records =
        ref.watch(localGameHistoryProvider).valueOrNull ?? const [];
    final recent = records.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              const _Caption('Recent games'),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/history'),
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: recent.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No games yet. Your first game starts your record.',
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 12.5,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < recent.length; i++) ...[
                      if (i > 0)
                        Divider(height: 1, color: colors.border),
                      _RecentGameRow(record: recent[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _RecentGameRow extends StatelessWidget {
  final LocalGameRecord record;

  const _RecentGameRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final resultColor = record.isWin ? colors.success : colors.error;

    return InkWell(
      onTap: () => context.go('/replay/${record.gameId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: Text(
                  record.isWin ? 'W' : 'L',
                  style: TextStyle(
                    color: resultColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                record.opponentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${record.playerScore}–${record.opponentScore}',
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 13.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueGameSection extends StatelessWidget {
  final AsyncValue<List<GameState>> activeGames;
  final AsyncValue<ActiveLocalGame?> activeLocalGame;
  final bool isLoggedIn;

  const _ContinueGameSection({
    required this.activeGames,
    required this.activeLocalGame,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    final onlineGames = isLoggedIn
        ? (activeGames.valueOrNull ?? <GameState>[])
        : <GameState>[];
    final localGame = activeLocalGame.valueOrNull;

    if (onlineGames.isEmpty && localGame == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: _Caption('In progress'),
        ),
        const SizedBox(height: 8),
        if (localGame != null)
          _ActiveGameTile(game: localGame.gameState),
        ...onlineGames.map((game) => _ActiveGameTile(game: game)),
        const SizedBox(height: 14),
      ],
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
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go('/game/${game.gameId}'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  color: colors.accent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'vs ${opponent.name}',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${game.stage.displayName} · ${player.score}–${opponent.score}',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 12,
                          fontFeatures: const [FontFeature.tabularFigures()],
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
