import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/game_history_event.dart';
import '../../../core/models/game_state.dart';
import '../../game/state/game_providers.dart';
import '../../game/widgets/card_widget.dart';
import '../../game/widgets/cribbage_board.dart';
import '../state/replay_snapshot_builder.dart';

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
      ? const ReplaySnapshot(eventDescription: 'Game start — tap play or step forward')
      : ReplaySnapshotBuilder.buildSnapshot(
          events, currentEventIndex, playerIds, playerNames);

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
      : super(ReplayState(
          events: gameState.history,
          playerIds: gameState.players.map((p) => p.id).toList(),
          playerNames: {
            for (final p in gameState.players) p.id: p.name,
          },
        ));

  void stepForward() {
    if (state.atEnd) return;
    state = state.copyWith(currentEventIndex: state.currentEventIndex + 1);
  }

  void stepBack() {
    if (state.atStart) return;
    state = state.copyWith(currentEventIndex: state.currentEventIndex - 1);
  }

  void seekTo(int index) {
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
final _replayGameStateProvider =
    FutureProvider.family.autoDispose<GameState, String>((ref, gameId) async {
  if (isLocalGame(gameId)) {
    final notifierState = ref.read(localGameNotifierProvider(gameId));
    final gs = notifierState.gameState;
    if (gs == null) throw Exception('Local game not found');
    return gs;
  } else {
    final restClient = ref.read(restClientProvider);
    return restClient.getGameState(gameId);
  }
});

final replayNotifierProvider = StateNotifierProvider.family
    .autoDispose<ReplayNotifier, ReplayState, String>((ref, gameId) {
  final gameStateAsync = ref.watch(_replayGameStateProvider(gameId));
  final gameState = gameStateAsync.valueOrNull;
  if (gameState == null) {
    return ReplayNotifier(const GameState(
      gameId: '',
      players: [],
    ));
  }
  return ReplayNotifier(gameState);
});

class ReplayScreen extends ConsumerWidget {
  final String gameId;

  const ReplayScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameStateAsync = ref.watch(_replayGameStateProvider(gameId));

    return gameStateAsync.when(
      loading: () => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.feltGradient),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Replay')),
        body: Center(
          child: Text('Failed to load: $error',
              style: const TextStyle(color: Colors.redAccent)),
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
    final replayState = ref.watch(replayNotifierProvider(gameId));
    final snapshot = replayState.snapshot;
    final playerIds = replayState.playerIds;
    final auth = ref.watch(authProvider);

    // Determine which player is "me" vs "opponent"
    final myId = isLocalGame(gameId)
        ? playerIds.firstWhere((id) => !id.startsWith('ai_'),
            orElse: () => playerIds.first)
        : (auth.userId ?? playerIds.first);
    final opponentId = playerIds.firstWhere((id) => id != myId,
        orElse: () => playerIds.last);
    final myName = replayState.playerNames[myId] ?? 'Player';
    final opponentName = replayState.playerNames[opponentId] ?? 'Opponent';
    final myScore = snapshot.scores[myId] ?? 0;
    final opponentScore = snapshot.scores[opponentId] ?? 0;
    final isDealer = snapshot.dealerPlayerId == myId;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.feltGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white70, size: 20),
                      onPressed: () => context.go('/'),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$myName: $myScore',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                          if (isDealer)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text('(D)',
                                  style: TextStyle(
                                      color: AppTheme.goldAccent, fontSize: 11)),
                            ),
                          const Text('  vs  ',
                              style: TextStyle(color: Colors.white38)),
                          Text('$opponentName: $opponentScore',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                          if (!isDealer && snapshot.dealerPlayerId != null)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text('(D)',
                                  style: TextStyle(
                                      color: AppTheme.goldAccent, fontSize: 11)),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.analytics,
                          color: Colors.white54, size: 20),
                      tooltip: 'Analysis',
                      onPressed: () => context.go('/analysis/$gameId'),
                    ),
                  ],
                ),
              ),

              // Cribbage Board
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: CribbageBoard(
                  playerScore: myScore,
                  opponentScore: opponentScore,
                  isDealer: isDealer,
                ),
              ),

              // Opponent hand (face up in replay)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opponentName,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 2),
                    _HandRow(cards: snapshot.hands[opponentId] ?? []),
                  ],
                ),
              ),

              // Middle: cut card, crib, played cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Round indicator
                      if (snapshot.roundNumber > 0)
                        Text('Round ${snapshot.roundNumber}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 6),

                      // Cut card + crib
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (snapshot.cutCard != null)
                            Column(
                              children: [
                                const Text('Cut',
                                    style: TextStyle(
                                        color: Colors.white38, fontSize: 10)),
                                CardWidget(
                                  card: snapshot.cutCard,
                                  width: 44,
                                  height: 62,
                                  enabled: false,
                                ),
                              ],
                            ),
                          if (snapshot.cribCards.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Column(
                              children: [
                                const Text('Crib',
                                    style: TextStyle(
                                        color: Colors.white38, fontSize: 10)),
                                Row(
                                  children: snapshot.cribCards
                                      .map((c) => Padding(
                                            padding:
                                                const EdgeInsets.only(right: 2),
                                            child: CardWidget(
                                              card: c,
                                              faceUp: snapshot.cribRevealed,
                                              width: 32,
                                              height: 45,
                                              enabled: false,
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),

                      // Played cards
                      if (snapshot.playedCards.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Count: ${snapshot.peggingCount}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 3,
                          children: snapshot.playedCards
                              .map((c) => CardWidget(
                                    card: c,
                                    width: 36,
                                    height: 50,
                                    enabled: false,
                                  ))
                              .toList(),
                        ),
                      ],

                      // Game over
                      if (snapshot.isGameOver)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Icon(
                            Icons.emoji_events,
                            size: 36,
                            color: snapshot.winnerPlayerId == myId
                                ? AppTheme.goldAccent
                                : Colors.white38,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Event description
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.black26,
                child: Text(
                  snapshot.eventDescription,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

              // Player hand (face up in replay)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(myName,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 2),
                    _HandRow(cards: snapshot.hands[myId] ?? []),
                  ],
                ),
              ),

              // Progress bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: AppTheme.goldAccent,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: AppTheme.goldAccent,
                  ),
                  child: Slider(
                    min: -1,
                    max: (replayState.totalEvents - 1).toDouble(),
                    value: replayState.currentEventIndex.toDouble(),
                    onChanged: (val) {
                      ref
                          .read(replayNotifierProvider(gameId).notifier)
                          .seekTo(val.round());
                    },
                  ),
                ),
              ),

              // Controls
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Speed control
                    _SpeedChip(
                      speed: replayState.playbackSpeed,
                      onTap: () {
                        final speeds = [0.5, 1.0, 1.5, 2.0];
                        final idx = speeds.indexOf(replayState.playbackSpeed);
                        final next = speeds[(idx + 1) % speeds.length];
                        ref
                            .read(replayNotifierProvider(gameId).notifier)
                            .setSpeed(next);
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: replayState.atStart
                          ? null
                          : () => ref
                              .read(replayNotifierProvider(gameId).notifier)
                              .stepBack(),
                      icon: Icon(Icons.skip_previous,
                          color: replayState.atStart
                              ? Colors.white24
                              : Colors.white),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(replayNotifierProvider(gameId).notifier)
                          .togglePlay(),
                      icon: Icon(
                        replayState.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    IconButton(
                      onPressed: replayState.atEnd
                          ? null
                          : () => ref
                              .read(replayNotifierProvider(gameId).notifier)
                              .stepForward(),
                      icon: Icon(Icons.skip_next,
                          color:
                              replayState.atEnd ? Colors.white24 : Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      '${replayState.currentEventIndex + 1}/${replayState.totalEvents}',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HandRow extends StatelessWidget {
  final List<dynamic> cards;

  const _HandRow({required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox(height: 50);
    }
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: CardWidget(
                    card: c,
                    width: 40,
                    height: 56,
                    enabled: false,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  final double speed;
  final VoidCallback onTap;

  const _SpeedChip({required this.speed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${speed}x',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }
}
