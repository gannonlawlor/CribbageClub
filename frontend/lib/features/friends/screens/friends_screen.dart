import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/friend.dart';
import '../../../core/models/lobby.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.goldAccent,
          labelColor: AppTheme.goldAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
            Tab(text: 'Find'),
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
    final friends = ref.watch(_friendsProvider);

    return friends.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    'No friends yet',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Use the Find tab to search for players',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
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
          style: const TextStyle(color: Colors.redAccent),
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
    return Dismissible(
      key: Key(friend.friendshipId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.withValues(alpha: 0.3),
        child: const Icon(Icons.person_remove, color: Colors.redAccent),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.feltGreenDark,
            title: const Text(
              'Remove Friend',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Remove ${friend.displayName ?? friend.username} from your friends?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.redAccent),
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
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to remove friend: $e')),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: friend.isOnline ? Colors.greenAccent : Colors.white24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName ?? friend.username,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    if (friend.displayName != null)
                      Text(
                        friend.username,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _challengeFriend(context, ref),
                icon: const Icon(Icons.sports_esports, size: 16),
                label: const Text('Challenge'),
                style: ElevatedButton.styleFrom(
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
    );
  }

  Future<void> _challengeFriend(BuildContext context, WidgetRef ref) async {
    try {
      final restClient = ref.read(restClientProvider);
      final lobby = await restClient.createChallenge(friend.userId);
      if (context.mounted) {
        context.go('/lobby/${lobby.id}');
      }
    } catch (e) {
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
    final requests = ref.watch(_incomingRequestsProvider);
    final challenges = ref.watch(_incomingChallengesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Incoming friend requests
          const Text(
            'Friend Requests',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          requests.when(
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No pending requests',
                    style: TextStyle(color: Colors.white38),
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
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),

          const SizedBox(height: 24),

          // Incoming challenges
          const Text(
            'Challenges',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          challenges.when(
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No pending challenges',
                    style: TextStyle(color: Colors.white38),
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
              style: const TextStyle(color: Colors.redAccent),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.person_add, color: AppTheme.goldAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.fromDisplayName ?? request.fromUsername,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  if (request.fromDisplayName != null)
                    Text(
                      request.fromUsername,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.greenAccent),
              onPressed: () => _accept(context, ref),
              tooltip: 'Accept',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent),
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
    } catch (e) {
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to decline: $e')));
      }
    }
  }
}

class _ChallengeTile extends ConsumerWidget {
  final Lobby challenge;
  const _ChallengeTile({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengerName = challenge.players.isNotEmpty
        ? challenge.players.first.name
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.sports_esports,
              color: AppTheme.goldAccent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$challengerName wants to play!',
                style: const TextStyle(color: Colors.white, fontSize: 14),
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
              child: const Text(
                'Decline',
                style: TextStyle(color: Colors.white54, fontSize: 12),
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
    } catch (e) {
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
            decoration: const InputDecoration(
              hintText: 'Search by username...',
              hintStyle: TextStyle(color: Colors.white38),
              prefixIcon: Icon(Icons.search, color: Colors.white38),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white10,
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        if (query.length < 2 && query.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Type at least 2 characters to search',
              style: TextStyle(color: Colors.white38),
            ),
          ),
        Expanded(
          child: results.when(
            data: (list) {
              if (list.isEmpty && query.length >= 2) {
                return const Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(color: Colors.white54),
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
                style: const TextStyle(color: Colors.redAccent),
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
    final statusLabel = switch (result.relationshipStatus) {
      'FRIENDS' => 'Friends',
      'PENDING_SENT' => 'Request Sent',
      'PENDING_RECEIVED' => 'Pending',
      _ => null,
    };
    final canAdd = result.relationshipStatus == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.displayName ?? result.username,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  if (result.displayName != null)
                    Text(
                      result.username,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (statusLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white10,
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            if (canAdd)
              IconButton(
                icon: const Icon(Icons.person_add, color: AppTheme.goldAccent),
                onPressed: () => _sendRequest(context, ref),
                tooltip: 'Add Friend',
              ),
          ],
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
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send request: $e')));
      }
    }
  }
}
