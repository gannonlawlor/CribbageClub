import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/api/websocket_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/card.dart';
import '../../../core/models/game_history_event.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/player.dart';
import '../../../core/models/score_breakdown.dart';
import '../../../shared/utils/card_utils.dart';
import '../state/game_providers.dart';
import '../state/local_game_notifier.dart';
import '../widgets/crib_area.dart';
import '../widgets/cribbage_board.dart';
import '../widgets/cut_card.dart';
import '../widgets/game_controls.dart';
import '../widgets/hand_fan.dart';
import '../widgets/history_log.dart';
import '../widgets/play_area.dart';
import '../widgets/score_display.dart';
import '../widgets/score_popup_overlay.dart';
import '../widgets/stage_indicator.dart';

class GameScreen extends ConsumerWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  bool get _isLocal => isLocalGame(gameId);

  /// Read the notifier state from the correct provider (local vs online).
  GameNotifierState _watchState(WidgetRef ref) {
    return _isLocal
        ? ref.watch(localGameNotifierProvider(gameId))
        : ref.watch(gameNotifierProvider(gameId));
  }

  /// Access the notifier itself.
  StateNotifier<GameNotifierState> _readNotifier(WidgetRef ref) {
    return _isLocal
        ? ref.read(localGameNotifierProvider(gameId).notifier)
        : ref.read(gameNotifierProvider(gameId).notifier);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameNotifier = _watchState(ref);
    final auth = ref.watch(authProvider);

    if (gameNotifier.isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.feltGradient),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (gameNotifier.error != null && gameNotifier.gameState == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.feltGradient),
          child: SafeArea(
            child: Center(
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
          ),
        ),
      );
    }

    final gs = gameNotifier.gameState!;

    // Guard: empty players list
    if (gs.players.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.feltGradient),
          child: SafeArea(
            child: Center(
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
          ),
        ),
      );
    }

    final playerId = _isLocal
        ? gs.players.firstWhere((p) => !p.id.startsWith('ai_')).id
        : (auth.userId ?? '');
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.feltGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Top bar: back + scores + history
                  _TopBar(
                    gameNotifier: gameNotifier,
                    player: player,
                    opponent: opponent,
                    isDealer: isDealer,
                    events: gs.history,
                    playerId: playerId,
                    onBack: () => context.go('/'),
                    onError: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(gameNotifier.error!)),
                      );
                      final n = _readNotifier(ref);
                      if (n is GameNotifier) n.clearError();
                      if (n is LocalGameNotifier) n.clearError();
                    },
                  ),

                  // Reconnecting banner
                  if (gameNotifier.connectionStatus == ConnectionStatus.reconnecting)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.orange.shade800,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Reconnecting...',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  if (gameNotifier.connectionStatus == ConnectionStatus.failed)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.red.shade800,
                      child: const Text(
                        'Connection lost. Please go back and rejoin.',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Cribbage Board (compact)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: CribbageBoard(
                      playerScore: player.score,
                      opponentScore: opponent.score,
                      isDealer: isDealer,
                    ),
                  ),

                  // Opponent hand
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                    child: OpponentHand(
                      cardCount: opponent.hand.isEmpty
                          ? _estimateOpponentCards(gs, opponent.id)
                          : opponent.hand.length,
                    ),
                  ),

                  // Middle area
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Stage indicator (compact pill)
                          StageIndicator(
                            stage: gs.stage,
                            isMyTurn: isMyTurn,
                            isDealer: isDealer,
                            currentPlayerName: opponent.name,
                            selectedCardCount: selectedCards.length,
                          ),
                          const SizedBox(height: 6),

                          // Cut card + crib
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.25,
                                child: CutCardDisplay(cutCard: gs.cutCard),
                              ),
                              const SizedBox(width: 8),
                              CribArea(crib: cribCards, revealed: cribRevealed),
                            ],
                          ),

                          // Play area (if pegging)
                          if (gs.stage == GameStage.pegging) ...[
                            const SizedBox(height: 6),
                            PlayArea(
                              playedCards: gs.playedCards,
                              peggingCount: gs.peggingCount,
                            ),
                          ],

                          // Game over
                          if (gs.stage == GameStage.gameOver)
                            _buildGameOver(context, ref, gs, playerId),
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
                    onCut: () {
                      final n = _readNotifier(ref);
                      if (n is GameNotifier) n.cutDeck();
                      if (n is LocalGameNotifier) n.cutDeck();
                    },
                    onGo: () {
                      final n = _readNotifier(ref);
                      if (n is GameNotifier) n.sayGo();
                      if (n is LocalGameNotifier) n.sayGo();
                    },
                    onCount: () {
                      final n = _readNotifier(ref);
                      if (n is GameNotifier) n.countHand();
                      if (n is LocalGameNotifier) n.countHand();
                    },
                  ),

                  // Player hand
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, top: 2, left: 12, right: 12),
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

              // Score popup overlay
              ScorePopupOverlay(
                gameId: gameId,
                playerId: playerId,
              ),
            ],
          ),
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
    final currentState = _isLocal
        ? ref.read(localGameNotifierProvider(gameId))
        : ref.read(gameNotifierProvider(gameId));
    if (currentState.isDiscarding) return;

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
          final n = _readNotifier(ref);
          if (n is GameNotifier) n.playCard(card);
          if (n is LocalGameNotifier) n.playCard(card);
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

    ref.read(selectedCardsProvider(gameId).notifier).state = {};

    final n = _readNotifier(ref);
    if (n is GameNotifier) await n.discardCards(cardsToDiscard);
    if (n is LocalGameNotifier) await n.discardCards(cardsToDiscard);
  }

  Widget _buildGameOver(BuildContext context, WidgetRef ref, GameState gs, String playerId) {
    final winner = gs.history.whereType<GameEnded>().firstOrNull;
    final didWin = winner?.winnerPlayerId == playerId;
    final playerIndex = gs.players.indexWhere((p) => p.id == playerId);
    final player = playerIndex >= 0 ? gs.players[playerIndex] : gs.players[0];
    final opponent = gs.players[playerIndex >= 0 ? 1 - playerIndex : 1];
    final margin = (player.score - opponent.score).abs();

    final handCounts = gs.history.whereType<HandCounted>().toList();
    final cribCounts = gs.history.whereType<CribCounted>().toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(
            didWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
            size: 40,
            color: didWin ? AppTheme.goldAccent : Colors.white38,
          ),
          const SizedBox(height: 6),
          Text(
            didWin ? 'You Win!' : 'You Lose',
            style: TextStyle(
              color: didWin ? AppTheme.goldAccent : Colors.white70,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${player.name}: ${player.score}  -  ${opponent.name}: ${opponent.score}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (margin > 0)
            Text(
              didWin ? 'Won by $margin points' : 'Lost by $margin points',
              style: TextStyle(
                color: didWin ? AppTheme.goldAccent.withValues(alpha: 0.8) : Colors.white54,
                fontSize: 12,
              ),
            ),
          if (handCounts.isNotEmpty || cribCounts.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...handCounts.reversed.take(2).map((e) => Text(
              '${e.playerId == playerId ? "Your hand" : "Opponent hand"}: '
              '${e.totalPoints} pts${_breakdownText(e.scoreBreakdown)}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            )),
            ...cribCounts.reversed.take(1).map((e) => Text(
              'Crib: ${e.totalPoints} pts${_breakdownText(e.scoreBreakdown)}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            )),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _playAgain(context, ref),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Play Again'),
              ),
              const SizedBox(width: 10),
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
    if (_isLocal) {
      final gs = _watchState(ref).gameState;
      final aiPlayer = gs?.players.firstWhere((p) => p.id.startsWith('ai_'));
      final difficulty = aiPlayer?.name.contains('Medium') == true
          ? 'medium'
          : aiPlayer?.name.contains('Hard') == true
              ? 'hard'
              : 'basic';
      final auth = ref.read(authProvider);
      final service = ref.read(localGameServiceProvider);
      final newState = service.createGame(
        humanPlayerId: auth.userId ?? 'local_player',
        humanPlayerName: auth.username ?? 'Player',
        difficulty: difficulty,
      );
      if (context.mounted) {
        context.go('/game/${newState.gameId}');
      }
    } else {
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
}

/// Compact top bar: back button, score chips, history icon
class _TopBar extends StatelessWidget {
  final GameNotifierState gameNotifier;
  final Player player;
  final Player opponent;
  final bool isDealer;
  final List<GameHistoryEvent> events;
  final String playerId;
  final VoidCallback onBack;
  final VoidCallback onError;

  const _TopBar({
    required this.gameNotifier,
    required this.player,
    required this.opponent,
    required this.isDealer,
    required this.events,
    required this.playerId,
    required this.onBack,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 20),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Expanded(
            child: ScoreDisplay(
              player: player,
              opponent: opponent,
              isDealer: isDealer,
            ),
          ),
          if (gameNotifier.error != null)
            IconButton(
              icon: const Icon(Icons.warning, color: Colors.amber, size: 20),
              onPressed: onError,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white54, size: 20),
            onPressed: () => _showHistorySheet(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.feltGreenDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Game History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 300,
              child: HistoryLog(
                events: events,
                playerId: playerId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
