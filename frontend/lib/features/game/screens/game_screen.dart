import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/api/websocket_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/card.dart';
import '../../../core/models/game_history_event.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/score_breakdown.dart';
import '../../../shared/utils/card_utils.dart';
import '../state/game_providers.dart';
import '../widgets/crib_area.dart';
import '../widgets/cribbage_board.dart';
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

    // Guard: empty players list
    if (gs.players.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Game')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Invalid game state: no players found.',
                style: TextStyle(color: Colors.redAccent),
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

    final playerId = auth.userId ?? '';
    final playerIndex = gs.players.indexWhere((p) => p.id == playerId);
    final player = playerIndex >= 0 ? gs.players[playerIndex] : gs.players[0];
    final opponent = gs.players[playerIndex >= 0 ? 1 - playerIndex : 1];
    final isMyTurn = gs.currentPlayerId == playerId;
    final isDealer = gs.dealerIndex == playerIndex;
    final cribRevealed =
        gs.stage == GameStage.counting || gs.stage == GameStage.gameOver;

    // Get crib cards: prefer current state, fall back to CribCounted history event
    final cribCards = gs.crib.isNotEmpty
        ? gs.crib
        : gs.history
            .whereType<CribCounted>()
            .lastOrNull
            ?.cribCards ?? const [];
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
            // Reconnecting banner
            if (gameNotifier.connectionStatus == ConnectionStatus.reconnecting)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: Colors.orange.shade800,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Reconnecting...',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            if (gameNotifier.connectionStatus == ConnectionStatus.failed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: Colors.red.shade800,
                child: const Text(
                  'Connection lost. Please go back and rejoin.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            // Scores
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ScoreDisplay(
                player: player,
                opponent: opponent,
                isDealer: isDealer,
              ),
            ),

            // Cribbage Board
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: CribbageBoard(
                playerScore: player.score,
                opponentScore: opponent.score,
                isDealer: isDealer,
              ),
            ),

            // Opponent hand
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: OpponentHand(
                cardCount: opponent.hand.isEmpty ? _estimateOpponentCards(gs, opponent.id) : opponent.hand.length,
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
                      isDealer: isDealer,
                      currentPlayerName: opponent.name,
                      selectedCardCount: selectedCards.length,
                    ),
                    const SizedBox(height: 8),

                    // Center: cut card + crib + play area
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CutCardDisplay(cutCard: gs.cutCard),
                        const SizedBox(width: 16),
                        CribArea(crib: cribCards, revealed: cribRevealed),
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
                      _buildGameOver(context, ref, gs, playerId),

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
              isDiscarding: gameNotifier.isDiscarding,
              canGo: !_canPlayAnyCard(player.hand, gs.peggingCount),
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
                enabled: isMyTurn && !gameNotifier.isDiscarding,
                onCardTap: (index) =>
                    _handleCardTap(context, ref, gs, playerId, index, selectedCards),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _estimateOpponentCards(GameState gs, String opponentId) {
    switch (gs.stage) {
      case GameStage.dealing:
      case GameStage.discardingToCrib:
        return 6;
      case GameStage.cutting:
        return 4;
      case GameStage.pegging:
        // Count cards opponent has played since the last CardsDealt event
        int played = 0;
        for (final event in gs.history.reversed) {
          if (event is CardsDealt) break;
          if (event is CardPlayed && event.playerId == opponentId) played++;
        }
        return (4 - played).clamp(0, 4);
      case GameStage.counting:
      case GameStage.gameOver:
        return 0;
    }
  }

  void _handleCardTap(
    BuildContext context,
    WidgetRef ref,
    GameState gs,
    String playerId,
    int index,
    Set<int> selected,
  ) {
    // Block all card interaction while discard is in flight
    if (ref.read(gameNotifierProvider(gameId)).isDiscarding) return;

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
      if (index >= 0 && index < sorted.length) {
        final card = sorted[index];
        if (card.rank.peggingValue + gs.peggingCount > 31) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('That card would exceed 31. Try another or tap Go.'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ref.read(gameNotifierProvider(gameId).notifier).playCard(card);
        }
      }
    }
  }

  bool _canPlayAnyCard(List<PlayingCard> hand, int peggingCount) {
    return hand.any((card) => card.rank.peggingValue + peggingCount <= 31);
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
    final cardsToDiscard = selected
        .where((idx) => idx < sorted.length)
        .map((idx) => sorted[idx])
        .toList();

    // Clear selection immediately to prevent double-tap
    ref.read(selectedCardsProvider(gameId).notifier).state = {};

    await ref.read(gameNotifierProvider(gameId).notifier).discardCards(cardsToDiscard);
  }

  Widget _buildGameOver(BuildContext context, WidgetRef ref, GameState gs, String playerId) {
    final winner = gs.history.whereType<GameEnded>().firstOrNull;
    final didWin = winner?.winnerPlayerId == playerId;
    final playerIndex = gs.players.indexWhere((p) => p.id == playerId);
    final player = playerIndex >= 0 ? gs.players[playerIndex] : gs.players[0];
    final opponent = gs.players[playerIndex >= 0 ? 1 - playerIndex : 1];
    final margin = (player.score - opponent.score).abs();

    // Get the last counting breakdowns from history
    final handCounts = gs.history.whereType<HandCounted>().toList();
    final cribCounts = gs.history.whereType<CribCounted>().toList();

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
          const SizedBox(height: 8),
          // Final scores
          Text(
            '${player.name}: ${player.score}  -  ${opponent.name}: ${opponent.score}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          if (margin > 0)
            Text(
              didWin ? 'Won by $margin points' : 'Lost by $margin points',
              style: TextStyle(
                color: didWin ? AppTheme.goldAccent.withValues(alpha: 0.8) : Colors.white54,
                fontSize: 14,
              ),
            ),
          // Last round breakdown
          if (handCounts.isNotEmpty || cribCounts.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...handCounts.reversed.take(2).map((e) => Text(
              '${e.playerId == playerId ? "Your hand" : "Opponent hand"}: '
              '${e.totalPoints} pts${_breakdownText(e.scoreBreakdown)}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            )),
            ...cribCounts.reversed.take(1).map((e) => Text(
              'Crib: ${e.totalPoints} pts${_breakdownText(e.scoreBreakdown)}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            )),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _playAgain(context, ref),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Play Again'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => context.go('/'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white38),
                ),
                child: const Text('Home'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _breakdownText(ScoreBreakdown b) {
    final parts = <String>[];
    if (b.fifteens > 0) parts.add('${b.fifteens} fifteens');
    if (b.pairs > 0) parts.add('${b.pairs} pairs');
    if (b.runs > 0) parts.add('${b.runs} runs');
    if (b.flushes > 0) parts.add('${b.flushes} flush');
    if (b.nobs > 0) parts.add('${b.nobs} nobs');
    return parts.isEmpty ? '' : ' (${parts.join(', ')})';
  }

  Future<void> _playAgain(BuildContext context, WidgetRef ref) async {
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
    }
  }
}
