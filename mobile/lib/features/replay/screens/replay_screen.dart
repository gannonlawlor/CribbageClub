import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/constants.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/card.dart';
import '../../../core/models/game_history_event.dart';
import '../../../core/models/game_state.dart';
import '../../../core/services/local_game_history_provider.dart';
import '../../../shared/utils/card_utils.dart';
import '../../../shared/utils/forfeit_text.dart';
import '../../../shared/widgets/cc_buttons.dart';
import '../../game/state/game_providers.dart';
import '../../game/widgets/card_widget.dart';
import '../../game/widgets/count_block.dart';
import '../../game/widgets/game_icon_button.dart';
import '../../game/widgets/pegging_pile.dart';
import '../../game/widgets/perimeter_board.dart';
import '../../game/widgets/player_bar.dart';
import '../../game/widgets/starter_crib.dart';
import '../state/replay_snapshot_builder.dart';

/// Horizontal inset that keeps the table clear of the perimeter track —
/// matches the game screen so a replay reads as the same board.
const double _sideInset = 40;

/// Height the transport strip claims at the bottom of the screen.
const double _transportHeight = 116;

/// Playback speeds cycled by the speed chip.
const List<double> _speeds = [0.5, 1.0, 1.5, 2.0];

/// State for replay playback.
class ReplayState {
  final int currentEventIndex;
  final bool isPlaying;
  final double playbackSpeed;
  final List<GameHistoryEvent> events;
  final List<String> playerIds;
  final Map<String, String> playerNames;

  const ReplayState({
    this.currentEventIndex = -1,
    this.isPlaying = false,
    this.playbackSpeed = 1.0,
    this.events = const [],
    this.playerIds = const [],
    this.playerNames = const {},
  });

  int get totalEvents => events.length;
  bool get atStart => currentEventIndex < 0;
  bool get atEnd => currentEventIndex >= events.length - 1;

  ReplaySnapshot get snapshot => currentEventIndex < 0
      ? const ReplaySnapshot(eventDescription: 'Ready to replay')
      : ReplaySnapshotBuilder.buildSnapshot(
          events,
          currentEventIndex,
          playerIds,
          playerNames,
        );

  ReplayState copyWith({
    int? currentEventIndex,
    bool? isPlaying,
    double? playbackSpeed,
    List<GameHistoryEvent>? events,
    List<String>? playerIds,
    Map<String, String>? playerNames,
  }) {
    return ReplayState(
      currentEventIndex: currentEventIndex ?? this.currentEventIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      events: events ?? this.events,
      playerIds: playerIds ?? this.playerIds,
      playerNames: playerNames ?? this.playerNames,
    );
  }
}

class ReplayNotifier extends StateNotifier<ReplayState> {
  Timer? _playTimer;

  ReplayNotifier(GameState gameState)
    : super(
        ReplayState(
          events: gameState.history,
          playerIds: gameState.players.map((p) => p.id).toList(),
          playerNames: {for (final p in gameState.players) p.id: p.name},
        ),
      );

  void stepForward() {
    if (state.atEnd) return;
    state = state.copyWith(currentEventIndex: state.currentEventIndex + 1);
  }

  void stepBack() {
    if (state.atStart) return;
    state = state.copyWith(currentEventIndex: state.currentEventIndex - 1);
  }

  /// Scrubbing takes over from playback — the timer would otherwise fight
  /// the thumb.
  void seekTo(int index) {
    if (state.isPlaying) _stopPlaying();
    state = state.copyWith(
      currentEventIndex: index.clamp(-1, state.totalEvents - 1),
    );
  }

  void togglePlay() {
    if (state.isPlaying) {
      _stopPlaying();
    } else {
      _startPlaying();
    }
  }

  void setSpeed(double speed) {
    state = state.copyWith(playbackSpeed: speed);
    if (state.isPlaying) {
      _stopPlaying();
      _startPlaying();
    }
  }

  void _startPlaying() {
    if (state.atEnd) {
      state = state.copyWith(currentEventIndex: -1);
    }
    state = state.copyWith(isPlaying: true);
    _scheduleNext();
  }

  void _scheduleNext() {
    _playTimer?.cancel();
    final ms = (1200 / state.playbackSpeed).round();
    _playTimer = Timer(Duration(milliseconds: ms), () {
      if (!mounted || !state.isPlaying) return;
      if (state.atEnd) {
        _stopPlaying();
        return;
      }
      state = state.copyWith(currentEventIndex: state.currentEventIndex + 1);
      _scheduleNext();
    });
  }

  void _stopPlaying() {
    _playTimer?.cancel();
    _playTimer = null;
    state = state.copyWith(isPlaying: false);
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }
}

/// Provider that loads game state (from local or REST) and creates replay notifier.
final _replayGameStateProvider = FutureProvider.family
    .autoDispose<GameState, String>((ref, gameId) async {
      if (isLocalGame(gameId)) {
        // Try in-memory active game first
        final notifierState = ref.read(localGameNotifierProvider(gameId));
        var gs = notifierState.gameState;
        // Fall back to persisted storage
        gs ??= await ref.read(persistedGameStateProvider(gameId).future);
        if (gs == null) throw Exception('Local game not found');
        return gs;
      } else {
        final restClient = ref.read(restClientProvider);
        return (await restClient.getGameState(gameId)).gameState;
      }
    });

final replayNotifierProvider = StateNotifierProvider.family
    .autoDispose<ReplayNotifier, ReplayState, String>((ref, gameId) {
      final gameStateAsync = ref.watch(_replayGameStateProvider(gameId));
      final gameState = gameStateAsync.valueOrNull;
      if (gameState == null) {
        return ReplayNotifier(const GameState(gameId: '', players: []));
      }
      return ReplayNotifier(gameState);
    });

class ReplayScreen extends ConsumerWidget {
  final String gameId;

  const ReplayScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final gameStateAsync = ref.watch(_replayGameStateProvider(gameId));

    return gameStateAsync.when(
      loading: () => Scaffold(
        backgroundColor: colors.scaffoldBg,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: colors.scaffoldBg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'This game could not be loaded.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textTertiary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    child: CcSecondaryButton(
                      label: 'Back to home',
                      onPressed: () => context.go('/'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      data: (gameState) => _ReplayContent(gameId: gameId, gameState: gameState),
    );
  }
}

class _ReplayContent extends ConsumerWidget {
  final String gameId;
  final GameState gameState;

  const _ReplayContent({required this.gameId, required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final replayState = ref.watch(replayNotifierProvider(gameId));
    final notifier = ref.read(replayNotifierProvider(gameId).notifier);
    final snapshot = replayState.snapshot;
    final playerIds = replayState.playerIds;
    final auth = ref.watch(authProvider);

    if (playerIds.isEmpty) {
      return Scaffold(
        backgroundColor: colors.scaffoldBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Determine which player is "me" vs "opponent"
    final myId = isLocalGame(gameId)
        ? playerIds.firstWhere(
            (id) => !id.startsWith('ai_'),
            orElse: () => playerIds.first,
          )
        : (auth.userId ?? playerIds.first);
    final opponentId = playerIds.firstWhere(
      (id) => id != myId,
      orElse: () => playerIds.last,
    );
    final myName = replayState.playerNames[myId] ?? 'You';
    final opponentName = replayState.playerNames[opponentId] ?? 'Opponent';
    final isDealer = snapshot.dealerPlayerId == myId;
    final hasDealer = snapshot.dealerPlayerId != null;

    // Once the game is over the recorded result is the truth — a history
    // that skipped events (an imported or dev-scored game) would otherwise
    // end the replay on a score that never happened.
    final finalScores = {for (final p in gameState.players) p.id: p.score};
    final myScore = snapshot.isGameOver
        ? (finalScores[myId] ?? snapshot.scores[myId] ?? 0)
        : (snapshot.scores[myId] ?? 0);
    final opponentScore = snapshot.isGameOver
        ? (finalScores[opponentId] ?? snapshot.scores[opponentId] ?? 0)
        : (snapshot.scores[opponentId] ?? 0);

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
          final bottomPad = math.max(mq.padding.bottom, 12.0);

          final handWidth = width - _sideInset * 2;
          final handCardW = math.min(64.0, handWidth * 0.22);
          final handSlot = handCardW / AppConstants.cardAspectRatio;
          final oppCardW = math.min(46.0, handWidth * 0.16);
          final oppSlot = oppCardW / AppConstants.cardAspectRatio;

          final bottomBlock =
              bottomPad + _transportHeight + PlayerBar.height + 10 + handSlot;
          final sideBottom = height - bottomBlock - 22;

          final tableCardW = math.min(52.0, handWidth * 0.165);

          return Stack(
            children: [
              Positioned.fill(
                child: PerimeterBoard(
                  topY: topTrackY,
                  sideTop: contentTop,
                  sideBottom: sideBottom,
                  playerScore: myScore,
                  opponentScore: opponentScore,
                ),
              ),
              Column(
                children: [
                  SizedBox(height: contentTop),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _sideInset),
                    child: PlayerBar(
                      name: opponentName,
                      score: opponentScore,
                      isSelf: false,
                      isDealer: hasDealer && !isDealer,
                      isActive: snapshot.actingPlayerId == opponentId,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _sideInset),
                    child: _ReplayHand(
                      cards: snapshot.hands[opponentId] ?? const [],
                      cardWidth: oppCardW,
                      slotHeight: oppSlot,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _sideInset,
                      ),
                      child: _ReplayTable(
                        snapshot: snapshot,
                        myId: myId,
                        myScore: myScore,
                        opponentScore: opponentScore,
                        opponentName: opponentName,
                        isDealer: isDealer,
                        cardWidth: tableCardW,
                        onClose: () => context.go('/'),
                        onAnalyze: () => context.go('/analysis/$gameId'),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _sideInset),
                    child: _ReplayHand(
                      cards: snapshot.hands[myId] ?? const [],
                      cardWidth: handCardW,
                      slotHeight: handSlot,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _sideInset),
                    child: PlayerBar(
                      name: myName,
                      score: myScore,
                      isSelf: true,
                      isDealer: hasDealer && isDealer,
                      isActive: snapshot.actingPlayerId == myId,
                    ),
                  ),
                  _TransportBar(
                    state: replayState,
                    snapshot: snapshot,
                    isSelfActing: snapshot.actingPlayerId == myId,
                    bottomPad: bottomPad,
                    onSeek: notifier.seekTo,
                    onStepBack: notifier.stepBack,
                    onStepForward: notifier.stepForward,
                    onTogglePlay: notifier.togglePlay,
                    onCycleSpeed: () {
                      final idx = _speeds.indexOf(replayState.playbackSpeed);
                      notifier.setSpeed(_speeds[(idx + 1) % _speeds.length]);
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The table between the two player bars: the stage block with the pegging
/// pile under it, the starter + crib cluster at the dealer's end, and the
/// replay utilities in the opposite corner (mirrors the game screen).
class _ReplayTable extends StatelessWidget {
  final ReplaySnapshot snapshot;
  final String myId;
  final int myScore;
  final int opponentScore;
  final String opponentName;
  final bool isDealer;
  final double cardWidth;
  final VoidCallback onClose;
  final VoidCallback onAnalyze;

  const _ReplayTable({
    required this.snapshot,
    required this.myId,
    required this.myScore,
    required this.opponentScore,
    required this.opponentName,
    required this.isDealer,
    required this.cardWidth,
    required this.onClose,
    required this.onAnalyze,
  });

  String get _caption =>
      snapshot.roundNumber > 0 ? 'Round ${snapshot.roundNumber}' : 'Replay';

  String? get _headline => switch (snapshot.phase) {
    ReplayPhase.start => 'Game start',
    ReplayPhase.deal => 'Cards dealt',
    ReplayPhase.cut => 'Starter cut',
    ReplayPhase.pegging => null,
    ReplayPhase.counting => 'Counting hands',
    ReplayPhase.gameOver => '',
  };

  @override
  Widget build(BuildContext context) {
    final showResult = snapshot.phase == ReplayPhase.gameOver;
    final showCluster = snapshot.cutCard != null && !showResult;
    final showPile = snapshot.playedCards.isNotEmpty && !showResult;
    final isSelfScoring = snapshot.actingPlayerId == myId;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Reserve the band the corner cluster occupies so the centred
              // stage block never collides with it.
              final band = showCluster
                  ? math.min(
                      StarterCribCluster.heightFor(cardWidth) + 20,
                      constraints.maxHeight * 0.34,
                    )
                  : 0.0;
              return Padding(
                padding: EdgeInsets.only(
                  top: isDealer ? 0 : band,
                  bottom: isDealer ? band : 0,
                ),
                child: Center(
                  child: showResult
                      ? _ResultPanel(
                          didWin: snapshot.winnerPlayerId == myId,
                          myScore: myScore,
                          opponentScore: opponentScore,
                          forfeitReason: snapshot.forfeitReason,
                          onAnalyze: onAnalyze,
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CountBlock(
                                  label: _caption,
                                  count: snapshot.phase == ReplayPhase.pegging
                                      ? snapshot.peggingCount
                                      : null,
                                  headline: _headline,
                                  instruction:
                                      snapshot.phase == ReplayPhase.start
                                      ? 'Play or step through the game'
                                      : '',
                                ),
                                if (snapshot.scoreDelta > 0) ...[
                                  const SizedBox(height: 10),
                                  _ScorePill(
                                    points: snapshot.scoreDelta,
                                    reason: snapshot.scoreReason,
                                    isSelf: isSelfScoring,
                                  ),
                                ],
                                if (showPile) ...[
                                  const SizedBox(height: 16),
                                  PeggingPile(
                                    cards: snapshot.playedCards,
                                    playedByMe: [
                                      for (final id
                                          in snapshot.playedCardOwners)
                                        id == myId,
                                    ],
                                    cardWidth: cardWidth,
                                  ),
                                ],
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
            left: 0,
            top: isDealer ? null : 12,
            bottom: isDealer ? 12 : null,
            child: StarterCribCluster(
              starter: snapshot.cutCard,
              crib: snapshot.cribCards,
              cribRevealed: snapshot.cribRevealed,
              cribOwner: isDealer ? 'Yours' : "$opponentName's",
              cardWidth: cardWidth,
            ),
          ),
        Positioned(
          right: 0,
          top: 12,
          child: Column(
            children: [
              GameIconButton(
                icon: Icons.close,
                tooltip: 'Leave replay',
                onPressed: onClose,
              ),
              const SizedBox(height: 8),
              GameIconButton(
                icon: Icons.insights,
                tooltip: 'Analysis',
                onPressed: onAnalyze,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Score pill (design language §4): filled with the scorer's identity colour,
/// dark text, points then reason at 75% opacity.
class _ScorePill extends StatelessWidget {
  final int points;
  final String? reason;
  final bool isSelf;

  const _ScorePill({
    required this.points,
    required this.reason,
    required this.isSelf,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fill = isSelf ? colors.pegPlayer : colors.pegOpponent;
    final onFill = isSelf ? colors.accentOnSurface : const Color(0xFF26221E);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      child: Container(
        key: ValueKey('$points$reason$isSelf'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+$points',
              style: TextStyle(
                color: onFill,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (reason != null && reason!.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                reason!,
                style: TextStyle(
                  color: onFill.withValues(alpha: 0.75),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Game-over panel (design language §4): the result word is never coloured —
/// the score line carries the outcome.
class _ResultPanel extends StatelessWidget {
  final bool didWin;
  final int myScore;
  final int opponentScore;
  final String? forfeitReason;
  final VoidCallback onAnalyze;

  const _ResultPanel({
    required this.didWin,
    required this.myScore,
    required this.opponentScore,
    required this.forfeitReason,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final margin = (myScore - opponentScore).abs();

    final detail = forfeitReason != null
        ? forfeitSentence(forfeitReason, isSelf: !didWin)
        : margin > 0
        ? 'by $margin point${margin == 1 ? '' : 's'}'
        : null;

    return Container(
      width: 280,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
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
            detail == null
                ? '$myScore–$opponentScore'
                : '$myScore–$opponentScore · $detail',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 14,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CcSecondaryButton(
              label: 'Analyze game',
              height: 40,
              fontSize: 13,
              onPressed: onAnalyze,
            ),
          ),
        ],
      ),
    );
  }
}

/// A hand laid out face-up. Replay never deals or selects, so this is the
/// static counterpart to the game screen's HandFan — same geometry, no
/// animation to fight the scrubber.
class _ReplayHand extends StatelessWidget {
  final List<PlayingCard> cards;
  final double cardWidth;
  final double slotHeight;

  const _ReplayHand({
    required this.cards,
    required this.cardWidth,
    required this.slotHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return SizedBox(height: slotHeight);
    final sorted = CardUtils.sorted(cards);

    return SizedBox(
      height: slotHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth;
          final n = sorted.length;
          final cardH = cardWidth / AppConstants.cardAspectRatio;
          final step = n > 1
              ? math
                    .min(cardWidth + 8, (available - cardWidth) / (n - 1))
                    .clamp(cardWidth * 0.45, cardWidth + 8)
              : 0.0;
          final startX = (available - (cardWidth + (n - 1) * step)) / 2;
          final overlapping = n > 1 && step < cardWidth;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < n; i++)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  left: startX + i * step,
                  bottom: 0,
                  child: CardWidget(
                    card: sorted[i],
                    faceUp: true,
                    enabled: false,
                    indexOnly: overlapping && i < n - 1,
                    width: cardWidth,
                    height: cardH,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The playback chrome pinned to the bottom edge: the move being shown, a
/// scrubber across the whole game, and the transport controls.
class _TransportBar extends StatelessWidget {
  final ReplayState state;
  final ReplaySnapshot snapshot;
  final bool isSelfActing;
  final double bottomPad;
  final ValueChanged<int> onSeek;
  final VoidCallback onStepBack;
  final VoidCallback onStepForward;
  final VoidCallback onTogglePlay;
  final VoidCallback onCycleSpeed;

  const _TransportBar({
    required this.state,
    required this.snapshot,
    required this.isSelfActing,
    required this.bottomPad,
    required this.onSeek,
    required this.onStepBack,
    required this.onStepForward,
    required this.onTogglePlay,
    required this.onCycleSpeed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final total = state.totalEvents;
    final marker = snapshot.actingPlayerId == null
        ? colors.textDisabled
        : (isSelfActing ? colors.pegPlayer : colors.pegOpponent);

    return Container(
      height: _transportHeight + bottomPad,
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
      decoration: BoxDecoration(
        color: colors.surfaceChrome,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Column(
        children: [
          // The move currently on the table.
          SizedBox(
            height: 20,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: marker,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 120),
                    // Default switcher layout centres its children; the move
                    // line reads from the left.
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [...previous, ?current],
                    ),
                    child: Text(
                      snapshot.eventDescription,
                      key: ValueKey(snapshot.eventDescription),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${state.currentEventIndex + 1}/$total',
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 24,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                trackShape: const RoundedRectSliderTrackShape(),
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 7,
                  elevation: 0,
                  pressedElevation: 0,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: colors.accent,
                inactiveTrackColor: colors.surfaceDim,
                thumbColor: colors.accent,
                overlayColor: colors.accent.withValues(alpha: 0.15),
              ),
              child: Slider(
                min: -1,
                max: math.max(0, total - 1).toDouble(),
                value: state.currentEventIndex.toDouble().clamp(
                  -1,
                  math.max(0, total - 1).toDouble(),
                ),
                onChanged: (val) => onSeek(val.round()),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _SpeedChip(
                      speed: state.playbackSpeed,
                      onTap: onCycleSpeed,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GameIconButton(
                        icon: Icons.skip_previous,
                        tooltip: 'Previous move',
                        onPressed: state.atStart ? null : onStepBack,
                        iconColor: state.atStart
                            ? colors.textDisabled
                            : colors.textSecondary,
                      ),
                      const SizedBox(width: 14),
                      _PlayButton(
                        isPlaying: state.isPlaying,
                        onPressed: onTogglePlay,
                      ),
                      const SizedBox(width: 14),
                      GameIconButton(
                        icon: Icons.skip_next,
                        tooltip: 'Next move',
                        onPressed: state.atEnd ? null : onStepForward,
                        iconColor: state.atEnd
                            ? colors.textDisabled
                            : colors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 56),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Green means "act" — the one saturated control in the transport strip,
/// with the CTA's 4px bottom bevel.
class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _PlayButton({required this.isPlaying, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(10);

    return Container(
      width: 56,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF5D9948),
        borderRadius: radius,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: colors.accent,
          borderRadius: radius,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              size: 26,
              color: colors.accentOnSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Playback speed, cycled on tap. Tertiary weight — it is not the action.
class _SpeedChip extends StatelessWidget {
  final double speed;
  final VoidCallback onTap;

  const _SpeedChip({required this.speed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final label = speed == speed.roundToDouble()
        ? '${speed.toInt()}×'
        : '$speed×';

    return Material(
      color: colors.surfacePrimary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderStrong),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
