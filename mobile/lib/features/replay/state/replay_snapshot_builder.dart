import '../../../core/models/card.dart';
import '../../../core/models/game_history_event.dart';
import '../../../core/models/score_breakdown.dart';
import '../../../shared/utils/forfeit_text.dart';

/// Where the replayed game stands at the current event — drives the stage
/// caption and headline on the replay table.
enum ReplayPhase { start, deal, cut, pegging, counting, gameOver }

/// A snapshot of visual state at a given event index during replay.
class ReplaySnapshot {
  final Map<String, List<PlayingCard>> hands;
  final Map<String, int> scores;
  final PlayingCard? cutCard;
  final List<PlayingCard> playedCards;

  /// Parallel to [playedCards]: who played each card on the pile.
  final List<String> playedCardOwners;
  final int peggingCount;
  final List<PlayingCard> cribCards;
  final bool cribRevealed;
  final String? dealerPlayerId;
  final int roundNumber;
  final String eventDescription;
  final ReplayPhase phase;

  /// Who made the move being shown — lights that player's bar.
  final String? actingPlayerId;

  /// Points the acting player just took, with its reason when the engine
  /// gave one ("fifteen", "pair"). Drives the score pill.
  final int scoreDelta;
  final String? scoreReason;
  final bool isGameOver;
  final String? winnerPlayerId;
  final String? forfeitReason;

  const ReplaySnapshot({
    this.hands = const {},
    this.scores = const {},
    this.cutCard,
    this.playedCards = const [],
    this.playedCardOwners = const [],
    this.peggingCount = 0,
    this.cribCards = const [],
    this.cribRevealed = false,
    this.dealerPlayerId,
    this.roundNumber = 0,
    this.eventDescription = '',
    this.phase = ReplayPhase.start,
    this.actingPlayerId,
    this.scoreDelta = 0,
    this.scoreReason,
    this.isGameOver = false,
    this.winnerPlayerId,
    this.forfeitReason,
  });
}

/// Builds a ReplaySnapshot by walking events from index 0 to currentEventIndex.
class ReplaySnapshotBuilder {
  ReplaySnapshotBuilder._();

  static ReplaySnapshot buildSnapshot(
    List<GameHistoryEvent> events,
    int currentEventIndex,
    List<String> playerIds,
    Map<String, String> playerNames,
  ) {
    final hands = <String, List<PlayingCard>>{
      for (final id in playerIds) id: [],
    };
    final scores = <String, int>{for (final id in playerIds) id: 0};
    PlayingCard? cutCard;
    var playedCards = <PlayingCard>[];
    var playedCardOwners = <String>[];
    var peggingCount = 0;
    var cribCards = <PlayingCard>[];
    var cribRevealed = false;
    String? dealerPlayerId;
    var roundNumber = 0;
    var eventDescription = '';
    var phase = ReplayPhase.start;
    String? actingPlayerId;
    var scoreDelta = 0;
    String? scoreReason;
    var isGameOver = false;
    String? winnerPlayerId;
    String? forfeitReason;

    final end = currentEventIndex.clamp(0, events.length - 1);

    String getName(String id) => playerNames[id] ?? id;

    for (var i = 0; i <= end; i++) {
      final event = events[i];
      // Per-event fields — cleared each step so they only describe the move
      // currently on screen.
      actingPlayerId = null;
      scoreDelta = 0;
      scoreReason = null;

      if (event is RoundStarted) {
        // Reset for new round
        for (final id in playerIds) {
          hands[id] = [];
        }
        cutCard = null;
        playedCards = [];
        playedCardOwners = [];
        peggingCount = 0;
        cribCards = [];
        cribRevealed = false;
        roundNumber = event.roundNumber;
        phase = ReplayPhase.deal;
        eventDescription = 'Round ${event.roundNumber} started';
      } else if (event is CardsDealt) {
        for (final entry in event.dealtHands.entries) {
          hands[entry.key] = List.from(entry.value);
        }
        phase = ReplayPhase.deal;
        eventDescription = 'Cards dealt';
      } else if (event is DeckCut) {
        cutCard = event.cutCard;
        dealerPlayerId = playerIds.firstWhere(
          (id) => id != event.cuttingPlayerId,
          orElse: () => playerIds.first,
        );
        // Discards are never recorded, so the six dealt cards would stay in
        // hand all through pegging. The count that closes this round is the
        // only record of what each player kept.
        for (final entry in _keptHands(events, i + 1).entries) {
          hands[entry.key] = [
            for (final card in entry.value)
              if (card != cutCard) card,
          ];
        }
        phase = ReplayPhase.cut;
        actingPlayerId = event.cuttingPlayerId;
        final cutName =
            '${event.cutCard.rank.display}${event.cutCard.suit.symbol}';
        if (event.dealerScoredNobs) {
          scores[dealerPlayerId] = (scores[dealerPlayerId] ?? 0) + 2;
          actingPlayerId = dealerPlayerId;
          scoreDelta = 2;
          scoreReason = 'his nobs';
          eventDescription =
              '${getName(event.cuttingPlayerId)} cut $cutName — his nobs, 2 to the dealer';
        } else {
          eventDescription = '${getName(event.cuttingPlayerId)} cut $cutName';
        }
      } else if (event is CardPlayed) {
        hands[event.playerId]?.remove(event.card);
        playedCards = [...playedCards, event.card];
        playedCardOwners = [...playedCardOwners, event.playerId];
        peggingCount = event.newCount;
        scores[event.playerId] =
            (scores[event.playerId] ?? 0) + event.pointsScored;
        phase = ReplayPhase.pegging;
        actingPlayerId = event.playerId;
        scoreDelta = event.pointsScored;
        scoreReason = event.scoringReason;
        eventDescription =
            '${getName(event.playerId)} played ${event.card.rank.display}${event.card.suit.symbol}';
      } else if (event is GoAnnounced) {
        scores[event.playerId] =
            (scores[event.playerId] ?? 0) + event.pointsScored;
        phase = ReplayPhase.pegging;
        actingPlayerId = event.playerId;
        scoreDelta = event.pointsScored;
        scoreReason = event.pointsScored > 0 ? 'go' : null;
        eventDescription = '${getName(event.playerId)} says go';
      } else if (event is PeggingEnded) {
        playedCards = [];
        playedCardOwners = [];
        peggingCount = 0;
        phase = ReplayPhase.counting;
        eventDescription = 'Pegging ended';
      } else if (event is HandCounted) {
        // The counted hand carries the starter with it; the table already
        // shows that card in the cluster.
        hands[event.playerId] = [
          for (final card in event.hand)
            if (card != cutCard) card,
        ];
        scores[event.playerId] =
            (scores[event.playerId] ?? 0) + event.totalPoints;
        phase = ReplayPhase.counting;
        actingPlayerId = event.playerId;
        scoreDelta = event.totalPoints;
        scoreReason = 'hand';
        eventDescription =
            '${getName(event.playerId)} counts ${event.totalPoints}${_breakdownText(event.scoreBreakdown)}';
      } else if (event is CribCounted) {
        cribCards = List.from(event.cribCards);
        cribRevealed = true;
        scores[event.dealerPlayerId] =
            (scores[event.dealerPlayerId] ?? 0) + event.totalPoints;
        phase = ReplayPhase.counting;
        actingPlayerId = event.dealerPlayerId;
        scoreDelta = event.totalPoints;
        scoreReason = 'crib';
        eventDescription =
            '${getName(event.dealerPlayerId)} takes ${event.totalPoints} in the crib${_breakdownText(event.scoreBreakdown)}';
      } else if (event is GameEnded) {
        isGameOver = true;
        phase = ReplayPhase.gameOver;
        winnerPlayerId = event.winnerPlayerId;
        actingPlayerId = event.winnerPlayerId;
        eventDescription =
            '${getName(event.winnerPlayerId)} wins with ${event.finalScore}';
      } else if (event is GameForfeited) {
        isGameOver = true;
        phase = ReplayPhase.gameOver;
        forfeitReason = event.reason;
        // The winner is the other player
        winnerPlayerId = playerIds.firstWhere(
          (id) => id != event.forfeitingPlayerId,
          orElse: () => playerIds.first,
        );
        eventDescription =
            '${getName(event.forfeitingPlayerId)} ${forfeitVerb(event.reason)}';
      }
    }

    return ReplaySnapshot(
      hands: hands,
      scores: scores,
      cutCard: cutCard,
      playedCards: playedCards,
      playedCardOwners: playedCardOwners,
      peggingCount: peggingCount,
      cribCards: cribCards,
      cribRevealed: cribRevealed,
      dealerPlayerId: dealerPlayerId,
      roundNumber: roundNumber,
      eventDescription: eventDescription,
      phase: phase,
      actingPlayerId: actingPlayerId,
      scoreDelta: scoreDelta,
      scoreReason: scoreReason,
      isGameOver: isGameOver,
      winnerPlayerId: winnerPlayerId,
      forfeitReason: forfeitReason,
    );
  }

  /// The hand each player takes into pegging this round, read from the
  /// [HandCounted] events that close it. Scanning stops at the next round.
  static Map<String, List<PlayingCard>> _keptHands(
    List<GameHistoryEvent> events,
    int from,
  ) {
    final kept = <String, List<PlayingCard>>{};
    for (var i = from; i < events.length; i++) {
      final event = events[i];
      if (event is RoundStarted) break;
      if (event is HandCounted) {
        kept.putIfAbsent(event.playerId, () => List.from(event.hand));
      }
    }
    return kept;
  }

  static String _breakdownText(ScoreBreakdown b) {
    final parts = <String>[];
    if (b.fifteens > 0) parts.add('${b.fifteens} fifteens');
    if (b.pairs > 0) parts.add('${b.pairs} pairs');
    if (b.runs > 0) parts.add('${b.runs} runs');
    if (b.flushes > 0) parts.add('${b.flushes} flush');
    if (b.nobs > 0) parts.add('${b.nobs} nobs');
    return parts.isEmpty ? '' : ' (${parts.join(', ')})';
  }
}
