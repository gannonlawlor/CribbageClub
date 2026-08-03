import 'dart:convert';
import 'dart:math' as math;

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
import '../../../core/models/score_breakdown.dart';
import '../../../core/services/achievement_service.dart';
import '../../../core/services/local_game_history_provider.dart';
import '../../profile/state/my_profile_provider.dart';
import '../../../shared/utils/card_utils.dart';
import '../../../shared/utils/forfeit_text.dart';
import '../../../core/services/settings_provider.dart';
import '../state/game_providers.dart';
import '../state/local_game_notifier.dart';
import '../../../config/constants.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/cc_buttons.dart';
import '../../../shared/widgets/cc_dialog.dart';
import '../widgets/card_widget.dart';
import '../widgets/count_block.dart';
import '../widgets/crib_area.dart';
import '../widgets/cut_card.dart';
import '../widgets/cut_for_deal_overlay.dart';
import '../widgets/discard_flight.dart';
import '../widgets/opponent_deal_flight.dart';
import '../widgets/game_controls.dart';
import '../widgets/game_icon_button.dart';
import '../widgets/game_settings_sheet.dart';
import '../widgets/hand_fan.dart';
import '../widgets/history_log.dart';
import '../widgets/pegging_pile.dart';
import '../widgets/perimeter_board.dart';
import '../widgets/play_area.dart';
import '../widgets/player_bar.dart';
import '../widgets/counting_overlay.dart';
import '../widgets/score_display.dart';
import '../widgets/dev_overlay.dart';
import '../widgets/score_popup_overlay.dart';
import '../widgets/stage_indicator.dart';
import '../widgets/starter_crib.dart';
import '../widgets/turn_timer.dart';
import '../widgets/vertical_cribbage_board.dart';
import '../../../shared/utils/navigation.dart';

/// Tracks which local game IDs have already been saved to history (prevents duplicate saves on rebuild).
final _savedLocalGamesProvider = StateProvider<Set<String>>((ref) => {});

/// Anchors the discard flight measures itself against, plus the counter that
/// launches it. Kept per game so the keys survive rebuilds.
class _FlightAnchors {
  final stack = GlobalKey();
  final hand = GlobalKey();
  final crib = GlobalKey();
}

final _flightAnchorsProvider = Provider.family<_FlightAnchors, String>(
  (ref, gameId) => _FlightAnchors(),
);

/// Bumped each time the player throws to the crib.
final _discardTokenProvider = StateProvider.family<int, String>((ref, _) => 0);

/// Whether this game's opening cut-for-deal has been shown. The ceremony is
/// presentation only — the engine decided the dealer at creation — so one
/// showing per game is all it gets.
final _cutForDealDoneProvider = StateProvider.family<bool, String>(
  (ref, _) => false,
);

/// True while the player is calling the count themselves. The choice between
/// counting and being counted for now lives on the game screen, so the panel
/// only opens once they've asked for it.
final _manualCountProvider = StateProvider.family<bool, String>(
  (ref, _) => false,
);

/// True when the dealer has counted their hand this round but not yet their
/// crib — the window where the crib is theirs to count. Derived from history
/// so it always agrees with the engine.
bool _cribCountPending(GameState gs, String dealerId) {
  for (final e in gs.history.reversed) {
    if (e is RoundStarted) return false;
    if (e is CribCounted) return false;
    if (e is HandCounted && e.playerId == dealerId) return true;
  }
  return false;
}

/// Horizontal inset that keeps the table clear of the perimeter track.
const double _sideInset = 40;

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
                    onPressed: () => context.backOrHome(),
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
          ref.read(_savedLocalGamesProvider.notifier).state = {
            ...savedIds,
            gs.gameId,
          };
          final service = ref.read(localGameHistoryServiceProvider);
          await service.saveCompletedGame(gs);
          ref.invalidate(localGameHistoryProvider);
          ref.invalidate(activeLocalGameProvider);

          // If logged in, upload to server immediately
          if (auth.isLoggedIn) {
            final uploadService = ref.read(gameUploadServiceProvider);
            final uploaded = await uploadService.uploadSingleGame(
              gameId: gs.gameId,
              stateJson: _encodeGameState(gs),
              completedAt: DateTime.now().toUtc().toIso8601String(),
            );
            ref.invalidate(localGameHistoryProvider);
            // The server records the result on import, so the profile's
            // rating and record are stale the moment this lands.
            if (uploaded) {
              ref.invalidate(myProfileProvider);
              // The import may have unlocked achievements server-side.
              await ref.read(achievementSyncServiceProvider).sync();
            }
          }
        });
      }
    }

    // Online games: the server evaluates achievements at game over; one sync
    // when this game first shows as finished picks the new unlocks up. The
    // saved-set guard keeps it to once per game.
    if (!_isLocal && gs.stage == GameStage.gameOver && auth.isLoggedIn) {
      final savedIds = ref.read(_savedLocalGamesProvider);
      if (!savedIds.contains(gs.gameId)) {
        Future.microtask(() {
          ref.read(_savedLocalGamesProvider.notifier).state = {
            ...ref.read(_savedLocalGamesProvider),
            gs.gameId,
          };
          ref.read(achievementSyncServiceProvider).sync();
        });
      }
    }

    // Auto-save in-progress local games
    if (_isLocal && gs.stage != GameStage.gameOver) {
      final localService = ref.read(localGameServiceProvider);
      if (localService.aiPlayerId != null && localService.difficulty != null) {
        Future.microtask(() {
          ref
              .read(localGameHistoryServiceProvider)
              .saveActiveGame(
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
                    onPressed: () => context.backOrHome(),
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
    // The crib is never turned face up on the table — not during the count,
    // not for either player's crib. It's scored into the history (with its
    // cards) and otherwise stays a face-down stack under its CRIB label.
    const cribRevealed = false;

    // Get crib cards: prefer current state, fall back to CribCounted history event
    final cribCards = gs.crib.isNotEmpty
        ? gs.crib
        : gs.history.whereType<CribCounted>().lastOrNull?.cribCards ?? const [];
    final settings = ref.watch(settingsProvider);
    final anchors = ref.watch(_flightAnchorsProvider(gameId));
    final discardToken = ref.watch(_discardTokenProvider(gameId));
    final selectedCards = ref.watch(selectedCardsProvider(gameId));
    final selectedPeggingCard = ref.watch(selectedPeggingCardProvider(gameId));

    // Counting happens on the table now: pegging empties `player.hand`, so the
    // four cards being counted come from the engine's counting snapshot.
    final isCounting = gs.stage == GameStage.counting;
    final countingHand = gs.handsForCounting[playerId] ?? const <PlayingCard>[];
    final manualCount = ref.watch(_manualCountProvider(gameId));

    // The dealer counts hand then crib as two engine actions; between them the
    // engine leaves it the dealer's turn with their hand counted and the crib
    // not, which is exactly what this reads back from the history.
    final dealerId = gs.players.isNotEmpty
        ? gs.players[gs.dealerIndex.clamp(0, gs.players.length - 1)].id
        : '';
    final cribPending = isCounting && _cribCountPending(gs, dealerId);
    final countingCrib = cribPending && isMyTurn && isDealer;
    final showCountingPanel = isCounting && isMyTurn && manualCount;

    // Score the step the player is on: the crib once their hand is done,
    // otherwise the hand.
    void applyCount() {
      final n = _readNotifier(ref);
      if (countingCrib) {
        if (n is GameNotifier) n.countCrib();
        if (n is LocalGameNotifier) n.countCrib();
      } else {
        if (n is GameNotifier) n.countHand();
        if (n is LocalGameNotifier) n.countHand();
      }
    }

    // The opening cut-for-deal: shown once, before the first hand appears.
    // Timed games skip the ceremony — it would burn the discard clock.
    final cutForDealDone = ref.watch(_cutForDealDoneProvider(gameId));
    final isFirstRound = !gs.history.any(
      (e) => e is RoundStarted && e.roundNumber > 1,
    );
    final showCutForDeal =
        !cutForDealDone &&
        !gameNotifier.isTimed &&
        isFirstRound &&
        (gs.stage == GameStage.dealing ||
            gs.stage == GameStage.discardingToCrib) &&
        player.hand.length == 6;

    // A pegging selection only survives while it's still playable: the stage
    // moves on, the card gets played, or the count outgrows it — it clears.
    if (selectedPeggingCard != null &&
        (gs.stage != GameStage.pegging ||
            !player.hand.contains(selectedPeggingCard) ||
            selectedPeggingCard.rank.peggingValue + gs.peggingCount > 31)) {
      Future.microtask(() {
        ref.read(selectedPeggingCardProvider(gameId).notifier).state = null;
      });
    }

    // Every card played since the last deal, oldest first. The engine clears
    // its pile at 31 or a go; the difference between this list and the live
    // pile is the spent cards we keep on the table, faded.
    final roundPlays = <CardPlayed>[];
    if (gs.stage == GameStage.pegging) {
      for (final event in gs.history.reversed) {
        if (event is CardsDealt) break;
        if (event is CardPlayed) roundPlays.insert(0, event);
      }
    }
    final spentPileCount = math.max(
      0,
      roundPlays.length - gs.playedCards.length,
    );

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
    if (settings.autoCut && gs.stage == GameStage.cutting && isMyTurn) {
      final cutDelay = settings.scaleDuration(
        const Duration(milliseconds: 300),
      );
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

    // The perimeter board needs a tall viewport; anything shorter (a phone
    // turned landscape) gets the side-panel layout with the vertical board.
    final isTabletLandscape =
        Responsive.isTabletLandscape(context) ||
        MediaQuery.of(context).size.height < 620;

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
                  style: TextStyle(color: colors.accentOnSurface, fontSize: 12),
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

    // Portrait: each clock hugs its owner's bar (opponent's just below theirs,
    // yours just above yours) so whose time is running is never ambiguous.
    Widget buildBarTimer({required bool mine}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: _sideInset),
      child: Align(
        alignment: Alignment.centerRight,
        child: TurnTimer(
          turnStartedAt: gameNotifier.turnStartedAt,
          turnTimeLimitMs: gameNotifier.turnTimeLimitMs,
          timeBankMs: mine
              ? gameNotifier.myTimeBankMs
              : gameNotifier.opponentTimeBankMs,
          isActivePlayer: mine ? isMyTurn : !isMyTurn,
          isTimed: true,
        ),
      ),
    );

    Widget buildOpponentHand() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      child: OpponentHand(
        cardCount: showCutForDeal
            ? 0
            : opponent.hand.isEmpty
            ? _estimateOpponentCards(gs, opponent.id)
            : opponent.hand.length,
        receiveFirst: isDealer,
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
                  previousCards: [
                    for (int i = 0; i < spentPileCount; i++) roundPlays[i].card,
                  ],
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
      showCountingOverlay: showCountingPanel,
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
      onCount: applyCount,
      onManualCount: () {
        ref.read(_manualCountProvider(gameId).notifier).state = true;
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

    // During the count the hand slot shows what's being counted: the crib
    // once it's the dealer's turn for it, otherwise the counting hand.
    final sortedHand = CardUtils.sorted(
      countingCrib
          ? gs.crib
          : isCounting && countingHand.isNotEmpty
          ? countingHand
          : player.hand,
    );

    // Cards that would bust 31 read as unavailable during pegging.
    final dimmedHandCards = <int>{
      if (gs.stage == GameStage.pegging)
        for (int i = 0; i < sortedHand.length; i++)
          if (sortedHand[i].rank.peggingValue + gs.peggingCount > 31) i,
    };

    // With manual pegging the tapped card raises like a discard pick, so the
    // Play button always has a visible subject.
    final selectedPeggingIndex =
        gs.stage == GameStage.pegging && selectedPeggingCard != null
        ? sortedHand.indexOf(selectedPeggingCard)
        : -1;

    Widget buildHand({double horizontalPadding = 12}) => Padding(
      key: anchors.hand,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: HandFan(
        // The hand stays off the table until the opening cut settles; its
        // arrival is what kicks off the deal animation.
        cards: showCutForDeal ? const [] : sortedHand,
        selectedIndices: gs.stage == GameStage.pegging
            ? {if (selectedPeggingIndex >= 0) selectedPeggingIndex}
            : selectedCards,
        dimmedIndices: dimmedHandCards,
        enabled: isMyTurn && !gameNotifier.isDiscarding && !isCounting,
        receiveFirst: !isDealer,
        // The counting hand is the one just played — show it, don't re-deal it.
        animateDeal: !isCounting,
        onCardTap: (index) =>
            _handleCardTap(context, ref, gs, playerId, index, selectedCards),
      ),
    );

    Widget buildPlayerHand() => Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: buildHand(),
    );

    List<Widget> buildOverlays({double? bubbleTop, double? bubbleBottom}) => [
      // The points land on the score they changed: hanging under the
      // opponent's bar, sitting on top of yours.
      ScorePopupOverlay(
        gameId: gameId,
        playerId: playerId,
        opponentName: opponent.name,
        opponentTop: bubbleTop,
        playerBottom: bubbleBottom,
        // Flush with the bars, so the tail lands over the score they carry.
        rightInset: _sideInset,
        alignmentY: -0.62,
      ),
      if (showCountingPanel)
        CountingOverlay(
          cards: countingCrib
              ? gs.crib
              : (countingHand.isNotEmpty ? countingHand : player.hand),
          cutCard: gs.cutCard!,
          isCrib: countingCrib,
          title: countingCrib ? 'Your crib' : 'Your hand',
          onComplete: () {
            ref.read(_manualCountProvider(gameId).notifier).state = false;
            applyCount();
          },
        ),
      if (kDebugMode && _isLocal)
        DevOverlay(gameId: gameId, playerId: playerId),
      if (showCutForDeal)
        CutForDealOverlay(
          playerDeals: isDealer,
          opponentName: opponent.name,
          onComplete: () {
            ref.read(_cutForDealDoneProvider(gameId).notifier).state = true;
          },
        ),
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
                          icon: Icon(
                            Icons.arrow_back,
                            color: colors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            ref.invalidate(activeLocalGameProvider);
                            ref.invalidate(localGameHistoryProvider);
                            context.backOrHome();
                          },
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
                              icon: Icon(
                                Icons.warning,
                                color: colors.warning,
                                size: 18,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(gameNotifier.error!)),
                                );
                                final n = _readNotifier(ref);
                                if (n is GameNotifier) n.clearError();
                                if (n is LocalGameNotifier) n.clearError();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          if (gs.stage != GameStage.gameOver)
                            IconButton(
                              icon: Icon(
                                Icons.flag,
                                color: colors.textTertiary,
                                size: 18,
                              ),
                              onPressed: () => _confirmResign(context, ref),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          IconButton(
                            icon: Icon(
                              Icons.settings,
                              color: colors.textTertiary,
                              size: 18,
                            ),
                            onPressed: () => _showSettingsSheet(context, ref),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.history,
                              color: colors.textTertiary,
                              size: 18,
                            ),
                            onPressed: () => _showHistorySheet(
                              context,
                              gs.history,
                              playerId,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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

    // Phone / tablet portrait: the 121-hole track wraps the screen edge, with
    // the player bars and table inset clear of it.
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mq = MediaQuery.of(context);
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // Track geometry — the content insets below derive from these so
          // nothing ever lands on a hole.
          final topTrackY = mq.padding.top + 6;
          final contentTop = topTrackY + BoardMetrics.topRunHeight + 20;
          final bottomPad = math.max(mq.padding.bottom, 12.0) + 8;

          final handWidth = width - _sideInset * 2;
          final handCardW = math.min(HandFan.maxCardWidth, handWidth * 0.28);
          final handSlot =
              handCardW / AppConstants.cardAspectRatio + HandFan.liftRoom;
          // Timed games slot a clock against each player bar (4px gap + chip).
          final timerBlock = gameNotifier.isTimed ? TurnTimer.height + 4 : 0.0;
          final bottomBlock =
              bottomPad + PlayerBar.height + timerBlock + 12 + handSlot + 12;
          final sideBottom = height - bottomBlock - 26;

          final tableCardW = math.min(56.0, handWidth * 0.175);

          // The opponent's cards, face down under their bar, at the same size
          // as your own so the two hands mirror each other. Capped against the
          // screen height as well, so on a short phone the row gives the table
          // back the room it needs rather than squeezing it flat.
          // One or the other: a fan of card backs under their bar, or a count
          // chip on the bar itself.
          final showOppCards =
              settings.opponentHandDisplay == OpponentHandDisplay.cards;
          final oppCardW = math.min(handCardW, height * 0.085);
          final oppCardH = oppCardW / AppConstants.cardAspectRatio;
          final oppHandTop = contentTop + PlayerBar.height + timerBlock + 6;
          // Where the opponent's half of the table ends, and where a dealt
          // card is headed — their hand when it's shown, their bar when it
          // isn't.
          final oppBlockBottom = showOppCards
              ? oppHandTop + oppCardH
              : contentTop + PlayerBar.height + timerBlock;
          final oppLandingY = showOppCards
              ? oppHandTop + oppCardH / 2
              : contentTop + PlayerBar.height / 2;
          final oppCardCount = showCutForDeal
              ? 0
              : opponent.hand.isEmpty
              ? _estimateOpponentCards(gs, opponent.id)
              : opponent.hand.length;

          return Stack(
            key: anchors.stack,
            children: [
              Positioned.fill(
                child: PerimeterBoard(
                  topY: topTrackY,
                  sideTop: contentTop,
                  sideBottom: sideBottom,
                  playerScore: player.score,
                  opponentScore: opponent.score,
                ),
              ),
              Column(
                children: [
                  SizedBox(height: contentTop),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _sideInset),
                    child: PlayerBar(
                      name: opponent.name,
                      score: opponent.score,
                      isSelf: false,
                      isDealer: !isDealer,
                      isActive: gs.currentPlayerId == opponent.id,
                      // One or the other: when their cards are on the table
                      // you can count them, so the chip would only repeat it.
                      handCount: showOppCards ? null : oppCardCount,
                    ),
                  ),
                  if (gameNotifier.isTimed) ...[
                    const SizedBox(height: 4),
                    buildBarTimer(mine: false),
                  ],
                  if (showOppCards) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _sideInset,
                      ),
                      child: OpponentHand(
                        cardCount: oppCardCount,
                        receiveFirst: isDealer,
                        cardWidth: oppCardW,
                        fanned: true,
                        dealDelay: OpponentDealFlight.flightDuration,
                      ),
                    ),
                  ],
                  buildConnectionBanners(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _sideInset,
                      ),
                      child: _Table(
                        gs: gs,
                        playerId: playerId,
                        opponentName: opponent.name,
                        isMyTurn: isMyTurn,
                        isDealer: isDealer,
                        countingCrib: countingCrib,
                        cribCards: cribCards,
                        cribRevealed: cribRevealed,
                        selectedCardCount: selectedCards.length,
                        cardWidth: tableCardW,
                        handCardWidth: handCardW,
                        roundPlays: roundPlays,
                        spentPileCount: spentPileCount,
                        gameOver: gs.stage == GameStage.gameOver
                            ? _buildGameOver(context, ref, gs, playerId)
                            : null,
                        cribKey: anchors.crib,
                        onSettings: () => _showSettingsSheet(
                          context,
                          ref,
                          canResign: gs.stage != GameStage.gameOver,
                          onLeave: () {
                            ref.invalidate(activeLocalGameProvider);
                            ref.invalidate(localGameHistoryProvider);
                            context.backOrHome();
                          },
                        ),
                        onHistory: () =>
                            _showHistorySheet(context, gs.history, playerId),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _sideInset),
                    child: buildControls(),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _sideInset),
                    child: buildHand(horizontalPadding: 0),
                  ),
                  const SizedBox(height: 12),
                  if (gameNotifier.isTimed) ...[
                    buildBarTimer(mine: true),
                    const SizedBox(height: 4),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _sideInset),
                    child: PlayerBar(
                      name: player.name,
                      score: player.score,
                      isSelf: true,
                      isDealer: isDealer,
                      isActive: isMyTurn,
                    ),
                  ),
                  SizedBox(height: bottomPad),
                ],
              ),
              if (gameNotifier.error != null)
                Positioned(
                  left: _sideInset,
                  right: _sideInset,
                  top: oppBlockBottom + 6,
                  child: _ErrorChip(
                    message: gameNotifier.error!,
                    onDismiss: () {
                      final n = _readNotifier(ref);
                      if (n is GameNotifier) n.clearError();
                      if (n is LocalGameNotifier) n.clearError();
                    },
                  ),
                ),
              // The opponent's half of the deal: card backs fly from the
              // table up to their bar, interleaved with the player's cards.
              Positioned.fill(
                child: OpponentDealFlight(
                  handCount: showCutForDeal ? 0 : player.hand.length,
                  receiveFirst: isDealer,
                  from: Offset(width / 2, height * 0.45),
                  to: Offset(width / 2, oppLandingY),
                  cardWidth: tableCardW * 0.85,
                ),
              ),
              // Anchored to the two score bars: just below the opponent's,
              // just above the player's (clear of the clocks in timed games).
              ...buildOverlays(
                bubbleTop: contentTop + PlayerBar.height + timerBlock + 8,
                bubbleBottom: bottomPad + PlayerBar.height + timerBlock + 8,
              ),
              DiscardFlight(
                stackKey: anchors.stack,
                handKey: anchors.hand,
                cribKey: anchors.crib,
                token: discardToken,
              ),
            ],
          );
        },
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
          // Manual: tap selects card, "Play Card" button confirms; tapping
          // the selected card again puts it back down.
          final current = ref.read(selectedPeggingCardProvider(gameId));
          ref.read(selectedPeggingCardProvider(gameId).notifier).state =
              current == card ? null : card;
        }
      }
    }
  }

  void _showHistorySheet(
    BuildContext context,
    List<GameHistoryEvent> events,
    String playerId,
  ) {
    showCcDialog(
      context: context,
      builder: (_) => CcDialog(
        title: 'Game history',
        child: HistoryLog(events: events, playerId: playerId),
      ),
    );
  }

  void _showSettingsSheet(
    BuildContext context,
    WidgetRef ref, {
    bool canResign = false,
    VoidCallback? onLeave,
  }) {
    showGameSettingsDialog(
      context,
      onLeave: onLeave,
      onResign: canResign ? () => _confirmResign(context, ref) : null,
    );
  }

  void _confirmResign(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    showCcDialog(
      context: context,
      builder: (ctx) => CcDialog(
        title: 'Resign this game?',
        showCloseButton: false,
        actions: [
          CcSecondaryButton(
            label: 'Resign',
            labelColor: colors.error,
            onPressed: () {
              Navigator.of(ctx).pop();
              final n = _readNotifier(ref);
              if (n is GameNotifier) n.resign();
              if (n is LocalGameNotifier) n.resign();
            },
          ),
          CcPrimaryButton(
            label: 'Keep playing',
            height: 44,
            fontSize: 14,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
        child: Text(
          'It counts as a loss.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.35,
          ),
        ),
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
    // Send the pair across to the crib. The flight is decorative — the state
    // change below doesn't wait on it.
    ref.read(_discardTokenProvider(gameId).notifier).state++;

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

    final forfeitText = forfeit == null
        ? null
        : forfeitSentence(
            forfeit.reason,
            isSelf: forfeit.forfeitingPlayerId == playerId,
          );

    // Result subtitle: forfeit reason, or score + margin
    final scoreLine = forfeitText != null
        ? '${player.score}–${opponent.score} · $forfeitText'
        : margin > 0
        ? '${player.score}–${opponent.score} · by $margin point${margin == 1 ? '' : 's'}'
        : '${player.score}–${opponent.score}';

    // Game-over panel (design language §4): result word never colored —
    // the score line carries the outcome.
    return Center(
      child: Container(
        width: 300,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderStrong),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 40,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              didWin ? 'Victory' : 'Defeat',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              scoreLine,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 14,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (forfeit == null &&
                (handCounts.isNotEmpty || cribCounts.isNotEmpty)) ...[
              const SizedBox(height: 8),
              ...handCounts.reversed
                  .take(2)
                  .map(
                    (e) => Text(
                      '${e.playerId == playerId ? "Your hand" : "Opponent hand"}: '
                      '${e.totalPoints} pts${_breakdownText(e.scoreBreakdown)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ...cribCounts.reversed
                  .take(1)
                  .map(
                    (e) => Text(
                      'Crib: ${e.totalPoints} pts${_breakdownText(e.scoreBreakdown)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CcPrimaryButton(
                label: 'Rematch',
                height: 48,
                fontSize: 15,
                onPressed: () => _playAgain(context, ref),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CcSecondaryButton(
                    label: 'Analyze game',
                    height: 40,
                    fontSize: 13,
                    filled: false,
                    onPressed: () => context.push('/analysis/${gs.gameId}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CcSecondaryButton(
                    label: 'Replay',
                    height: 40,
                    fontSize: 13,
                    filled: false,
                    onPressed: () => context.push('/replay/${gs.gameId}'),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.backOrHome(),
              child: Text(
                'Home',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _breakdownText(ScoreBreakdown b) {
    final parts = <String>[];
    // Breakdown fields are points, not counts (a lone pair is 2 in `pairs`),
    // so phrase them as points.
    if (b.fifteens > 0) parts.add('${b.fifteens} for 15s');
    if (b.pairs > 0) parts.add('${b.pairs} for pairs');
    if (b.runs > 0) parts.add('${b.runs} for runs');
    if (b.flushes > 0) parts.add('${b.flushes} for the flush');
    if (b.nobs > 0) parts.add('${b.nobs} for nobs');
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
        context.pushReplacement('/game/${newState.gameId}');
      }
    } else {
      try {
        final restClient = ref.read(restClientProvider);
        final gameState = await restClient.createAIGame();
        if (context.mounted) {
          context.pushReplacement('/game/${gameState.gameId}');
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

/// The table between the two player bars: the stage/count block with the
/// pegging pile under it, the starter + crib cluster anchored at the dealer's
/// end, and the game utilities in the opposite corner.
class _Table extends StatelessWidget {
  final GameState gs;
  final String playerId;
  final String opponentName;
  final bool isMyTurn;
  final bool isDealer;

  /// True while this player is counting their own crib — the crib has moved
  /// into the hand slot, so its corner stack steps aside and the instruction
  /// changes.
  final bool countingCrib;
  final List<PlayingCard> cribCards;
  final bool cribRevealed;
  final int selectedCardCount;
  final double cardWidth;

  /// Size of a card in the player's hand. The starter is shown at this size
  /// while counting, so the two read as one hand.
  final double handCardWidth;

  /// Every card played this round, oldest first — spent counts then the live
  /// pile.
  final List<CardPlayed> roundPlays;

  /// How many of [roundPlays] belong to counts already closed by a 31 or go.
  final int spentPileCount;
  final Widget? gameOver;

  /// Where the discard flight lands.
  final GlobalKey cribKey;
  final VoidCallback onSettings;
  final VoidCallback onHistory;

  const _Table({
    required this.gs,
    required this.playerId,
    required this.opponentName,
    required this.isMyTurn,
    required this.isDealer,
    required this.countingCrib,
    required this.cribCards,
    required this.cribRevealed,
    required this.selectedCardCount,
    required this.cardWidth,
    required this.handCardWidth,
    required this.roundPlays,
    required this.spentPileCount,
    required this.gameOver,
    required this.cribKey,
    required this.onSettings,
    required this.onHistory,
  });

  /// The middle stays quiet: the action button, the crib cluster, the cards on
  /// the table and the active player bar already say the stage, whose turn it
  /// is, and how many cards are picked. The only things it carries are the
  /// pegging count — kept small at the pile's side — and a one-word cue for
  /// the crib step, where the crib cards stand in for your hand with nothing
  /// else to name them.
  Widget _countBlock() {
    switch (gs.stage) {
      case GameStage.counting:
        return countingCrib
            ? const CountBlock(
                label: '',
                headline: 'Your crib',
                instruction: '',
              )
            : const SizedBox.shrink();
      case GameStage.pegging:
      case GameStage.dealing:
      case GameStage.discardingToCrib:
      case GameStage.cutting:
      case GameStage.gameOver:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The corner crib stack steps aside while the crib is being counted in the
    // hand slot, so it isn't shown in two places at once.
    final showCluster =
        gs.stage != GameStage.dealing && gameOver == null && !countingCrib;
    // While counting, the starter leaves its corner and sits in the middle at
    // hand size — you count it together with the four in your hand.
    final countingStarter = gs.stage == GameStage.counting ? gs.cutCard : null;
    final pileCards = [for (final p in roundPlays) p.card];
    final pileOwners = [for (final p in roundPlays) p.playerId == playerId];
    final showPile = pileCards.isNotEmpty && gameOver == null;
    final pegging = gs.stage == GameStage.pegging && gameOver == null;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Centre the count block in what is left after the corner
              // cluster, so the two never collide when the pile grows — but
              // never surrender more than a third of a short screen to it.
              final band = showCluster
                  ? math.min(
                      StarterCribCluster.heightFor(cardWidth) + 24,
                      constraints.maxHeight * 0.34,
                    )
                  : 0.0;
              return Padding(
                padding: EdgeInsets.only(
                  top: isDealer ? 0 : band,
                  bottom: isDealer ? band : 0,
                ),
                child: Center(
                  child:
                      gameOver ??
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        // FittedBox hands its child unbounded width, so pin
                        // the table width back on or the headline stops
                        // wrapping and shrinks to nothing instead.
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _countBlock(),
                              if (countingStarter != null) ...[
                                const SizedBox(height: 16),
                                _CountingStarter(
                                  card: countingStarter,
                                  width: handCardWidth,
                                ),
                              ],
                              if (showPile || pegging)
                                // The count keeps the pile company rather
                                // than headlining the table: label over a
                                // small number, on the pile's left.
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (pegging)
                                      CountBlock(
                                        label: 'Count',
                                        count: gs.peggingCount,
                                        instruction: '',
                                        compact: true,
                                      ),
                                    if (pegging && showPile)
                                      const SizedBox(width: 16),
                                    if (showPile)
                                      PeggingPile(
                                        cards: pileCards,
                                        playedByMe: pileOwners,
                                        previousCount: spentPileCount,
                                        cardWidth: cardWidth,
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                ),
              );
            },
          ),
        ),
        if (showCluster)
          Positioned(
            left: 6,
            top: isDealer ? null : 18,
            bottom: isDealer ? 18 : null,
            child: StarterCribCluster(
              cribKey: cribKey,
              starter: gs.cutCard,
              crib: cribCards,
              cribRevealed: cribRevealed,
              cribOwner: isDealer ? 'Yours' : "$opponentName's",
              cardWidth: cardWidth,
              showStarter: countingStarter == null,
            ),
          ),
        // The result panel is the only thing to act on once the game is over,
        // and it sits under these in the stack — so they step aside.
        if (gameOver == null)
          Positioned(
            right: 6,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                GameIconButton(
                  icon: Icons.tune,
                  tooltip: 'Game settings',
                  onPressed: onSettings,
                ),
                const SizedBox(height: 8),
                GameIconButton(
                  icon: Icons.history,
                  tooltip: 'Play history',
                  onPressed: onHistory,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The starter, centred at hand size for the count.
class _CountingStarter extends StatelessWidget {
  final PlayingCard card;
  final double width;

  const _CountingStarter({required this.card, required this.width});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CardWidget(
          card: card,
          faceUp: true,
          enabled: false,
          width: width,
          height: width / AppConstants.cardAspectRatio,
        ),
        const SizedBox(height: 6),
        Text(
          'STARTER',
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

/// Transient error notice, shown in place of the old top-bar warning button.
class _ErrorChip extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorChip({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.error.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: colors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
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
