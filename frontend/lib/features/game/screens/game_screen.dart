import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/game_history_event.dart';
import '../../../core/models/game_state.dart';
import '../../../shared/utils/card_utils.dart';
import '../state/game_providers.dart';
import '../widgets/crib_area.dart';
import '../widgets/cut_card.dart';
import '../widgets/game_controls.dart';
import '../widgets/hand_fan.dart';
import '../widgets/history_log.dart';
import '../widgets/play_area.dart';
import '../widgets/score_display.dart';
import '../widgets/stage_indicator.dart';

class GameScreen extends ConsumerWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameNotifier = ref.watch(gameNotifierProvider(gameId));
    final auth = ref.watch(authProvider);

    if (gameNotifier.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (gameNotifier.error != null && gameNotifier.gameState == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Game')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                gameNotifier.error!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    final gs = gameNotifier.gameState!;
    final playerId = auth.userId ?? '';
    final playerIndex = gs.players.indexWhere((p) => p.id == playerId);
    final player = playerIndex >= 0 ? gs.players[playerIndex] : gs.players[0];
    final opponent = gs.players[playerIndex >= 0 ? 1 - playerIndex : 1];
    final isMyTurn = gs.currentPlayerId == playerId;
    final isDealer = gs.dealerIndex == playerIndex;
    final cribRevealed =
        gs.stage == GameStage.counting || gs.stage == GameStage.gameOver;
    final selectedCards = ref.watch(selectedCardsProvider(gameId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text('Game - ${gs.stage.displayName}'),
        actions: [
          if (gameNotifier.error != null)
            IconButton(
              icon: const Icon(Icons.warning, color: Colors.amber),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(gameNotifier.error!)),
                );
                ref.read(gameNotifierProvider(gameId).notifier).clearError();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scores
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ScoreDisplay(
                player: player,
                opponent: opponent,
                isDealer: isDealer,
              ),
            ),

            // Opponent hand
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: OpponentHand(
                cardCount: opponent.hand.isEmpty ? _estimateOpponentCards(gs) : opponent.hand.length,
              ),
            ),

            // Middle area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stage indicator
                    StageIndicator(
                      stage: gs.stage,
                      isMyTurn: isMyTurn,
                      currentPlayerName: opponent.name,
                    ),
                    const SizedBox(height: 8),

                    // Center: cut card + crib + play area
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CutCardDisplay(cutCard: gs.cutCard),
                        const SizedBox(width: 16),
                        CribArea(crib: gs.crib, revealed: cribRevealed),
                      ],
                    ),

                    if (gs.stage == GameStage.pegging) ...[
                      const SizedBox(height: 8),
                      PlayArea(
                        playedCards: gs.playedCards,
                        peggingCount: gs.peggingCount,
                      ),
                    ],

                    // Game over
                    if (gs.stage == GameStage.gameOver)
                      _buildGameOver(context, gs, playerId),

                    // History
                    const SizedBox(height: 8),
                    Expanded(
                      child: HistoryLog(
                        events: gs.history,
                        playerId: playerId,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Controls
            GameControls(
              stage: gs.stage,
              isMyTurn: isMyTurn,
              selectedCardCount: selectedCards.length,
              onDiscard: () => _handleDiscard(ref, gs, playerId, selectedCards),
              onCut: () =>
                  ref.read(gameNotifierProvider(gameId).notifier).cutDeck(),
              onGo: () =>
                  ref.read(gameNotifierProvider(gameId).notifier).sayGo(),
              onCount: () =>
                  ref.read(gameNotifierProvider(gameId).notifier).countHand(),
            ),

            // Player hand
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: HandFan(
                cards: CardUtils.sorted(player.hand),
                selectedIndices: selectedCards,
                enabled: isMyTurn,
                onCardTap: (index) =>
                    _handleCardTap(ref, gs, playerId, index, selectedCards),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _estimateOpponentCards(GameState gs) {
    // Opponent hand is filtered to empty by backend.
    // Estimate based on game stage.
    switch (gs.stage) {
      case GameStage.dealing:
      case GameStage.discardingToCrib:
        return 6;
      case GameStage.cutting:
      case GameStage.pegging:
        return 4;
      case GameStage.counting:
      case GameStage.gameOver:
        return 0;
    }
  }

  void _handleCardTap(
    WidgetRef ref,
    GameState gs,
    String playerId,
    int index,
    Set<int> selected,
  ) {
    if (gs.stage == GameStage.discardingToCrib) {
      final newSelected = Set<int>.from(selected);
      if (newSelected.contains(index)) {
        newSelected.remove(index);
      } else if (newSelected.length < 2) {
        newSelected.add(index);
      }
      ref.read(selectedCardsProvider(gameId).notifier).state = newSelected;
    } else if (gs.stage == GameStage.pegging && gs.currentPlayerId == playerId) {
      final sorted = CardUtils.sorted(
          gs.players.firstWhere((p) => p.id == playerId).hand);
      if (index < sorted.length) {
        ref.read(gameNotifierProvider(gameId).notifier).playCard(sorted[index]);
      }
    }
  }

  Future<void> _handleDiscard(
    WidgetRef ref,
    GameState gs,
    String playerId,
    Set<int> selected,
  ) async {
    if (selected.length != 2) return;

    final sorted = CardUtils.sorted(
        gs.players.firstWhere((p) => p.id == playerId).hand);
    final sortedIndices = selected.toList()..sort((a, b) => b.compareTo(a));
    final notifier = ref.read(gameNotifierProvider(gameId).notifier);

    for (final idx in sortedIndices) {
      if (idx < sorted.length) {
        await notifier.discardCard(sorted[idx]);
      }
    }

    ref.read(selectedCardsProvider(gameId).notifier).state = {};
  }

  Widget _buildGameOver(BuildContext context, GameState gs, String playerId) {
    final winner = gs.history.whereType<GameEnded>().firstOrNull;
    final didWin = winner?.winnerPlayerId == playerId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(
            didWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
            size: 48,
            color: didWin ? AppTheme.goldAccent : Colors.white38,
          ),
          const SizedBox(height: 8),
          Text(
            didWin ? 'You Win!' : 'You Lose',
            style: TextStyle(
              color: didWin ? AppTheme.goldAccent : Colors.white70,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
