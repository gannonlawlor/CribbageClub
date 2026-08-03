import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/profile_response.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/services/achievement_service.dart';
import '../../../core/services/local_game_history_provider.dart';
import '../../../shared/widgets/cc_bottom_nav.dart';
import '../../daily_puzzle/state/puzzle_provider.dart';
import '../../../shared/widgets/game_history_row.dart';
import '../state/my_profile_provider.dart';
import '../widgets/achievements_section.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "Me" tab (design comp 3c): identity, rating, stat tiles, game history.
class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final auth = ref.watch(authProvider);
    final profile = ref.watch(myProfileProvider).valueOrNull;
    final records = ref.watch(localGameHistoryProvider).valueOrNull ?? const [];
    final serverGames =
        ref.watch(serverGameHistoryProvider).valueOrNull ?? const [];
    final puzzle = ref.watch(dailyPuzzleStatusProvider);
    final streak = puzzle.valueOrNull?.streak ?? 0;

    final name = auth.username ?? 'Guest';
    final localWins = records.where((r) => r.isWin).length;
    final localLosses = records.length - localWins;

    // On-device records are the games that haven't reached the server yet —
    // they clear as soon as an upload succeeds. Counting both keeps a game you
    // just finished from reading as 0–0 while its upload is still pending.
    final wins = (profile?.overallStats.gamesWon ?? 0) + localWins;
    final losses = (profile?.overallStats.gamesLost ?? 0) + localLosses;
    final gamesPlayed =
        (profile?.overallStats.gamesPlayed ?? 0) + records.length;

    String? memberSince;
    if (profile != null) {
      final created = DateTime.tryParse(profile.createdAt);
      if (created != null) {
        memberSince =
            'Member since ${_months[created.month - 1]} ${created.year}';
      }
    }
    final subtitle = [
      memberSince ?? (auth.isLoggedIn && auth.isGuest ? 'Guest account' : null),
      '$gamesPlayed game${gamesPlayed == 1 ? '' : 's'}',
    ].whereType<String>().join(' · ');

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                // Identity header
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colors.surfaceDim,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: 12.5,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Guest / signed-out prompt
                if (!auth.isLoggedIn || auth.isGuest) ...[
                  _PromptCard(
                    text: auth.isLoggedIn
                        ? 'You\'re playing as a guest. Create an account to keep a rating and your game history.'
                        : 'Sign in to keep a rating and your game history.',
                    actionLabel: auth.isLoggedIn ? 'Upgrade' : 'Sign in',
                    onTap: () =>
                        context.go(auth.isLoggedIn ? '/upgrade' : '/login'),
                  ),
                  const SizedBox(height: 14),
                ],

                // Rating card (server identity only)
                if (profile != null) ...[
                  _RatingCard(profile: profile),
                  const SizedBox(height: 14),
                ],

                // Stat tiles
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        caption: 'Record',
                        value: '$wins–$losses',
                        suffix: (profile?.currentWinStreak ?? 0) > 1
                            ? 'W${profile!.currentWinStreak}'
                            : null,
                        suffixColor: colors.streak,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        caption: 'Puzzle streak',
                        value: streak > 0 ? '$streak days' : '—',
                        suffix: null,
                        suffixColor: colors.streak,
                      ),
                    ),
                  ],
                ),
                if (profile != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          // Local records are all engine games, so they land
                          // in this tile too until they upload.
                          caption: 'vs engine',
                          value:
                              '${profile.aiStats.gamesWon + localWins}–${profile.aiStats.gamesLost + localLosses}',
                          suffix: null,
                          suffixColor: colors.streak,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          caption: 'vs humans',
                          value:
                              '${profile.humanStats.gamesWon}–${profile.humanStats.gamesLost}',
                          suffix: null,
                          suffixColor: colors.streak,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),

                // Friends / leaderboard rows
                _LinkRow(
                  icon: Icons.people_outline,
                  label: 'Friends',
                  badge: ref
                      .watch(notificationCountProvider)
                      .whenOrNull(data: (n) => n.total),
                  onTap: () => context.go('/friends'),
                ),
                const SizedBox(height: 8),
                _LinkRow(
                  icon: Icons.leaderboard_outlined,
                  label: 'Leaderboard',
                  onTap: () => context.go('/leaderboard'),
                ),
                const SizedBox(height: 18),

                // Achievements (server identity only — needs an account)
                if (auth.isLoggedIn)
                  ref
                          .watch(myAchievementsProvider)
                          .whenOrNull(
                            data: (achievements) => achievements == null
                                ? null
                                : Column(
                                    children: [
                                      AchievementsSection(
                                        response: achievements,
                                      ),
                                      const SizedBox(height: 18),
                                    ],
                                  ),
                          ) ??
                      const SizedBox.shrink(),

                // History
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      Text(
                        'HISTORY',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.7,
                        ),
                      ),
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
                GameHistoryList(
                  games: [
                    // Uploaded games live on the server; anything still on the
                    // device hasn't made it there yet. Both are your history.
                    for (final r in records) GameSummary.fromLocal(r),
                    for (final g in serverGames)
                      GameSummary.fromGameState(g, auth.userId ?? ''),
                  ].take(8).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CcBottomNav(active: CcTab.profile),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final String text;
  final String actionLabel;
  final VoidCallback onTap;

  const _PromptCard({
    required this.text,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              text,
              style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              actionLabel,
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

class _RatingCard extends StatelessWidget {
  final ProfileResponse profile;

  const _RatingCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RATING',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${profile.rating.round()}',
                style: TextStyle(
                  color: colors.ratingGold,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (profile.currentWinStreak > 1) ...[
                const SizedBox(width: 10),
                Text(
                  '${profile.currentWinStreak} straight',
                  style: TextStyle(
                    color: colors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Best streak ${profile.longestWinStreak} · highest game ${profile.highestGameScore}',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 12.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String caption;
  final String value;
  final String? suffix;
  final Color suffixColor;

  const _StatTile({
    required this.caption,
    required this.value,
    required this.suffix,
    required this.suffixColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption.toUpperCase(),
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 6),
                Text(
                  suffix!,
                  style: TextStyle(
                    color: suffixColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? badge;
  final VoidCallback onTap;

  const _LinkRow({
    required this.icon,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surfacePrimary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Badge(
                isLabelVisible: (badge ?? 0) > 0,
                label: Text('$badge', style: const TextStyle(fontSize: 10)),
                backgroundColor: colors.error,
                child: Icon(icon, size: 19, color: colors.textSecondary),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, size: 18, color: colors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}
