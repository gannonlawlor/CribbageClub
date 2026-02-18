import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/widgets/loading_overlay.dart';

final _isCreatingGameProvider = StateProvider<bool>((ref) => false);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isCreating = ref.watch(_isCreatingGameProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cribbage Club'),
        actions: [
          if (auth.username != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  auth.username!,
                  style: const TextStyle(color: AppTheme.goldAccent),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: isCreating,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.style,
                    size: 100,
                    color: AppTheme.goldAccent,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: isCreating
                          ? null
                          : () => _createAIGame(context, ref),
                      icon: const Icon(Icons.smart_toy, size: 24),
                      label: const Text(
                        'Play vs AI',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: null, // Phase 2
                      icon: const Icon(Icons.people, size: 24),
                      label: const Text(
                        'Find Match',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white38,
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Multiplayer coming soon',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createAIGame(BuildContext context, WidgetRef ref) async {
    ref.read(_isCreatingGameProvider.notifier).state = true;
    try {
      final restClient = ref.read(restClientProvider);
      final gameState = await restClient.createAIGame();
      if (context.mounted) {
        context.go('/game/${gameState.gameId}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create game: $e')),
        );
      }
    } finally {
      ref.read(_isCreatingGameProvider.notifier).state = false;
    }
  }
}
