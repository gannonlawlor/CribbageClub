import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/game_state.dart';
import '../../../shared/widgets/auth_required.dart';
import '../../../shared/widgets/cc_bottom_nav.dart';
import '../../../shared/widgets/cc_buttons.dart';
import '../../../shared/widgets/cc_dialog.dart';
import '../../../shared/widgets/cc_list.dart';
import '../../../shared/widgets/game_history_row.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../daily_puzzle/state/puzzle_provider.dart';
import '../../profile/state/my_profile_provider.dart';
import '../../../core/services/local_game_history_provider.dart';
import '../../../core/services/local_game_history_service.dart';
import '../../game/state/game_providers.dart';
import '../../game/widgets/card_widget.dart';

final _isCreatingGameProvider = StateProvider<bool>((ref) => false);

/// Engine strengths, in the order the segmented control offers them.
const _difficulties = [
  ('basic', 'Easy'),
  ('medium', 'Medium'),
  ('hard', 'Hard'),
];

/// The strength you last played, so the segment you usually pick is already
/// lit and starting that game again is one tap.
final _botDifficultyProvider =
    StateNotifierProvider<_BotDifficultyNotifier, String>(
      (ref) => _BotDifficultyNotifier(),
    );

class _BotDifficultyNotifier extends StateNotifier<String> {
  static const _key = 'bot_difficulty';

  _BotDifficultyNotifier() : super('medium') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null && mounted) state = stored;
  }

  Future<void> set(String value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }
}

// Active games provider — fetches from /api/games/me (only when logged in).
// Kept alive so returning to the Play tab doesn't re-load and shift layout.
final _activeGamesProvider = FutureProvider<List<GameState>>((ref) async {
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
                          spacing: 12,
                          children: [
                            if (auth.isLoggedIn && auth.isGuest) _GuestBanner(),

                            // In-progress games resume straight from the top.
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              alignment: Alignment.topCenter,
                              child: _ResumeSection(
                                activeGames: activeGames,
                                activeLocalGame: activeLocalGame,
                                isLoggedIn: auth.isLoggedIn,
                              ),
                            ),

                            _OnlineCard(
                              onPlay: isCreating
                                  ? null
                                  : () => _quickMatch(context, ref),
                            ),

                            _BotCard(
                              // The chip taps persist the level themselves;
                              // Play just starts a game at whatever's picked.
                              onPlay: isCreating
                                  ? null
                                  : (difficulty) => _createLocalAIGame(
                                      context,
                                      ref,
                                      difficulty,
                                    ),
                            ),

                            _FriendCard(
                              onTap: isCreating
                                  ? null
                                  : () => _showFriendOptions(context, ref),
                            ),

                            Row(
                              spacing: 10,
                              children: const [
                                Expanded(child: _DailyPuzzleCard()),
                                Expanded(child: _PuzzleModeCard()),
                              ],
                            ),

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

  void _showFriendOptions(BuildContext context, WidgetRef ref) {
    showCcDialog(
      context: context,
      builder: (dialogContext) => CcDialog(
        title: 'Play a friend',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CcOptionRow(
              icon: Icons.lock_outline,
              title: 'Private game',
              subtitle: 'Invite with a code',
              onTap: () {
                Navigator.pop(dialogContext);
                _createPrivateGame(context, ref);
              },
            ),
            const SizedBox(height: 8),
            CcOptionRow(
              icon: Icons.vpn_key_outlined,
              title: 'Join by code',
              subtitle: 'Enter a code you were sent',
              onTap: () {
                Navigator.pop(dialogContext);
                _showJoinByCodeDialog(context, ref);
              },
            ),
            const SizedBox(height: 8),
            CcOptionRow(
              icon: Icons.people_outline,
              title: 'Challenge a club member',
              subtitle: 'Pick someone from your friends',
              onTap: () {
                Navigator.pop(dialogContext);
                context.push('/friends');
              },
            ),
            const SizedBox(height: 8),
            CcOptionRow(
              icon: Icons.list,
              title: 'Browse lobbies',
              subtitle: 'Join a table someone left open',
              onTap: () {
                Navigator.pop(dialogContext);
                _browseLobbies(context, ref);
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
      context.push('/game/${state.gameId}');
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
          context.push('/game/${result.gameState!.gameId}');
        } else {
          context.push('/lobby/${result.lobby.id}');
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
    context.push('/lobbies');
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
        context.push('/lobby/${lobby.id}');
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
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
          homeContext.push('/game/${result.gameState!.gameId}');
        } else {
          homeContext.push('/lobby/${result.lobby.id}');
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

/// App header: peg mark, wordmark, rating pill.
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
          const _PegMark(),
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

/// The app mark: a green peg standing in its hole.
class _PegMark extends StatelessWidget {
  const _PegMark();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.boardPrimary, colors.boardSecondary],
        ),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: colors.borderStrong),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colors.accent,
              shape: BoxShape.circle,
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -1),
            child: Container(
              width: 4,
              height: 8,
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(2),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -2.5),
            child: Container(
              width: 11,
              height: 3,
              decoration: BoxDecoration(
                color: colors.boardHole,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
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
            onPressed: () => context.push('/upgrade'),
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

/// Caption label — 11/600 uppercase (design language "caption").
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
        letterSpacing: 0.66,
      ),
    );
  }
}

/// Card shell shared by the bot, friend and puzzle blocks: surface-2 panel,
/// hairline border, r10.
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  const _Card({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 12),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(10);
    return Material(
      color: color ?? colors.surfacePrimary,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 40px rounded tile that holds the small drawn marks on the play cards.
class _IconTile extends StatelessWidget {
  final Widget child;

  const _IconTile({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.surfaceDim,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _OnlineCard extends StatelessWidget {
  final VoidCallback? onPlay;

  const _OnlineCard({required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _Card(
      onTap: onPlay,
      child: Row(
        children: [
          _IconTile(
            child: SizedBox(
              width: 18,
              height: 18,
              // A drawn globe: equator and meridian inside the ring, with the
              // ring painted last so it caps their ends cleanly.
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(width: 18, height: 1.5, color: colors.textTertiary),
                  Container(
                    width: 9,
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(
                        Radius.elliptical(4.5, 9),
                      ),
                      border: Border.all(
                        color: colors.textTertiary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.selectedBorder,
                        width: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Play Online',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _RowAction(label: 'Play', icon: Icons.play_arrow, onTap: onPlay),
        ],
      ),
    );
  }
}

/// The compact filled action that ends a row on the Play tab — both Play
/// buttons and Resume. One size for all of them: rows are peers, so their
/// actions shouldn't differ in weight just because the labels differ.
class _RowAction extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  static const double _width = 86;
  static const double _height = 40;

  const _RowAction({required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: colors.accent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: _width,
            height: _height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: colors.accentOnSurface),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.accentOnSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotCard extends ConsumerWidget {
  final void Function(String difficulty)? onPlay;

  const _BotCard({required this.onPlay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final selected = ref.watch(_botDifficultyProvider);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header: the icon and label, like the other play cards.
          Row(
            children: [
              _IconTile(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        for (int i = 0; i < 2; i++)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colors.selectedBorder,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 14,
                      height: 3,
                      decoration: BoxDecoration(
                        color: colors.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Play a Bot',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Pick the level, then start the game. Tapping a difficulty only
          // moves the outline — launching is Play's job, so a stray tap
          // while browsing can't drop you into a game.
          Row(
            children: [
              for (final (value, label) in _difficulties)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _DifficultyChip(
                      label: label,
                      selected: selected == value,
                      onTap: () =>
                          ref.read(_botDifficultyProvider.notifier).set(value),
                    ),
                  ),
                ),
              const SizedBox(width: 2),
              _RowAction(
                label: 'Play',
                icon: Icons.play_arrow,
                onTap: onPlay == null ? null : () => onPlay!(selected),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One difficulty option: an outlined rectangle that takes the accent border
/// when it's the chosen level. No fill — the filled thing in this card is the
/// Play button, and only one thing should read as the action.
class _DifficultyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DifficultyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colors.accent : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? colors.accent : colors.textTertiary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _FriendCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _Card(
      onTap: onTap,
      child: Row(
        children: [
          _IconTile(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 5,
              children: [
                _Peg(head: colors.pegPlayer, stem: colors.accentPressed),
                _Peg(head: colors.pegOpponent, stem: colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Play a Friend',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.chevron_right, size: 18, color: colors.textDisabled),
        ],
      ),
    );
  }
}

/// A single peg: round head over a tapered stem.
class _Peg extends StatelessWidget {
  final Color head;
  final Color stem;

  const _Peg({required this.head, required this.stem});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: head, shape: BoxShape.circle),
        ),
        Transform.translate(
          offset: const Offset(0, -1),
          child: Container(
            width: 4.5,
            height: 9,
            decoration: BoxDecoration(
              color: stem,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyPuzzleCard extends ConsumerWidget {
  const _DailyPuzzleCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final status = ref.watch(dailyPuzzleStatusProvider);
    final completedToday = status.valueOrNull?.completedToday ?? false;
    final completedCount = status.valueOrNull?.completedCount ?? 0;
    final streak = status.valueOrNull?.streak ?? 0;

    final (label, labelColor) = streak > 0
        ? ('streak $streak', colors.streak)
        : completedToday
        ? ('solved today', colors.textTertiary)
        : ('$completedCount of 5', colors.textTertiary);

    return _Card(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/daily-puzzle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PuzzleCards(),
          const SizedBox(height: 10),
          Text(
            'Daily Puzzle',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: labelColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// The daily puzzle mark: a face-down card tucked behind a "?" card.
class _PuzzleCards extends StatelessWidget {
  const _PuzzleCards();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 44,
      height: 58,
      child: Stack(
        // The back card is offset 8px and tilted, so its corner reaches past
        // the 44px box — let it spill into the card's padding rather than
        // shaving the edge off.
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 8,
            top: 0,
            child: Transform.rotate(
              angle: 5 * math.pi / 180,
              // The real card back, so the mark carries the same slate and
              // 45° hairlines as the deck in play.
              child: const CardWidget(
                faceUp: false,
                enabled: false,
                width: 38,
                height: 52,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 3,
            child: Container(
              width: 38,
              height: 52,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.cardFace,
                borderRadius: BorderRadius.circular(5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Text(
                    '?',
                    style: TextStyle(
                      color: colors.suitRed,
                      fontSize: 15,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '♥',
                      style: TextStyle(
                        color: colors.suitRed,
                        fontSize: 14,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PuzzleModeCard extends StatelessWidget {
  const _PuzzleModeCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _Card(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/practice-puzzle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            height: 58,
            child: Center(
              // Sized to sit level with the card mark on the daily card.
              child: _PuzzlePiece(background: colors.surfacePrimary, size: 52),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Puzzle Mode',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'drills & traps',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textTertiary, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

/// Jigsaw piece drawn from a rounded square with two knobs and one notch.
class _PuzzlePiece extends StatelessWidget {
  final Color background;

  /// Drawn against a 40px grid and scaled from there, so the piece can be
  /// sized to sit level with the daily card mark beside it.
  final double size;

  const _PuzzlePiece({required this.background, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final k = size / 40;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 4 * k,
            top: 10 * k,
            child: Container(
              width: 26 * k,
              height: 26 * k,
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(5 * k),
              ),
            ),
          ),
          Positioned(
            left: 12 * k,
            top: 3 * k,
            child: _Knob(color: colors.accent, size: 11 * k),
          ),
          Positioned(
            left: 25 * k,
            top: 18 * k,
            child: _Knob(color: colors.accent, size: 11 * k),
          ),
          Positioned(
            left: -1 * k,
            top: 18 * k,
            child: _Knob(color: background, size: 11 * k),
          ),
        ],
      ),
    );
  }
}

class _Knob extends StatelessWidget {
  final Color color;
  final double size;

  const _Knob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _RecentGamesSection extends ConsumerWidget {
  const _RecentGamesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final auth = ref.watch(authProvider);
    final records = ref.watch(localGameHistoryProvider).valueOrNull ?? const [];
    final serverGames =
        ref.watch(serverGameHistoryProvider).valueOrNull ?? const [];
    // On-device records clear once they upload, so the server holds the rest.
    final recent = [
      for (final r in records) GameSummary.fromLocal(r),
      for (final g in serverGames) GameSummary.fromServer(g, auth.userId ?? ''),
    ].take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const _Caption('Recent games'),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/history'),
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
                      if (i > 0) Divider(height: 1, color: colors.border),
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
  final GameSummary record;

  const _RecentGameRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final resultColor = record.isWin ? colors.success : colors.error;

    return InkWell(
      onTap: () => context.push('/replay/${record.gameId}'),
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: record.opponentId == null
                      ? null
                      : () => context.push('/profile/${record.opponentId}'),
                  child: Text(
                    record.opponentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      decoration: record.opponentId == null
                          ? null
                          : TextDecoration.underline,
                      decorationColor: colors.textDisabled,
                    ),
                  ),
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
            if (record.ratingDelta != null) ...[
              const SizedBox(width: 8),
              Text(
                formatRatingDelta(record.ratingDelta!),
                style: TextStyle(
                  color: record.ratingDelta! >= 0
                      ? colors.success
                      : colors.error,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResumeSection extends StatelessWidget {
  final AsyncValue<List<GameState>> activeGames;
  final AsyncValue<ActiveLocalGame?> activeLocalGame;
  final bool isLoggedIn;

  const _ResumeSection({
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
      spacing: 10,
      children: [
        if (localGame != null) _ResumeCard(game: localGame.gameState),
        ...onlineGames.map((game) => _ResumeCard(game: game)),
      ],
    );
  }
}

/// The resume card (comp 3a): a two-lane peg snapshot of where the game
/// stands, who you're playing, and a green Resume.
class _ResumeCard extends ConsumerWidget {
  final GameState game;

  const _ResumeCard({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final auth = ref.watch(authProvider);
    final playerId = auth.userId ?? '';
    final index = game.players.indexWhere((p) => p.id == playerId);
    final player = index >= 0 ? game.players[index] : game.players[0];
    final opponent = game.players[index >= 0 ? 1 - index : 1];
    final isMyTurn = game.currentPlayerId == player.id;

    return _Card(
      color: colors.boardPrimary,
      onTap: () => context.push('/game/${game.gameId}'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          _MiniTrack(playerScore: player.score, opponentScore: opponent.score),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs ${opponent.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${player.score}–${opponent.score} · '
                  '${isMyTurn ? 'your play' : 'their play'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _RowAction(
            label: 'Resume',
            onTap: () => context.push('/game/${game.gameId}'),
          ),
        ],
      ),
    );
  }
}

/// Two five-hole lanes with each player's peg sitting where their score is —
/// the board, small enough to read in a list row.
class _MiniTrack extends StatelessWidget {
  final int playerScore;
  final int opponentScore;

  static const _holes = 5;

  const _MiniTrack({required this.playerScore, required this.opponentScore});

  int _position(int score) =>
      ((score / 121) * _holes).floor().clamp(0, _holes - 1);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget lane(int pegAt, Color pegColor) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 3,
      children: [
        for (int i = 0; i < _holes; i++)
          if (i == pegAt)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: pegColor,
                shape: BoxShape.circle,
              ),
            )
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.boardHole,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xB3000000),
                    blurRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        lane(_position(playerScore), colors.pegPlayer),
        lane(_position(opponentScore), colors.pegOpponent),
      ],
    );
  }
}
