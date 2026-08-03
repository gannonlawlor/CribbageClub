import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/leaderboard_entry.dart';
import '../../../shared/widgets/cc_screen.dart';
import '../../../shared/widgets/cc_swipe_back.dart';
import '../../../shared/utils/navigation.dart';

final _leaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>(
  (ref) async {
    final restClient = ref.read(restClientProvider);
    return restClient.getLeaderboard();
  },
);

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(_leaderboardProvider);
    await ref.read(_leaderboardProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final auth = ref.watch(authProvider);

    Widget body;
    if (!auth.isLoggedIn) {
      body = CcMessage(
        title: 'Sign in to see the ladder',
        detail: 'The leaderboard ranks players by rating.',
        action: 'Sign in',
        onAction: () => context.go('/login'),
      );
    } else {
      final leaderboard = ref.watch(_leaderboardProvider);
      body = leaderboard.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const CcMessage(
              title: 'No ranked players yet',
              detail: 'Play a rated game to put yourself on the ladder.',
            );
          }

          final myIndex = entries.indexWhere((e) => e.playerId == auth.userId);
          final me = myIndex >= 0 ? entries[myIndex] : null;

          return RefreshIndicator(
            color: colors.accent,
            onRefresh: () => _refresh(ref),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                if (me != null) ...[
                  const CcSectionCaption('Your standing'),
                  _MyStanding(
                    entry: me,
                    rank: myIndex + 1,
                    onTap: () => context.push('/profile/${me.playerId}'),
                  ),
                  const SizedBox(height: 20),
                ],
                const CcSectionCaption('Top players'),
                _LadderTable(
                  entries: entries,
                  meId: auth.userId,
                  onTap: (id) => context.push('/profile/$id'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => CcMessage(
          title: 'Leaderboard unavailable',
          detail: '$error',
          action: 'Go back',
          onAction: () => context.backOrHome(),
        ),
      );
    }

    return CcSwipeBack(
      onBack: () => context.backOrHome(),
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
                    title: 'Leaderboard',
                    onBack: () => context.backOrHome(),
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where you sit, pulled out of the table so you never have to hunt for
/// your own row. Rating is the only gold on the screen (§2).
class _MyStanding extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final VoidCallback onTap;

  const _MyStanding({
    required this.entry,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: CcPanel(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.gamesWon}–${entry.gamesLost} · '
                      '${(entry.winRate * 100).round()}% wins',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.rating.round()}',
                    style: TextStyle(
                      color: colors.ratingGold,
                      fontSize: 24,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (entry.currentWinStreak > 1) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${entry.currentWinStreak} straight',
                      style: TextStyle(
                        color: colors.streak,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The ladder as a data table (design language §4): caption header row,
/// hairline separators, right-aligned tabular numerals, and a green wash on
/// your own row.
class _LadderTable extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String? meId;
  final void Function(String playerId) onTap;

  const _LadderTable({
    required this.entries,
    required this.meId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget headerCell(String text, {TextAlign align = TextAlign.left}) => Text(
      text.toUpperCase(),
      textAlign: align,
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Container(
              color: colors.surfacePrimary,
              padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
              child: Row(
                children: [
                  SizedBox(width: 26, child: headerCell('#')),
                  const SizedBox(width: 10),
                  Expanded(child: headerCell('Player')),
                  SizedBox(
                    width: 54,
                    child: headerCell('W–L', align: TextAlign.right),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 44,
                    child: headerCell('Rating', align: TextAlign.right),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < entries.length; i++) ...[
              Divider(height: 1, color: colors.border),
              _LadderRow(
                entry: entries[i],
                rank: i + 1,
                isMe: entries[i].playerId == meId,
                onTap: () => onTap(entries[i].playerId),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LadderRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isMe;
  final VoidCallback onTap;

  const _LadderRow({
    required this.entry,
    required this.rank,
    required this.isMe,
    required this.onTap,
  });

  /// The top three carry a medal tint on the rank alone — the table stays a
  /// table, but the podium is still legible at a glance.
  Color? _medal(AppColors colors) => switch (rank) {
    1 => colors.medalGold,
    2 => colors.medalSilver,
    3 => colors.medalBronze,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final medal = _medal(colors);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isMe ? colors.pegPlayer.withValues(alpha: 0.08) : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: medal ?? colors.textTertiary,
                  fontSize: 13,
                  fontWeight: medal != null ? FontWeight.w700 : FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 10),
            CcAvatar(name: entry.displayName, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      entry.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (entry.currentWinStreak > 1) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${entry.currentWinStreak}▲',
                      style: TextStyle(
                        color: colors.streak,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: 54,
              child: Text(
                '${entry.gamesWon}–${entry.gamesLost}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 12.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 44,
              child: Text(
                '${entry.rating.round()}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: colors.ratingGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
