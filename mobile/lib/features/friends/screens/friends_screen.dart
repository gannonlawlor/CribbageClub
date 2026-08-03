import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/friend.dart';
import '../../../core/models/lobby.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/services/achievement_service.dart';
import '../../../shared/widgets/cc_buttons.dart';
import '../../../shared/widgets/cc_dialog.dart';
import '../../../shared/widgets/cc_field.dart';
import '../../../shared/widgets/cc_screen.dart';
import '../../../shared/widgets/cc_swipe_back.dart';
import '../../../shared/utils/navigation.dart';

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

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final notifCount = ref.watch(notificationCountProvider);
    final total = notifCount.whenOrNull(data: (n) => n.total) ?? 0;

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
                    title: 'Friends',
                    onBack: () => context.backOrHome(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: CcSegmented(
                      labels: const ['Club', 'Requests', 'Find'],
                      badges: [null, total, null],
                      selected: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _tab,
                      // Keeps the search field and its results alive across
                      // tab switches.
                      children: const [_ClubTab(), _RequestsTab(), _FindTab()],
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

// ──────────────────────────────────────────
// Tab 1: Your club
// ──────────────────────────────────────────
class _ClubTab extends ConsumerWidget {
  const _ClubTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(_friendsProvider);

    return friends.when(
      data: (unsorted) {
        // Online first, then alphabetical
        final list = [...unsorted]
          ..sort((a, b) {
            if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
            final nameA = (a.displayName ?? a.username).toLowerCase();
            final nameB = (b.displayName ?? b.username).toLowerCase();
            return nameA.compareTo(nameB);
          });

        if (list.isEmpty) {
          return const CcMessage(
            title: 'No club members yet',
            detail: 'Find a player by username to send the first request.',
          );
        }

        final online = list.where((f) => f.isOnline).length;

        return RefreshIndicator(
          color: context.appColors.accent,
          onRefresh: () async {
            ref.invalidate(_friendsProvider);
            await ref.read(_friendsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            children: [
              CcSectionCaption(
                online > 0
                    ? '${list.length} members · $online online'
                    : '${list.length} member${list.length == 1 ? '' : 's'}',
              ),
              CcPanel(rows: [for (final f in list) _FriendRow(friend: f)]),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          CcMessage(title: 'Friends unavailable', detail: '$error'),
    );
  }
}

class _FriendRow extends ConsumerWidget {
  final FriendInfo friend;
  const _FriendRow({required this.friend});

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
        color: colors.error.withValues(alpha: 0.25),
        child: Icon(Icons.person_remove, size: 18, color: colors.error),
      ),
      confirmDismiss: (_) => _confirmRemove(context, name),
      onDismissed: (_) async {
        try {
          final restClient = ref.read(restClientProvider);
          await restClient.removeFriend(friend.friendshipId);
          ref.invalidate(_friendsProvider);
        } catch (e) {
          debugPrint('[Friends] Failed to remove friend: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not remove $name: $e')),
            );
          }
        }
      },
      child: InkWell(
        onTap: () => context.push('/profile/${friend.userId}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              CcAvatar(name: name, size: 34, isOnline: friend.isOnline),
              const SizedBox(width: 12),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      friend.isOnline ? 'Online' : '@${friend.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: friend.isOnline
                            ? colors.accent
                            : colors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              CcSecondaryButton(
                label: 'Challenge',
                height: 32,
                fontSize: 12,
                onPressed: () => _challenge(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmRemove(BuildContext context, String name) async {
    final colors = context.appColors;
    final result = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: 'Remove $name?',
        showCloseButton: false,
        actions: [
          CcSecondaryButton(
            label: 'Remove',
            labelColor: colors.error,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
          CcPrimaryButton(
            label: 'Keep',
            height: 44,
            fontSize: 14,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ],
        child: Text(
          'They leave your club. You can send a new request later.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _challenge(BuildContext context, WidgetRef ref) async {
    try {
      final restClient = ref.read(restClientProvider);
      final lobby = await restClient.createChallenge(friend.userId);
      if (context.mounted) context.push('/lobby/${lobby.id}');
    } catch (e) {
      debugPrint('[Friends] Failed to create challenge: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send the challenge: $e')),
        );
      }
    }
  }
}

// ──────────────────────────────────────────
// Tab 2: Challenges + requests
// ──────────────────────────────────────────
class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final requests = ref.watch(_incomingRequestsProvider);
    final outgoing = ref.watch(_outgoingRequestsProvider);
    final challenges = ref.watch(_incomingChallengesProvider);

    final challengeList = challenges.valueOrNull ?? const <Lobby>[];
    final requestList = requests.valueOrNull ?? const <FriendRequestInfo>[];
    final sentList = outgoing.valueOrNull ?? const <FriendRequestInfo>[];

    if (challenges.isLoading && requests.isLoading && outgoing.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (challengeList.isEmpty && requestList.isEmpty && sentList.isEmpty) {
      return const CcMessage(
        title: 'Nothing waiting',
        detail: 'Challenges and friend requests land here.',
      );
    }

    return RefreshIndicator(
      color: colors.accent,
      onRefresh: () async {
        ref.invalidate(_incomingChallengesProvider);
        ref.invalidate(_incomingRequestsProvider);
        ref.invalidate(_outgoingRequestsProvider);
        await ref.read(_incomingChallengesProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          // Challenges first — they're the ones with a game behind them.
          if (challengeList.isNotEmpty) ...[
            const CcSectionCaption('Challenges'),
            CcPanel(
              rows: [
                for (final c in challengeList) _ChallengeRow(challenge: c),
              ],
            ),
            const SizedBox(height: 20),
          ],
          if (requestList.isNotEmpty) ...[
            const CcSectionCaption('Friend requests'),
            CcPanel(
              rows: [for (final r in requestList) _RequestRow(request: r)],
            ),
            const SizedBox(height: 20),
          ],
          if (sentList.isNotEmpty) ...[
            const CcSectionCaption('Sent'),
            CcPanel(rows: [for (final r in sentList) _SentRow(request: r)]),
          ],
        ],
      ),
    );
  }
}

class _ChallengeRow extends ConsumerWidget {
  final Lobby challenge;
  const _ChallengeRow({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final name = challenge.players.isNotEmpty
        ? challenge.players.first.name
        : 'A player';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          CcAvatar(name: name, size: 34),
          const SizedBox(width: 12),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Wants a game',
                  style: TextStyle(color: colors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _IconAction(
            icon: Icons.close,
            tooltip: 'Decline',
            color: colors.textTertiary,
            onPressed: () => _decline(context, ref),
          ),
          const SizedBox(width: 6),
          CcPrimaryButton(
            label: 'Accept',
            height: 32,
            fontSize: 12,
            onPressed: () => _accept(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    try {
      final restClient = ref.read(restClientProvider);
      final result = await restClient.acceptChallenge(challenge.id);
      if (context.mounted) {
        if (result.gameState != null) {
          context.push('/game/${result.gameState!.gameId}');
        } else {
          context.push('/lobby/${result.lobby.id}');
        }
      }
    } catch (e) {
      debugPrint('[Friends] Failed to accept challenge ${challenge.id}: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not accept the challenge: $e')),
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
          SnackBar(content: Text('Could not decline the challenge: $e')),
        );
      }
    }
  }
}

class _RequestRow extends ConsumerWidget {
  final FriendRequestInfo request;
  const _RequestRow({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final name = request.fromDisplayName ?? request.fromUsername;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          CcAvatar(name: name, size: 34),
          const SizedBox(width: 12),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '@${request.fromUsername}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _IconAction(
            icon: Icons.close,
            tooltip: 'Decline',
            color: colors.textTertiary,
            onPressed: () => _decline(context, ref),
          ),
          const SizedBox(width: 6),
          CcPrimaryButton(
            label: 'Accept',
            height: 32,
            fontSize: 12,
            onPressed: () => _accept(context, ref),
          ),
        ],
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
      // Accepting can unlock Making Friends for both parties.
      ref.read(achievementSyncServiceProvider).sync();
    } catch (e) {
      debugPrint('[Friends] Failed to accept friend request: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not accept: $e')));
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
        ).showSnackBar(SnackBar(content: Text('Could not decline: $e')));
      }
    }
  }
}

class _SentRow extends StatelessWidget {
  final FriendRequestInfo request;
  const _SentRow({required this.request});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Outgoing requests reuse the same model; fromUsername is the recipient
    final name = request.fromDisplayName ?? request.fromUsername;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CcAvatar(name: name, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const CcChip(label: 'PENDING'),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Tab 3: Find players
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
      if (mounted) {
        ref.read(_searchQueryProvider.notifier).state = value.trim();
      }
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            style: TextStyle(color: colors.textPrimary, fontSize: 15),
            decoration: CcTextField.decoration(colors, 'Search by username')
                .copyWith(
                  prefixIcon: Icon(
                    Icons.search,
                    size: 19,
                    color: colors.textTertiary,
                  ),
                ),
          ),
        ),
        Expanded(
          child: query.length < 2
              ? CcMessage(
                  title: query.isEmpty ? 'Find a player' : 'Keep typing',
                  detail: query.isEmpty
                      ? 'Search by username to send a friend request.'
                      : 'Two characters or more.',
                )
              : results.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return CcMessage(
                        title: 'No players match “$query”',
                        detail: 'Usernames must match exactly.',
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      children: [
                        CcPanel(
                          rows: [for (final r in list) _SearchRow(result: r)],
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      CcMessage(title: 'Search failed', detail: '$e'),
                ),
        ),
      ],
    );
  }
}

class _SearchRow extends ConsumerWidget {
  final UserSearchResult result;
  const _SearchRow({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final name = result.displayName ?? result.username;
    final status = switch (result.relationshipStatus) {
      'FRIENDS' => 'IN YOUR CLUB',
      'PENDING_SENT' => 'REQUESTED',
      'PENDING_RECEIVED' => 'AWAITING YOU',
      _ => null,
    };
    final canAdd = result.relationshipStatus == null;

    return InkWell(
      onTap: () => context.push('/profile/${result.userId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            CcAvatar(name: name, size: 34),
            const SizedBox(width: 12),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (result.displayName != null)
                    Text(
                      '@${result.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (status != null) CcChip(label: status),
            if (canAdd)
              CcSecondaryButton(
                label: 'Add',
                height: 32,
                fontSize: 12,
                onPressed: () => _sendRequest(context, ref),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent to ${result.username}.')),
        );
      }
    } catch (e) {
      debugPrint(
        '[Friends] Failed to send friend request to ${result.username}: $e',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not send request: $e')));
      }
    }
  }
}

/// Compact tertiary icon button used beside the accept CTAs.
class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
