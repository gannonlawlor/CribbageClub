import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/lobby.dart';
import '../../../shared/widgets/loading_overlay.dart';

final _publicLobbiesProvider = FutureProvider.autoDispose<List<Lobby>>((
  ref,
) async {
  final restClient = ref.read(restClientProvider);
  return restClient.listPublicLobbies();
});

final _isJoiningProvider = StateProvider<bool>((ref) => false);

class LobbyBrowserScreen extends ConsumerWidget {
  const LobbyBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final lobbies = ref.watch(_publicLobbiesProvider);
    final isJoining = ref.watch(_isJoiningProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Lobbies'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_publicLobbiesProvider),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: isJoining,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                Expanded(
                  child: lobbies.when(
                    data: (list) {
                      if (list.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: colors.textDisabled,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No lobbies available',
                                style: TextStyle(
                                  color: colors.textTertiary,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create one or try Quick Game!',
                                style: TextStyle(
                                  color: colors.textDisabled,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(_publicLobbiesProvider);
                          await ref.read(_publicLobbiesProvider.future);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final lobby = list[index];
                            return _LobbyTile(
                              lobby: lobby,
                              onJoin: () => _joinLobby(context, ref, lobby.id),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Failed to load lobbies',
                            style: TextStyle(color: colors.error),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () =>
                                ref.invalidate(_publicLobbiesProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isJoining
                          ? null
                          : () => _createPublicLobby(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Create Public Lobby',
                        style: TextStyle(fontSize: 16),
                      ),
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

  Future<void> _joinLobby(
    BuildContext context,
    WidgetRef ref,
    String lobbyId,
  ) async {
    ref.read(_isJoiningProvider.notifier).state = true;
    try {
      final restClient = ref.read(restClientProvider);
      final result = await restClient.joinLobby(lobbyId);
      if (context.mounted) {
        if (result.gameState != null) {
          context.go('/game/${result.gameState!.gameId}');
        } else {
          context.go('/lobby/${result.lobby.id}');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to join lobby: $e')));
      }
    } finally {
      ref.read(_isJoiningProvider.notifier).state = false;
    }
  }

  Future<void> _createPublicLobby(BuildContext context, WidgetRef ref) async {
    ref.read(_isJoiningProvider.notifier).state = true;
    try {
      final auth = ref.read(authProvider);
      final restClient = ref.read(restClientProvider);
      final lobby = await restClient.createLobby(
        '${auth.username}\'s game',
        isPrivate: false,
      );
      if (context.mounted) {
        context.go('/lobby/${lobby.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create lobby: $e')));
      }
    } finally {
      ref.read(_isJoiningProvider.notifier).state = false;
    }
  }
}

class _LobbyTile extends StatelessWidget {
  final Lobby lobby;
  final VoidCallback onJoin;

  const _LobbyTile({required this.lobby, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final creatorName =
        lobby.players.isNotEmpty ? lobby.players.first.name : 'Unknown';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surfaceDim,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.people, color: colors.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lobby.name,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Created by $creatorName  \u2022  ${lobby.players.length}/${lobby.maxPlayers} players',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Join'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
