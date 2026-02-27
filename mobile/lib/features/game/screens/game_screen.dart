import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/api/websocket_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/card.dart';
import '../../../core/models/game_history_event.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/player.dart';
import '../../../core/models/score_breakdown.dart';
import '../../../core/services/local_game_history_provider.dart';
import '../../../shared/utils/card_utils.dart';
import '../../../core/services/settings_provider.dart';
import '../state/game_providers.dart';
import '../state/local_game_notifier.dart';
import '../../../shared/utils/responsive.dart';
import '../widgets/crib_area.dart';
import '../widgets/cribbage_board.dart';
import '../widgets/cut_card.dart';
import '../widgets/game_controls.dart';
import '../widgets/hand_fan.dart';
import '../widgets/history_log.dart';
import '../widgets/play_area.dart';
import '../widgets/counting_overlay.dart';
import '../widgets/score_display.dart';
import '../widgets/dev_overlay.dart';
import '../widgets/score_popup_overlay.dart';
import '../widgets/stage_indicator.dart';
import '../widgets/turn_timer.dart';
import '../widgets/vertical_cribbage_board.dart';

/// Tracks which local game IDs have already been saved to history (prevents duplicate saves on rebuild).
final _savedLocalGamesProvider = StateProvider<Set<String>>((ref) => {});

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
    final colors = context.appColors;
    // Guard: stale local game URL after app restart — try to restore from persistence
    if (_isLocal) {
      final service = ref.read(localGameServiceProvider);
      if (!service.hasActiveGame) {
        return _RestoreGuard(gameId: gameId);
      }
    }

    final gameNotifier = _watchState(ref);
    final auth = ref.watch(authProvider);

    if (gameNotifier.isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: colors.gameGradient),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (gameNotifier.error != null && gameNotifier.gameState == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: colors.gameGradient),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    gameNotifier.error!,
                    style: TextStyle(color: colors.error),
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

    // Auto-save completed local games to history
    if (_isLocal && gs.stage == GameStage.gameOver) {
      final savedIds = ref.read(_savedLocalGamesProvider);
      if (!savedIds.contains(gs.gameId)) {
        Future.microtask(() async {
          ref.read(_savedLocalGamesProvider.notifier).state = {...savedIds, gs.gameId};
          final service = ref.read(localGameHistoryServiceProvider);
          await service.saveCompletedGame(gs);
          ref.invalidate(localGameHistoryProvider);
          ref.invalidate(activeLocalGameProvider);

          // If logged in, upload to server immediately
          if (auth.isLoggedIn) {
            final uploadService = ref.read(gameUploadServiceProvider);
            await uploadService.uploadSingleGame(
              gameId: gs.gameId,
              stateJson: _encodeGameState(gs),
              completedAt: DateTime.now().toUtc().toIso8601String(),
            );
            ref.invalidate(localGameHistoryProvider);
          }
        });
      }
    }

    // Auto-save in-progress local games
    if (_isLocal && gs.stage != GameStage.gameOver) {
      final localService = ref.read(localGameServiceProvider);
      if (localService.aiPlayerId != null && localService.difficulty != null) {
        Future.microtask(() {
          ref.read(localGameHistoryServiceProvider).saveActiveGame(
            gs,
            localService.aiPlayerId!,
            localService.difficulty!,
          );
        });
      }
    }

    // Guard: empty players list
    if (gs.players.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: colors.gameGradient),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Invalid game state: no players found.',
                    style: TextStyle(color: colors.error),
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
        : gs.history.whereType<CribCounted>().lastOrNull?.cribCards ?? const [];
    final settings = ref.watch(settingsProvider);
    final selectedCards = ref.watch(selectedCardsProvider(gameId));
    final selectedPeggingCard = ref.watch(selectedPeggingCardProvider(gameId));

    // Auto-go when player can't play during pegging
    if (settings.autoGo &&
        gs.stage == GameStage.pegging &&
        isMyTurn &&
        !_canPlayAnyCard(player.hand, gs.peggingCount)) {
      final goDelay = settings.scaleDuration(const Duration(milliseconds: 500));
      Future.delayed(goDelay, () {
        // Re-read current state to guard against stale/duplicate callbacks
        final current = _isLocal
            ? ref.read(localGameNotifierProvider(gameId))
            : ref.read(gameNotifierProvider(gameId));
        final currentGs = current.gameState;
        if (currentGs == null ||
            currentGs.stage != GameStage.pegging ||
            currentGs.currentPlayerId != playerId) {
          return;
        }

        final n = _readNotifier(ref);
        if (n is GameNotifier) n.sayGo();
        if (n is LocalGameNotifier) n.sayGo();
      });
    }

    // Auto-cut when it's my turn during cutting stage
    if (settings.autoCut &&
        gs.stage == GameStage.cutting &&
        isMyTurn) {
      final cutDelay = settings.scaleDuration(const Duration(milliseconds: 300));
      Future.delayed(cutDelay, () {
        final current = _isLocal
            ? ref.read(localGameNotifierProvider(gameId))
            : ref.read(gameNotifierProvider(gameId));
        final currentGs = current.gameState;
        if (currentGs == null ||
            currentGs.stage != GameStage.cutting ||
            currentGs.currentPlayerId != playerId) {
          return;
        }

        final n = _readNotifier(ref);
        if (n is GameNotifier) n.cutDeck();
        if (n is LocalGameNotifier) n.cutDeck();
      });
    }

    // Auto-deal for local games when it's my turn during dealing stage
    if (settings.autoDeal &&
        _isLocal &&
        gs.stage == GameStage.dealing &&
        isMyTurn) {
      Future.microtask(() {
        final current = ref.read(localGameNotifierProvider(gameId));
        final currentGs = current.gameState;
        if (currentGs == null ||
            currentGs.stage != GameStage.dealing ||
            currentGs.currentPlayerId != playerId) {
          return;
        }

        final n = _readNotifier(ref);
        if (n is LocalGameNotifier) n.deal();
      });
    }

    final isTabletLandscape = Responsive.isTabletLandscape(context);

    // Shared widgets used by both layouts
    Widget buildConnectionBanners() => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (gameNotifier.connectionStatus == ConnectionStatus.reconnecting)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: colors.warning,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.accentOnSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Reconnecting...',
                  style: TextStyle(
                    color: colors.accentOnSurface,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        if (gameNotifier.connectionStatus == ConnectionStatus.failed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: colors.error,
            child: Text(
              'Connection lost. Please go back and rejoin.',
              style: TextStyle(color: colors.accentOnSurface, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );

    Widget buildTimers() => gameNotifier.isTimed
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TurnTimer(
                  turnStartedAt: gameNotifier.turnStartedAt,
                  turnTimeLimitMs: gameNotifier.turnTimeLimitMs,
                  timeBankMs: gameNotifier.opponentTimeBankMs,
                  isActivePlayer: !isMyTurn,
                  isTimed: true,
                ),
                TurnTimer(
                  turnStartedAt: gameNotifier.turnStartedAt,
                  turnTimeLimitMs: gameNotifier.turnTimeLimitMs,
                  timeBankMs: gameNotifier.myTimeBankMs,
                  isActivePlayer: isMyTurn,
                  isTimed: true,
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    Widget buildOpponentHand() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      child: OpponentHand(
        cardCount: opponent.hand.isEmpty
            ? _estimateOpponentCards(gs, opponent.id)
            : opponent.hand.length,
      ),
    );

    Widget buildMiddleArea() => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StageIndicator(
              stage: gs.stage,
              isMyTurn: isMyTurn,
              isDealer: isDealer,
              isLocalGame: _isLocal,
              currentPlayerName: opponent.name,
              selectedCardCount: selectedCards.length,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CutCardDisplay(cutCard: gs.cutCard),
                const SizedBox(width: 8),
                CribArea(crib: cribCards, revealed: cribRevealed),
              ],
            ),
            const SizedBox(height: 6),
            if (gs.stage != GameStage.gameOver)
              Visibility(
                visible: gs.stage == GameStage.pegging,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: PlayArea(
                  playedCards: gs.playedCards,
                  peggingCount: gs.peggingCount,
                ),
              ),
            if (gs.stage == GameStage.gameOver)
              _buildGameOver(context, ref, gs, playerId),
          ],
        ),
      ),
    );

    Widget buildControls() => GameControls(
      stage: gs.stage,
      isMyTurn: isMyTurn,
      selectedCardCount: selectedCards.length,
      isDiscarding: gameNotifier.isDiscarding,
      showCountingOverlay: gs.stage == GameStage.counting && isMyTurn,
      autoDeal: settings.autoDeal,
      autoCut: settings.autoCut,
      autoGo: settings.autoGo,
      autoPlayPegging: settings.autoPlayAll || settings.autoPlayPegging,
      canPlayCard: _canPlayAnyCard(player.hand, gs.peggingCount),
      hasSelectedCard: selectedPeggingCard != null,
      onDiscard: () => _handleDiscard(ref, gs, playerId, selectedCards),
      onCut: () {
        final n = _readNotifier(ref);
        if (n is GameNotifier) n.cutDeck();
        if (n is LocalGameNotifier) n.cutDeck();
      },
      onCount: () {
        final n = _readNotifier(ref);
        if (n is GameNotifier) n.countHand();
        if (n is LocalGameNotifier) n.countHand();
      },
      onDeal: () {
        final n = _readNotifier(ref);
        if (n is LocalGameNotifier) n.deal();
      },
      onGo: () {
        final n = _readNotifier(ref);
        if (n is GameNotifier) n.sayGo();
        if (n is LocalGameNotifier) n.sayGo();
      },
      onPlayCard: () {
        final card = selectedPeggingCard;
        if (card == null) return;
        ref.read(selectedPeggingCardProvider(gameId).notifier).state = null;
        final n = _readNotifier(ref);
        if (n is GameNotifier) n.playCard(card);
        if (n is LocalGameNotifier) n.playCard(card);
      },
    );

    Widget buildPlayerHand() => Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 2, left: 12, right: 12),
      child: HandFan(
        cards: CardUtils.sorted(player.hand),
        selectedIndices: selectedCards,
        enabled: isMyTurn && !gameNotifier.isDiscarding,
        onCardTap: (index) => _handleCardTap(
          context, ref, gs, playerId, index, selectedCards,
        ),
      ),
    );

    List<Widget> buildOverlays() => [
      ScorePopupOverlay(gameId: gameId, playerId: playerId, opponentName: opponent.name),
      if (gs.stage == GameStage.counting && isMyTurn)
        CountingOverlay(
          hand: gs.handsForCounting[playerId] ?? player.hand,
          cutCard: gs.cutCard!,
          crib: isDealer ? gs.crib : [],
          isDealer: isDealer,
          onComplete: () {
            final n = _readNotifier(ref);
            if (n is GameNotifier) n.countHand();
            if (n is LocalGameNotifier) n.countHand();
          },
        ),
      if (kDebugMode && _isLocal)
        DevOverlay(gameId: gameId, playerId: playerId),
    ];

    if (isTabletLandscape) {
      // Tablet landscape: vertical board on left, card play area on right
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: colors.gameGradient),
          child: SafeArea(
            child: Row(
              children: [
                // Left panel: back button, score, stage, vertical board
                SizedBox(
                  width: 120,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: colors.textSecondary, size: 20),
                          onPressed: () => context.go('/'),
                        ),
                      ),
                      ScoreDisplay(
                        player: player,
                        opponent: opponent,
                        isDealer: isDealer,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (gameNotifier.error != null)
                            IconButton(
                              icon: Icon(Icons.warning, color: colors.warning, size: 18),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(gameNotifier.error!)),
                                );
                                final n = _readNotifier(ref);
                                if (n is GameNotifier) n.clearError();
                                if (n is LocalGameNotifier) n.clearError();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          if (!_isLocal && gs.stage != GameStage.gameOver)
                            IconButton(
                              icon: Icon(Icons.flag, color: colors.textTertiary, size: 18),
                              onPressed: () => _confirmResign(context, ref),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          IconButton(
                            icon: Icon(Icons.history, color: colors.textTertiary, size: 18),
                            onPressed: () => _showHistorySheet(context, gs.history, playerId),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: VerticalCribbageBoard(
                            playerScore: player.score,
                            opponentScore: opponent.score,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Right panel: card play area (same widgets, no perimeter board)
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          buildConnectionBanners(),
                          buildTimers(),
                          buildOpponentHand(),
                          buildMiddleArea(),
                          buildControls(),
                          buildPlayerHand(),
                        ],
                      ),
                      ...buildOverlays(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Phone / tablet portrait: original layout with perimeter board
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.gameGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: PerimeterCribbageBoard(
                playerScore: player.score,
                opponentScore: opponent.score,
                isDealer: isDealer,
                child: Stack(
                children: [
                  Column(
                    children: [
                      _TopBar(
                        gameNotifier: gameNotifier,
                        player: player,
                        opponent: opponent,
                        isDealer: isDealer,
                        events: gs.history,
                        playerId: playerId,
                        isOnlineGame: !_isLocal,
                        isGameOver: gs.stage == GameStage.gameOver,
                        onBack: () => context.go('/'),
                        onError: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(gameNotifier.error!)),
                          );
                          final n = _readNotifier(ref);
                          if (n is GameNotifier) n.clearError();
                          if (n is LocalGameNotifier) n.clearError();
                        },
                        onResign: () => _confirmResign(context, ref),
                      ),
                      buildConnectionBanners(),
                      buildTimers(),
                      buildOpponentHand(),
                      buildMiddleArea(),
                      buildControls(),
                      buildPlayerHand(),
                    ],
                  ),
                  ...buildOverlays(),
                ],
              ),
              ),
            ),
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

    final settings = ref.read(settingsProvider);

    if (gs.stage == GameStage.discardingToCrib) {
      if (settings.autoPlayAll) {
        // Auto-play all: tapping toggles selection and auto-submits when 2 selected
        final newSelected = Set<int>.from(selected);
        if (newSelected.contains(index)) {
          newSelected.remove(index);
        } else if (newSelected.length < 2) {
          newSelected.add(index);
        }
        ref.read(selectedCardsProvider(gameId).notifier).state = newSelected;
        if (newSelected.length == 2) {
          _handleDiscard(ref, gs, playerId, newSelected);
        }
      } else {
        // Normal: toggle selection, user must tap Discard button
        final newSelected = Set<int>.from(selected);
        if (newSelected.contains(index)) {
          newSelected.remove(index);
        } else if (newSelected.length < 2) {
          newSelected.add(index);
        }
        ref.read(selectedCardsProvider(gameId).notifier).state = newSelected;
      }
    } else if (gs.stage == GameStage.pegging &&
        gs.currentPlayerId == playerId) {
      final sorted = CardUtils.sorted(
        gs.players.firstWhere((p) => p.id == playerId).hand,
      );
      if (index >= 0 && index < sorted.length) {
        final card = sorted[index];
        if (card.rank.peggingValue + gs.peggingCount > 31) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('That card would exceed 31.'),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (settings.autoPlayAll || settings.autoPlayPegging) {
          // Auto-play: tap immediately plays the card
          final n = _readNotifier(ref);
          if (n is GameNotifier) n.playCard(card);
          if (n is LocalGameNotifier) n.playCard(card);
        } else {
          // Manual: tap selects card, "Play Card" button confirms
          ref.read(selectedPeggingCardProvider(gameId).notifier).state = card;
        }
      }
    }
  }

  void _showHistorySheet(BuildContext context, List<GameHistoryEvent> events, String playerId) {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Game History',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 300,
              child: HistoryLog(events: events, playerId: playerId),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResign(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resign Game?'),
        content: const Text(
          'Are you sure you want to resign? Your opponent will be awarded the win.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final n = _readNotifier(ref);
              if (n is GameNotifier) n.resign();
            },
            style: TextButton.styleFrom(foregroundColor: context.appColors.error),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
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
      gs.players.firstWhere((p) => p.id == playerId).hand,
    );
    final cardsToDiscard = selected
        .where((idx) => idx < sorted.length)
        .map((idx) => sorted[idx])
        .toList();

    ref.read(selectedCardsProvider(gameId).notifier).state = {};

    final n = _readNotifier(ref);
    if (n is GameNotifier) await n.discardCards(cardsToDiscard);
    if (n is LocalGameNotifier) n.discardCards(cardsToDiscard);
  }

  Widget _buildGameOver(
    BuildContext context,
    WidgetRef ref,
    GameState gs,
    String playerId,
  ) {
    final colors = context.appColors;
    final winner = gs.history.whereType<GameEnded>().firstOrNull;
    final didWin = winner?.winnerPlayerId == playerId;
    final playerIndex = gs.players.indexWhere((p) => p.id == playerId);
    final player = playerIndex >= 0 ? gs.players[playerIndex] : gs.players[0];
    final opponent = gs.players[playerIndex >= 0 ? 1 - playerIndex : 1];
    final margin = (player.score - opponent.score).abs();

    final forfeit = gs.history.whereType<GameForfeited>().firstOrNull;
    final handCounts = gs.history.whereType<HandCounted>().toList();
    final cribCounts = gs.history.whereType<CribCounted>().toList();

    String? forfeitText;
    if (forfeit != null) {
      final reason = forfeit.reason;
      final isMe = forfeit.forfeitingPlayerId == playerId;
      forfeitText = switch (reason) {
        'RESIGN' => isMe ? 'You resigned' : 'Opponent resigned',
        'TIMEOUT' => isMe ? 'You ran out of time' : 'Opponent ran out of time',
        'DISCONNECT' => isMe ? 'You disconnected' : 'Opponent disconnected',
        _ => isMe ? 'You forfeited' : 'Opponent forfeited',
      };
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Icon(
            didWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
            size: 32,
            color: didWin ? colors.accent : colors.textDisabled,
          ),
          const SizedBox(height: 4),
          Text(
            didWin ? 'You Win!' : 'You Lose',
            style: TextStyle(
              color: didWin ? colors.accent : colors.textSecondary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (forfeitText != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                forfeitText,
                style: TextStyle(color: colors.textTertiary, fontSize: 13),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            '${player.name}: ${player.score}  -  ${opponent.name}: ${opponent.score}',
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
          ),
          if (margin > 0 && forfeit == null)
            Text(
              didWin ? 'Won by $margin points' : 'Lost by $margin points',
              style: TextStyle(
                color: didWin
                    ? colors.accent.withValues(alpha: 0.8)
                    : colors.textTertiary,
                fontSize: 12,
              ),
            ),
          if (forfeit == null && (handCounts.isNotEmpty || cribCounts.isNotEmpty)) ...[
            const SizedBox(height: 4),
            ...handCounts.reversed
                .take(2)
                .map(
                  (e) => Text(
                    '${e.playerId == playerId ? "Your hand" : "Opponent hand"}: '
                    '${e.totalPoints} pts${_breakdownText(e.scoreBreakdown)}',
                    style: TextStyle(color: colors.textTertiary, fontSize: 11),
                  ),
                ),
            ...cribCounts.reversed
                .take(1)
                .map(
                  (e) => Text(
                    'Crib: ${e.totalPoints} pts${_breakdownText(e.scoreBreakdown)}',
                    style: TextStyle(color: colors.textTertiary, fontSize: 11),
                  ),
                ),
          ],
          const SizedBox(height: 8),
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
                  foregroundColor: colors.textSecondary,
                  side: BorderSide(color: colors.textDisabled),
                ),
                child: const Text('Home'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => context.go('/analysis/${gs.gameId}'),
                icon: const Icon(Icons.analytics, size: 16),
                label: const Text('Analyze'),
                style: TextButton.styleFrom(foregroundColor: colors.textTertiary),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => context.go('/replay/${gs.gameId}'),
                icon: const Icon(Icons.replay, size: 16),
                label: const Text('Replay'),
                style: TextButton.styleFrom(foregroundColor: colors.textTertiary),
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
        debugPrint('[Game] Failed to create AI game: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to create game: $e')));
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
  final bool isOnlineGame;
  final bool isGameOver;
  final VoidCallback onBack;
  final VoidCallback onError;
  final VoidCallback onResign;

  const _TopBar({
    required this.gameNotifier,
    required this.player,
    required this.opponent,
    required this.isDealer,
    required this.events,
    required this.playerId,
    required this.isOnlineGame,
    required this.isGameOver,
    required this.onBack,
    required this.onError,
    required this.onResign,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textSecondary, size: 20),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
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
              icon: Icon(Icons.warning, color: colors.warning, size: 20),
              onPressed: onError,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          if (isOnlineGame && !isGameOver)
            IconButton(
              icon: Icon(Icons.flag, color: colors.textTertiary, size: 20),
              onPressed: onResign,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          IconButton(
            icon: Icon(Icons.history, color: colors.textTertiary, size: 20),
            onPressed: () => _showHistorySheet(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }

  void _showHistorySheet(BuildContext context) {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Game History',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 300,
              child: HistoryLog(events: events, playerId: playerId),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestoreGuard extends ConsumerStatefulWidget {
  final String gameId;

  const _RestoreGuard({required this.gameId});

  @override
  ConsumerState<_RestoreGuard> createState() => _RestoreGuardState();
}

class _RestoreGuardState extends ConsumerState<_RestoreGuard> {
  bool _attempted = false;

  @override
  void initState() {
    super.initState();
    _tryRestore();
  }

  Future<void> _tryRestore() async {
    final historyService = ref.read(localGameHistoryServiceProvider);
    final active = await historyService.getActiveGame();

    if (!mounted) return;

    if (active != null && active.gameState.gameId == widget.gameId) {
      final service = ref.read(localGameServiceProvider);
      service.restoreGame(
        stateJson: active.stateJson,
        aiPlayerId: active.aiPlayerId,
        difficulty: active.difficulty,
      );
      // Force rebuild — the parent GameScreen will now see hasActiveGame == true
      setState(() => _attempted = true);
    } else {
      // No matching active game — redirect home
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (_attempted) {
      // Engine restored — render the real game screen
      return GameScreen(gameId: widget.gameId);
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.gameGradient),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

String _encodeGameState(GameState gs) {
  final json = gs.toJson();
  // Fix empty timestamps from Rust engine for backend Instant compatibility
  final now = DateTime.now().toUtc().toIso8601String();
  if (json['history'] is List) {
    for (final event in json['history'] as List) {
      if (event is Map<String, dynamic>) {
        final ts = event['timestamp'];
        if (ts == null || ts == '') {
          event['timestamp'] = now;
        }
      }
    }
  }
  return jsonEncode(json);
}
