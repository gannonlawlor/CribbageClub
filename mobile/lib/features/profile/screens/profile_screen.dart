import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/profile_response.dart';

final _profileProvider =
    FutureProvider.autoDispose.family<ProfileResponse, String>((
  ref,
  userId,
) async {
  final restClient = ref.read(restClientProvider);
  return restClient.getProfile(userId);
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
    final profile = ref.watch(_profileProvider(widget.userId));
    final auth = ref.watch(authProvider);
    final isOwnProfile = auth.userId == widget.userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile.when(
        data: (p) => Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar circle with initials
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.goldAccent.withValues(alpha: 0.2),
                      child: Text(
                        _initials(p.displayName ?? p.username),
                        style: const TextStyle(
                          color: AppTheme.goldAccent,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Display name
                    Text(
                      p.displayName ?? p.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (p.displayName != null)
                      Text(
                        '@${p.username}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since ${_formatDate(p.createdAt)}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action button (not shown on own profile)
                    if (!isOwnProfile) _buildActionButton(p, ref),

                    const SizedBox(height: 24),

                    // Rating
                    Text(
                      '${p.rating.round()}',
                      style: const TextStyle(
                        color: AppTheme.goldAccent,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Rating',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),

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
                        foregroundColor: Colors.white70,
                        selectedForegroundColor: AppTheme.goldAccent,
                        selectedBackgroundColor:
                            AppTheme.goldAccent.withValues(alpha: 0.15),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stats for selected category
                    _buildStats(_categoryStats(p)),
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
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
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
        // W-L record
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

  Widget _buildActionButton(ProfileResponse p, WidgetRef ref) {
    return switch (p.relationshipStatus) {
      'FRIENDS' => Chip(
          avatar: const Icon(Icons.check, size: 16, color: Colors.greenAccent),
          label: const Text(
            'Friends',
            style: TextStyle(color: Colors.white70),
          ),
          backgroundColor: Colors.white10,
          side: BorderSide.none,
        ),
      'PENDING_SENT' => Chip(
          avatar: const Icon(Icons.schedule, size: 16, color: Colors.white38),
          label: const Text(
            'Request Sent',
            style: TextStyle(color: Colors.white54),
          ),
          backgroundColor: Colors.white10,
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

  Future<void> _addFriend(WidgetRef ref, ProfileResponse p) async {
    try {
      final restClient = ref.read(restClientProvider);
      await restClient.sendFriendRequest(p.username);
      ref.invalidate(_profileProvider(widget.userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      }
    }
  }

  Future<void> _acceptRequest(WidgetRef ref, ProfileResponse p) async {
    try {
      final restClient = ref.read(restClientProvider);
      // Search to find the friendship ID for this pending request
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept request: $e')),
        );
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
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
