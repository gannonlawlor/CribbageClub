import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/leaderboard_entry.dart';
import '../../../shared/utils/text_utils.dart';

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, size: 64, color: colors.textDisabled),
                  const SizedBox(height: 16),
                  Text(
                    'No players yet',
                    style: TextStyle(color: colors.textTertiary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Play some games to appear on the leaderboard!',
                    style: TextStyle(color: colors.textDisabled, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // Split into top 3 and rest
          final top3 = entries.take(3).toList();
          final rest = entries.length > 3 ? entries.sublist(3) : <LeaderboardEntry>[];
          final myEntry = entries.cast<LeaderboardEntry?>().firstWhere(
            (e) => e!.playerId == auth.userId,
            orElse: () => null,
          );
          final myRank = myEntry != null
              ? entries.indexOf(myEntry) + 1
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // My Rank card
              if (myEntry != null && myRank != null)
                _MyRankCard(
                  entry: myEntry,
                  rank: myRank,
                  colors: colors,
                  onTap: () => context.push('/profile/${myEntry.playerId}'),
                ),
              if (myEntry != null) const SizedBox(height: 16),

              // Podium for top 3
              if (top3.length >= 3)
                _Podium(
                  entries: top3,
                  currentUserId: auth.userId,
                  colors: colors,
                  onTap: (id) => context.push('/profile/$id'),
                )
              else
                // If less than 3 entries, show them as regular tiles
                ...top3.asMap().entries.map(
                  (e) => _LeaderboardTile(
                    entry: e.value,
                    rank: e.key + 1,
                    isCurrentUser: e.value.playerId == auth.userId,
                    colors: colors,
                    onTap: () => context.push('/profile/${e.value.playerId}'),
                  ),
                ),

              if (top3.length >= 3) const SizedBox(height: 16),

              // Rest of leaderboard (4+)
              ...rest.asMap().entries.map(
                (e) => _LeaderboardTile(
                  entry: e.value,
                  rank: e.key + 4,
                  isCurrentUser: e.value.playerId == auth.userId,
                  colors: colors,
                  onTap: () => context.push('/profile/${e.value.playerId}'),
                ),
              ),
            ],
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

class _MyRankCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final AppColors colors;
  final VoidCallback onTap;

  const _MyRankCard({
    required this.entry,
    required this.rank,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.accent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accent.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: colors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Rank',
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    entry.displayName,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
                    fontSize: 20,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(entry.winRate * 100).toStringAsFixed(0)}% win',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    if (entry.currentWinStreak > 0) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.local_fire_department, size: 14, color: colors.warning),
                      Text(
                        '${entry.currentWinStreak}',
                        style: TextStyle(
                          color: colors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String? currentUserId;
  final AppColors colors;
  final void Function(String playerId) onTap;

  const _Podium({
    required this.entries,
    required this.currentUserId,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final first = entries[0];
    final second = entries[1];
    final third = entries[2];

    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place (left)
          Expanded(child: _PodiumEntry(
            entry: second,
            rank: 2,
            height: 130,
            medalColor: const Color(0xFFC0C0C0),
            colors: colors,
            isCurrentUser: second.playerId == currentUserId,
            onTap: () => onTap(second.playerId),
          )),
          const SizedBox(width: 8),
          // 1st place (center, tallest)
          Expanded(child: _PodiumEntry(
            entry: first,
            rank: 1,
            height: 170,
            medalColor: const Color(0xFFFFD700),
            colors: colors,
            isCurrentUser: first.playerId == currentUserId,
            onTap: () => onTap(first.playerId),
          )),
          const SizedBox(width: 8),
          // 3rd place (right)
          Expanded(child: _PodiumEntry(
            entry: third,
            rank: 3,
            height: 100,
            medalColor: const Color(0xFFCD7F32),
            colors: colors,
            isCurrentUser: third.playerId == currentUserId,
            onTap: () => onTap(third.playerId),
          )),
        ],
      ),
    );
  }
}

class _PodiumEntry extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double height;
  final Color medalColor;
  final AppColors colors;
  final bool isCurrentUser;
  final VoidCallback onTap;

  const _PodiumEntry({
    required this.entry,
    required this.rank,
    required this.height,
    required this.medalColor,
    required this.colors,
    required this.isCurrentUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar + medal
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: rank == 1 ? 28 : 22,
                backgroundColor: isCurrentUser
                    ? colors.accent.withValues(alpha: 0.2)
                    : colors.surfaceDim,
                child: Text(
                  initials(entry.displayName),
                  style: TextStyle(
                    color: isCurrentUser ? colors.accent : colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: rank == 1 ? 16 : 13,
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Icon(
                  Icons.emoji_events,
                  size: 18,
                  color: medalColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.displayName,
            style: TextStyle(
              color: isCurrentUser ? colors.accent : colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${entry.rating.round()}',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          // Pedestal
          Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: medalColor.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border.all(
                color: medalColor.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: medalColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isCurrentUser;
  final AppColors colors;
  final VoidCallback onTap;

  const _LeaderboardTile({
    required this.entry,
    required this.rank,
    required this.isCurrentUser,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? colors.accent.withValues(alpha: 0.1)
              : colors.surfaceDim,
          borderRadius: BorderRadius.circular(12),
          border: isCurrentUser
              ? Border.all(
                  color: colors.accent.withValues(alpha: 0.4),
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
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: isCurrentUser
                    ? colors.accent.withValues(alpha: 0.15)
                    : colors.surfaceDim,
                child: Text(
                  initials(entry.displayName),
                  style: TextStyle(
                    color: isCurrentUser ? colors.accent : colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
                            : FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${entry.gamesPlayed} games',
                          style: TextStyle(
                            color: colors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        if (entry.currentWinStreak > 0) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.local_fire_department, size: 12, color: colors.warning),
                          Text(
                            '${entry.currentWinStreak}',
                            style: TextStyle(
                              color: colors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
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
                    '${(entry.winRate * 100).toStringAsFixed(0)}%',
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
  }
}
