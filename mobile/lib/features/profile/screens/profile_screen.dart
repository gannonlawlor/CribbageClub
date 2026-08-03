import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/head_to_head_response.dart';
import '../../../core/models/profile_response.dart';
import '../../../shared/widgets/cc_screen.dart';
import '../../../shared/widgets/game_history_row.dart';
import '../../../shared/widgets/cc_swipe_back.dart';
import '../../../core/services/achievement_service.dart';
import '../widgets/achievements_section.dart';

final _profileProvider = FutureProvider.autoDispose
    .family<ProfileResponse, String>((ref, userId) async {
      final restClient = ref.read(restClientProvider);
      return restClient.getProfile(userId);
    });

final _gameHistoryProvider = FutureProvider.autoDispose<List<GameState>>((
  ref,
) async {
  final auth = ref.read(authProvider);
  if (!auth.isLoggedIn) return [];
  final restClient = ref.read(restClientProvider);
  return restClient.getMyGameHistory();
});

final _headToHeadProvider = FutureProvider.autoDispose
    .family<HeadToHeadResponse?, String>((ref, userId) async {
      final auth = ref.read(authProvider);
      if (!auth.isLoggedIn || auth.userId == userId) return null;
      try {
        final restClient = ref.read(restClientProvider);
        return await restClient.getHeadToHead(userId);
      } catch (e) {
        debugPrint('[Profile] Failed to load head-to-head: $e');
        return null;
      }
    });

class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedSegment = 0; // 0=Overall, 1=vs Humans, 2=vs AI

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final profile = ref.watch(_profileProvider(widget.userId));
    final auth = ref.watch(authProvider);
    final isOwnProfile = auth.userId == widget.userId;

    return CcSwipeBack(
      onBack: () => context.pop(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Profile'),
        ),
        body: profile.when(
          data: (p) => Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Hero: avatar with accent ring
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.accent.withValues(alpha: 0.5),
                            width: 3,
                          ),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: colors.accent.withValues(alpha: 0.2),
                          child: Text(
                            _initials(p.displayName ?? p.username),
                            style: TextStyle(
                              color: colors.accent,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Display name
                      Text(
                        p.displayName ?? p.username,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (p.displayName != null)
                        Text(
                          '@${p.username}',
                          style: TextStyle(
                            color: colors.textTertiary,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Member since ${_formatDate(p.createdAt)}',
                        style: TextStyle(
                          color: colors.textDisabled,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action row: friend chip/button + challenge button
                      if (!isOwnProfile) _buildActionRow(p, ref),

                      const SizedBox(height: 24),

                      // Rating badge
                      _buildRatingBadge(p),

                      const SizedBox(height: 20),

                      // Highlights row
                      _buildHighlightsRow(p),

                      const SizedBox(height: 24),

                      // Segmented button
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Overall')),
                          ButtonSegment(value: 1, label: Text('vs Humans')),
                          ButtonSegment(value: 2, label: Text('vs AI')),
                        ],
                        selected: {_selectedSegment},
                        onSelectionChanged: (s) =>
                            setState(() => _selectedSegment = s.first),
                        style: SegmentedButton.styleFrom(
                          foregroundColor: colors.textSecondary,
                          selectedForegroundColor: colors.accent,
                          selectedBackgroundColor: colors.accent.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Stats for selected category
                      _buildStats(_categoryStats(p)),

                      const SizedBox(height: 24),

                      // Achievements
                      ref
                              .watch(achievementsForUserProvider(widget.userId))
                              .whenOrNull(
                                data: (achievements) => Column(
                                  children: [
                                    AchievementsSection(response: achievements),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ) ??
                          const SizedBox.shrink(),

                      // Head-to-head (other users only)
                      if (!isOwnProfile) _buildHeadToHead(),

                      // Game history (own profile only)
                      if (isOwnProfile) _buildGameHistory(auth.userId ?? ''),
                    ],
                  ),
                ),
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Failed to load profile: $error',
                style: TextStyle(color: colors.error),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBadge(ProfileResponse p) {
    final colors = context.appColors;
    final isProvisional = p.ratingDeviation > 100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: colors.ratingGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '${p.rating.round()}',
            style: TextStyle(
              color: colors.ratingGold,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isProvisional
                ? 'Provisional'
                : '\u00b1${p.ratingDeviation.round()}',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsRow(ProfileResponse p) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _HighlightBox(
          icon: Icons.emoji_events,
          iconColor: colors.medalGold,
          label: 'High',
          value: '${p.highestGameScore}',
        ),
        Container(width: 1, height: 32, color: colors.surfaceDim),
        _HighlightBox(
          icon: Icons.local_fire_department,
          iconColor: colors.streak,
          label: 'Streak',
          value: '${p.currentWinStreak}',
        ),
        Container(width: 1, height: 32, color: colors.surfaceDim),
        _HighlightBox(
          icon: Icons.star,
          iconColor: colors.medalGold,
          label: 'Best',
          value: '${p.longestWinStreak}',
        ),
      ],
    );
  }

  CategoryStats _categoryStats(ProfileResponse p) {
    return switch (_selectedSegment) {
      1 => p.humanStats,
      2 => p.aiStats,
      _ => p.overallStats,
    };
  }

  Widget _buildStats(CategoryStats stats) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatBox(label: 'Played', value: '${stats.gamesPlayed}'),
            const SizedBox(width: 24),
            _StatBox(label: 'Won', value: '${stats.gamesWon}'),
            const SizedBox(width: 24),
            _StatBox(label: 'Lost', value: '${stats.gamesLost}'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatBox(
              label: 'Win Rate',
              value: '${(stats.winRate * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(width: 24),
            _StatBox(
              label: 'Avg Score',
              value: stats.averageScore.toStringAsFixed(1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionRow(ProfileResponse p, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFriendChip(p, ref),
        if (p.relationshipStatus == 'FRIENDS') ...[
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => _challenge(ref, p),
            icon: const Icon(Icons.sports_esports, size: 18),
            label: const Text('Challenge'),
          ),
        ],
      ],
    );
  }

  Widget _buildFriendChip(ProfileResponse p, WidgetRef ref) {
    final colors = context.appColors;
    return switch (p.relationshipStatus) {
      'FRIENDS' => Chip(
        avatar: Icon(Icons.check, size: 16, color: colors.success),
        label: Text('Friends', style: TextStyle(color: colors.textSecondary)),
        backgroundColor: colors.surfaceDim,
        side: BorderSide.none,
      ),
      'PENDING_SENT' => Chip(
        avatar: Icon(Icons.schedule, size: 16, color: colors.textDisabled),
        label: Text(
          'Request Sent',
          style: TextStyle(color: colors.textTertiary),
        ),
        backgroundColor: colors.surfaceDim,
        side: BorderSide.none,
      ),
      'PENDING_RECEIVED' => ElevatedButton.icon(
        onPressed: () => _acceptRequest(ref, p),
        icon: const Icon(Icons.person_add, size: 18),
        label: const Text('Accept Request'),
      ),
      _ => ElevatedButton.icon(
        onPressed: () => _addFriend(ref, p),
        icon: const Icon(Icons.person_add, size: 18),
        label: const Text('Add Friend'),
      ),
    };
  }

  Widget _buildHeadToHead() {
    final colors = context.appColors;
    final h2h = ref.watch(_headToHeadProvider(widget.userId));
    return h2h.when(
      data: (data) {
        if (data == null || data.gamesPlayed == 0) {
          return const SizedBox.shrink();
        }
        final total = data.gamesPlayed;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Head-to-Head',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Win bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    Expanded(
                      flex: data.viewerWins,
                      child: Container(color: colors.accent),
                    ),
                    if (data.opponentWins > 0)
                      Expanded(
                        flex: data.opponentWins,
                        child: Container(color: colors.error),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'You: ${data.viewerWins}',
                  style: TextStyle(
                    color: colors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$total games',
                  style: TextStyle(color: colors.textTertiary, fontSize: 12),
                ),
                Text(
                  'Them: ${data.opponentWins}',
                  style: TextStyle(
                    color: colors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (data.recentGames.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final game in data.recentGames.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _HeadToHeadGameRow(game: game),
                ),
            ],
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildGameHistory(String playerId) {
    final colors = context.appColors;
    final history = ref.watch(_gameHistoryProvider);
    return history.when(
      data: (games) {
        if (games.isEmpty) return const SizedBox.shrink();
        final recent = games.take(10).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CcSectionCaption('Recent games'),
            GameHistoryList(
              games: [
                for (final game in recent)
                  GameSummary.fromGameState(game, playerId),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => context.push('/history'),
                child: Text(
                  'View All History',
                  style: TextStyle(color: colors.accent),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Future<void> _challenge(WidgetRef ref, ProfileResponse p) async {
    try {
      final restClient = ref.read(restClientProvider);
      final lobby = await restClient.createChallenge(p.userId);
      if (mounted) {
        context.push('/lobby/${lobby.id}');
      }
    } catch (e) {
      debugPrint('[Profile] Failed to challenge ${p.username}: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send challenge: $e')));
      }
    }
  }

  Future<void> _addFriend(WidgetRef ref, ProfileResponse p) async {
    try {
      final restClient = ref.read(restClientProvider);
      await restClient.sendFriendRequest(p.username);
      ref.invalidate(_profileProvider(widget.userId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Friend request sent!')));
      }
    } catch (e) {
      debugPrint(
        '[Profile] Failed to send friend request to ${p.username}: $e',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send request: $e')));
      }
    }
  }

  Future<void> _acceptRequest(WidgetRef ref, ProfileResponse p) async {
    try {
      final restClient = ref.read(restClientProvider);
      final requests = await restClient.getIncomingFriendRequests();
      final match = requests.where((r) => r.fromUserId == p.userId).firstOrNull;
      if (match != null) {
        await restClient.acceptFriendRequest(match.friendshipId);
        ref.invalidate(_profileProvider(widget.userId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friend request accepted!')),
          );
        }
      }
    } catch (e) {
      debugPrint(
        '[Profile] Failed to accept friend request from ${p.username}: $e',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to accept request: $e')));
      }
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _HighlightBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _HighlightBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
      ],
    );
  }
}

class _HeadToHeadGameRow extends StatelessWidget {
  final HeadToHeadGame game;

  const _HeadToHeadGameRow({required this.game});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceDim,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            game.viewerWon ? Icons.emoji_events : Icons.close,
            color: game.viewerWon ? colors.accent : colors.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '${game.viewerScore} - ${game.opponentScore}',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            _formatDate(game.completedAt),
            style: TextStyle(color: colors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.month}/${date.day}';
    } catch (_) {
      return '';
    }
  }
}
