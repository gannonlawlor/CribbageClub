import '../../../core/models/card.dart';
import '../../../core/models/game_history_event.dart';
import '../../../core/models/score_breakdown.dart';
import '../../../shared/utils/forfeit_text.dart';

/// A snapshot of visual state at a given event index during replay.
class ReplaySnapshot {
  final Map<String, List<PlayingCard>> hands;
  final Map<String, int> scores;
  final PlayingCard? cutCard;
  final List<PlayingCard> playedCards;
  final int peggingCount;
  final List<PlayingCard> cribCards;
  final bool cribRevealed;
  final String? dealerPlayerId;
  final int roundNumber;
  final String eventDescription;
  final bool isGameOver;
  final String? winnerPlayerId;

  const ReplaySnapshot({
    this.hands = const {},
    this.scores = const {},
    this.cutCard,
    this.playedCards = const [],
    this.peggingCount = 0,
    this.cribCards = const [],
    this.cribRevealed = false,
    this.dealerPlayerId,
    this.roundNumber = 0,
    this.eventDescription = '',
    this.isGameOver = false,
    this.winnerPlayerId,
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
    var peggingCount = 0;
    var cribCards = <PlayingCard>[];
    var cribRevealed = false;
    String? dealerPlayerId;
    var roundNumber = 0;
    var eventDescription = '';
    var isGameOver = false;
    String? winnerPlayerId;

    final end = currentEventIndex.clamp(0, events.length - 1);

    String getName(String id) => playerNames[id] ?? id;

    for (var i = 0; i <= end; i++) {
      final event = events[i];

      if (event is RoundStarted) {
        // Reset for new round
        for (final id in playerIds) {
          hands[id] = [];
        }
        cutCard = null;
        playedCards = [];
        peggingCount = 0;
        cribCards = [];
        cribRevealed = false;
        roundNumber = event.roundNumber;
        eventDescription = 'Round ${event.roundNumber} started';
      } else if (event is CardsDealt) {
        for (final entry in event.dealtHands.entries) {
          hands[entry.key] = List.from(entry.value);
        }
        eventDescription = 'Cards dealt';
      } else if (event is DeckCut) {
        cutCard = event.cutCard;
        dealerPlayerId = playerIds.firstWhere(
          (id) => id != event.cuttingPlayerId,
          orElse: () => playerIds.first,
        );
        if (event.dealerScoredNobs) {
          scores[dealerPlayerId] = (scores[dealerPlayerId] ?? 0) + 2;
          eventDescription =
              '${getName(event.cuttingPlayerId)} cut ${event.cutCard.rank.display}${event.cutCard.suit.symbol} — His Nobs! +2 for dealer';
        } else {
          eventDescription =
              '${getName(event.cuttingPlayerId)} cut ${event.cutCard.rank.display}${event.cutCard.suit.symbol}';
        }
      } else if (event is CardPlayed) {
        hands[event.playerId]?.remove(event.card);
        playedCards = [...playedCards, event.card];
        peggingCount = event.newCount;
        scores[event.playerId] =
            (scores[event.playerId] ?? 0) + event.pointsScored;
        eventDescription =
            '${getName(event.playerId)} played ${event.card.rank.display}${event.card.suit.symbol} (count: ${event.newCount})';
        if (event.pointsScored > 0) {
          eventDescription +=
              ' — ${event.pointsScored} pts${event.scoringReason != null ? ' (${event.scoringReason})' : ''}';
        }
      } else if (event is GoAnnounced) {
        scores[event.playerId] =
            (scores[event.playerId] ?? 0) + event.pointsScored;
        eventDescription = '${getName(event.playerId)} says "Go"';
        if (event.pointsScored > 0) {
          eventDescription += ' — ${event.pointsScored} pts';
        }
      } else if (event is PeggingEnded) {
        playedCards = [];
        peggingCount = 0;
        eventDescription = 'Pegging ended';
      } else if (event is HandCounted) {
        hands[event.playerId] = List.from(event.hand);
        scores[event.playerId] =
            (scores[event.playerId] ?? 0) + event.totalPoints;
        eventDescription =
            '${getName(event.playerId)} hand: ${event.totalPoints} pts${_breakdownText(event.scoreBreakdown)}';
      } else if (event is CribCounted) {
        cribCards = List.from(event.cribCards);
        cribRevealed = true;
        scores[event.dealerPlayerId] =
            (scores[event.dealerPlayerId] ?? 0) + event.totalPoints;
        eventDescription =
            '${getName(event.dealerPlayerId)} crib: ${event.totalPoints} pts${_breakdownText(event.scoreBreakdown)}';
      } else if (event is GameEnded) {
        isGameOver = true;
        winnerPlayerId = event.winnerPlayerId;
        eventDescription =
            '${getName(event.winnerPlayerId)} wins with ${event.finalScore} points!';
      } else if (event is GameForfeited) {
        isGameOver = true;
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
      peggingCount: peggingCount,
      cribCards: cribCards,
      cribRevealed: cribRevealed,
      dealerPlayerId: dealerPlayerId,
      roundNumber: roundNumber,
      eventDescription: eventDescription,
      isGameOver: isGameOver,
      winnerPlayerId: winnerPlayerId,
    );
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
