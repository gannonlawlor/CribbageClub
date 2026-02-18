import 'package:flutter/material.dart';
import '../../../core/models/game_history_event.dart';
import '../../../core/models/score_breakdown.dart';

class HistoryLog extends StatelessWidget {
  final List<GameHistoryEvent> events;
  final String? playerId;

  const HistoryLog({super.key, required this.events, this.playerId});

  String _playerLabel(String id) {
    return id == playerId ? 'You' : 'Opponent';
  }

  String _breakdownSummary(ScoreBreakdown b) {
    final parts = <String>[];
    if (b.fifteens > 0) parts.add('${b.fifteens} fifteens');
    if (b.pairs > 0) parts.add('${b.pairs} pairs');
    if (b.runs > 0) parts.add('${b.runs} runs');
    if (b.flushes > 0) parts.add('${b.flushes} flush');
    if (b.nobs > 0) parts.add('${b.nobs} nobs');
    return parts.isEmpty ? '' : ' (${parts.join(', ')})';
  }

  String _describe(GameHistoryEvent event) {
    return switch (event) {
      RoundStarted(:final roundNumber) => 'Round $roundNumber started',
      CardsDealt() => 'Cards dealt',
      DeckCut(
        :final cuttingPlayerId,
        :final cutCard,
        :final dealerScoredNobs,
      ) =>
        '${_playerLabel(cuttingPlayerId)} cut ${cutCard.rank.display}${cutCard.suit.symbol}'
            '${dealerScoredNobs ? " - Nobs! +2" : ""}',
      CardPlayed(
        :final playerId,
        :final card,
        :final newCount,
        :final pointsScored,
      ) =>
        '${_playerLabel(playerId)} played ${card.rank.display}${card.suit.symbol} (count: $newCount)'
            '${pointsScored > 0 ? " +$pointsScored" : ""}',
      GoAnnounced(:final playerId, :final pointsScored) =>
        '${_playerLabel(playerId)} said Go${pointsScored > 0 ? " +$pointsScored" : ""}',
      PeggingEnded() => 'Pegging ended',
      HandCounted(:final playerId, :final totalPoints, :final scoreBreakdown) =>
        '${_playerLabel(playerId)} counted $totalPoints pts${_breakdownSummary(scoreBreakdown)}',
      CribCounted(
        :final dealerPlayerId,
        :final totalPoints,
        :final scoreBreakdown,
      ) =>
        '${_playerLabel(dealerPlayerId)} counted $totalPoints in crib${_breakdownSummary(scoreBreakdown)}',
      GameEnded(:final winnerPlayerId, :final finalScore) =>
        '${_playerLabel(winnerPlayerId)} wins with $finalScore!',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.all(8),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[events.length - 1 - index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              _describe(event),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          );
        },
      ),
    );
  }
}
