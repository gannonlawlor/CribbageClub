import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/friend.dart';
import '../../../core/models/lobby.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/utils/text_utils.dart';

// Providers
final _friendsProvider = FutureProvider.autoDispose<List<FriendInfo>>((
  ref,
) async {
  final restClient = ref.read(restClientProvider);
  return restClient.getFriends();
});

final _incomingRequestsProvider =
    FutureProvider.autoDispose<List<FriendRequestInfo>>((ref) async {
      final restClient = ref.read(restClientProvider);
      return restClient.getIncomingFriendRequests();
    });

final _outgoingRequestsProvider =
    FutureProvider.autoDispose<List<FriendRequestInfo>>((ref) async {
      final restClient = ref.read(restClientProvider);
      return restClient.getOutgoingFriendRequests();
    });

final _incomingChallengesProvider = FutureProvider.autoDispose<List<Lobby>>((
  ref,
) async {
  final restClient = ref.read(restClientProvider);
  return restClient.getIncomingChallenges();
});

final _searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final _searchResultsProvider =
    FutureProvider.autoDispose<List<UserSearchResult>>((ref) async {
      final query = ref.watch(_searchQueryProvider);
      if (query.length < 2) return [];
      final restClient = ref.read(restClientProvider);
      return restClient.searchUsers(query);
    });

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final notifCount = ref.watch(notificationCountProvider);
    final total = notifCount.whenOrNull(data: (n) => n.total) ?? 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Friends'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.accent,
          labelColor: colors.accent,
          unselectedLabelColor: colors.textTertiary,
          tabs: [
            const Tab(text: 'Friends'),
            Tab(
              child: Badge(
                isLabelVisible: total > 0,
                label: Text('$total', style: const TextStyle(fontSize: 10)),
                backgroundColor: colors.error,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Requests'),
                ),
              ),
            ),
            const Tab(text: 'Find'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_FriendsTab(), _RequestsTab(), _FindTab()],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Tab 1: Friends list
// ──────────────────────────────────────────
class _FriendsTab extends ConsumerWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final friends = ref.watch(_friendsProvider);

    return friends.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_add, size: 64, color: colors.textDisabled),
                  const SizedBox(height: 16),
                  Text(
                    'No friends yet',
                    style: TextStyle(color: colors.textTertiary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the Find tab to search for players and send friend requests.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textDisabled, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }
        if (Responsive.isTabletLandscape(context)) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: list.map((f) => SizedBox(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                child: _FriendTile(friend: f),
              )).toList(),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) => _FriendTile(friend: list[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Failed to load friends: $error',
          style: TextStyle(color: colors.error),
        ),
      ),
    );
  }
}

class _FriendTile extends ConsumerWidget {
  final FriendInfo friend;
  const _FriendTile({required this.friend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final name = friend.displayName ?? friend.username;
    return Dismissible(
      key: Key(friend.friendshipId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: colors.error.withValues(alpha: 0.3),
        child: Icon(Icons.person_remove, color: colors.error),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: colors.surfacePrimary,
            title: Text(
              'Remove Friend',
              style: TextStyle(color: colors.textPrimary),
            ),
            content: Text(
              'Remove $name from your friends?',
              style: TextStyle(color: colors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'Remove',
                  style: TextStyle(color: colors.error),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        try {
          final restClient = ref.read(restClientProvider);
          await restClient.removeFriend(friend.friendshipId);
          ref.invalidate(_friendsProvider);
        } catch (e) {
          debugPrint('[Friends] Failed to remove friend: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to remove friend: $e')),
            );
          }
        }
      },
      child: GestureDetector(
        onTap: () => context.push('/profile/${friend.userId}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: colors.surfaceDim,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: colors.accent.withValues(alpha: 0.15),
                      child: Text(
                        initials(name),
                        style: TextStyle(
                          color: colors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: friend.isOnline ? colors.success : colors.divider,
                          border: Border.all(
                            color: colors.surfaceDim,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (friend.displayName != null)
                        Text(
                          '@${friend.username}',
                          style: TextStyle(
                            color: colors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        'Friends since ${_formatDate(friend.since)}',
                        style: TextStyle(
                          color: colors.textDisabled,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _challengeFriend(context, ref),
                  icon: const Icon(Icons.sports_esports, size: 16),
                  label: const Text('Play'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  Future<void> _challengeFriend(BuildContext context, WidgetRef ref) async {
    try {
      final restClient = ref.read(restClientProvider);
      final lobby = await restClient.createChallenge(friend.userId);
      if (context.mounted) {
        context.go('/lobby/${lobby.id}');
      }
    } catch (e) {
      debugPrint('[Friends] Failed to create challenge: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create challenge: $e')),
        );
      }
    }
  }
}

// ──────────────────────────────────────────
// Tab 2: Requests + Challenges
// ──────────────────────────────────────────
class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final requests = ref.watch(_incomingRequestsProvider);
    final outgoing = ref.watch(_outgoingRequestsProvider);
    final challenges = ref.watch(_incomingChallengesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Incoming friend requests
          Text(
            'Friend Requests',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          requests.when(
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No pending requests',
                    style: TextStyle(color: colors.textDisabled),
                  ),
                );
              }
              return Column(
                children: list
                    .map((r) => _FriendRequestTile(request: r))
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text(
              'Error: $e',
              style: TextStyle(color: colors.error),
            ),
          ),

          const SizedBox(height: 24),

          // Outgoing friend requests
          Text(
            'Sent Requests',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          outgoing.when(
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No sent requests',
                    style: TextStyle(color: colors.textDisabled),
                  ),
                );
              }
              return Column(
                children: list
                    .map((r) => _OutgoingRequestTile(request: r))
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text(
              'Error: $e',
              style: TextStyle(color: colors.error),
            ),
          ),

          const SizedBox(height: 24),

          // Incoming challenges
          Text(
            'Challenges',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          challenges.when(
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No pending challenges',
                    style: TextStyle(color: colors.textDisabled),
                  ),
                );
              }
              return Column(
                children: list
                    .map((c) => _ChallengeTile(challenge: c))
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text(
              'Error: $e',
              style: TextStyle(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendRequestTile extends ConsumerWidget {
  final FriendRequestInfo request;
  const _FriendRequestTile({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final name = request.fromDisplayName ?? request.fromUsername;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surfaceDim,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colors.accent.withValues(alpha: 0.15),
              child: Text(
                initials(name),
                style: TextStyle(
                  color: colors.accent,
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
                    name,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  ),
                  if (request.fromDisplayName != null)
                    Text(
                      '@${request.fromUsername}',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.check, color: colors.success),
              onPressed: () => _accept(context, ref),
              tooltip: 'Accept',
            ),
            IconButton(
              icon: Icon(Icons.close, color: colors.error),
              onPressed: () => _decline(context, ref),
              tooltip: 'Decline',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    try {
      final restClient = ref.read(restClientProvider);
      await restClient.acceptFriendRequest(request.friendshipId);
      ref.invalidate(_incomingRequestsProvider);
      ref.invalidate(_friendsProvider);
      ref.invalidate(notificationCountProvider);
    } catch (e) {
      debugPrint('[Friends] Failed to accept friend request: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to accept: $e')));
      }
    }
  }

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    try {
      final restClient = ref.read(restClientProvider);
      await restClient.declineFriendRequest(request.friendshipId);
      ref.invalidate(_incomingRequestsProvider);
      ref.invalidate(notificationCountProvider);
    } catch (e) {
      debugPrint('[Friends] Failed to decline friend request: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to decline: $e')));
      }
    }
  }
}

class _OutgoingRequestTile extends StatelessWidget {
  final FriendRequestInfo request;
  const _OutgoingRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Outgoing requests reuse the same model; fromUsername is the recipient
    final name = request.fromDisplayName ?? request.fromUsername;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surfaceDim,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colors.accent.withValues(alpha: 0.15),
              child: Text(
                initials(name),
                style: TextStyle(
                  color: colors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colors.accent.withValues(alpha: 0.1),
              ),
              child: Text(
                'Pending',
                style: TextStyle(
                  color: colors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeTile extends ConsumerWidget {
  final Lobby challenge;
  const _ChallengeTile({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final challengerName = challenge.players.isNotEmpty
        ? challenge.players.first.name
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surfaceDim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colors.accent.withValues(alpha: 0.15),
              child: Text(
                initials(challengerName),
                style: TextStyle(
                  color: colors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$challengerName wants to play!',
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
              ),
            ),
            ElevatedButton(
              onPressed: () => _accept(context, ref),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Accept'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _decline(context, ref),
              child: Text(
                'Decline',
                style: TextStyle(color: colors.textTertiary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    try {
      final restClient = ref.read(restClientProvider);
      final result = await restClient.acceptChallenge(challenge.id);
      if (context.mounted) {
        if (result.gameState != null) {
          context.go('/game/${result.gameState!.gameId}');
        } else {
          context.go('/lobby/${result.lobby.id}');
        }
      }
    } catch (e) {
      debugPrint('[Friends] Failed to accept challenge ${challenge.id}: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept challenge: $e')),
        );
      }
    }
  }

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    try {
      final restClient = ref.read(restClientProvider);
      await restClient.declineChallenge(challenge.id);
      ref.invalidate(_incomingChallengesProvider);
      ref.invalidate(notificationCountProvider);
    } catch (e) {
      debugPrint('[Friends] Failed to decline challenge ${challenge.id}: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline challenge: $e')),
        );
      }
    }
  }
}

// ──────────────────────────────────────────
// Tab 3: Find users
// ──────────────────────────────────────────
class _FindTab extends ConsumerStatefulWidget {
  const _FindTab();

  @override
  ConsumerState<_FindTab> createState() => _FindTabState();
}

class _FindTabState extends ConsumerState<_FindTab> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(_searchQueryProvider.notifier).state = value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final results = ref.watch(_searchResultsProvider);
    final query = ref.watch(_searchQueryProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by username...',
              hintStyle: TextStyle(color: colors.textDisabled),
              prefixIcon: Icon(Icons.search, color: colors.textDisabled),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: colors.surfaceDim,
            ),
            style: TextStyle(color: colors.textPrimary),
          ),
        ),
        if (query.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_search, size: 64, color: colors.textDisabled),
                  const SizedBox(height: 16),
                  Text(
                    'Search by username',
                    style: TextStyle(color: colors.textTertiary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find players and send friend requests',
                    style: TextStyle(color: colors.textDisabled, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else if (query.length < 2)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Type at least 2 characters to search',
              style: TextStyle(color: colors.textDisabled),
            ),
          )
        else
          Expanded(
            child: results.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: colors.textTertiary),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) =>
                      _SearchResultTile(result: list[index]),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(
                child: Text(
                  'Search failed: $e',
                  style: TextStyle(color: colors.error),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchResultTile extends ConsumerWidget {
  final UserSearchResult result;
  const _SearchResultTile({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final name = result.displayName ?? result.username;
    final statusLabel = switch (result.relationshipStatus) {
      'FRIENDS' => 'Friends',
      'PENDING_SENT' => 'Request Sent',
      'PENDING_RECEIVED' => 'Pending',
      _ => null,
    };
    final canAdd = result.relationshipStatus == null;

    return GestureDetector(
      onTap: () => context.push('/profile/${result.userId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colors.surfaceDim,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.accent.withValues(alpha: 0.15),
                child: Text(
                  initials(name),
                  style: TextStyle(
                    color: colors.accent,
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
                      name,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    ),
                    if (result.displayName != null)
                      Text(
                        '@${result.username}',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (statusLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: colors.accent.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: colors.textTertiary, fontSize: 11),
                  ),
                ),
              if (canAdd)
                IconButton(
                  icon: Icon(Icons.person_add, color: colors.accent),
                  onPressed: () => _sendRequest(context, ref),
                  tooltip: 'Add Friend',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendRequest(BuildContext context, WidgetRef ref) async {
    try {
      final restClient = ref.read(restClientProvider);
      await restClient.sendFriendRequest(result.username);
      ref.invalidate(_searchResultsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Friend request sent!')));
      }
    } catch (e) {
      debugPrint('[Friends] Failed to send friend request to ${result.username}: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send request: $e')));
      }
    }
  }
}
