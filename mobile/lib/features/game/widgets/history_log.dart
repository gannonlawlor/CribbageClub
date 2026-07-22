import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/game_history_event.dart';
import '../../../core/models/score_breakdown.dart';

/// Chronological game log. Each entry is attributed with the design language's
/// player identity colours — `--player-self` (green) for you, `--player-opp`
/// (ivory) for the opponent — via a left identity edge, a coloured actor
/// label, and a subtle wash on your own rows. Events with no actor (round
/// start, deal, pegging end) render as centred separators.
class HistoryLog extends StatelessWidget {
  final List<GameHistoryEvent> events;
  final String? playerId;

  const HistoryLog({super.key, required this.events, this.playerId});

  String _breakdownSummary(ScoreBreakdown b) {
    final parts = <String>[];
    if (b.fifteens > 0) parts.add('${b.fifteens} fifteens');
    if (b.pairs > 0) parts.add('${b.pairs} pairs');
    if (b.runs > 0) parts.add('${b.runs} runs');
    if (b.flushes > 0) parts.add('${b.flushes} flush');
    if (b.nobs > 0) parts.add('${b.nobs} nobs');
    return parts.isEmpty ? '' : ' (${parts.join(', ')})';
  }

  /// Splits an event into its actor (null = neutral) and the predicate text
  /// that follows the actor label.
  ({String? actorId, String text, bool emphasize}) _entry(
    GameHistoryEvent event,
    String? viewerId,
  ) {
    return switch (event) {
      RoundStarted(:final roundNumber) => (
          actorId: null,
          text: 'Round $roundNumber',
          emphasize: false,
        ),
      CardsDealt() => (actorId: null, text: 'Cards dealt', emphasize: false),
      DeckCut(
        :final cuttingPlayerId,
        :final cutCard,
        :final dealerScoredNobs,
      ) =>
        (
          actorId: cuttingPlayerId,
          text: 'cut ${cutCard.rank.display}${cutCard.suit.symbol}'
              '${dealerScoredNobs ? ' · nobs +2' : ''}',
          emphasize: false,
        ),
      CardPlayed(
        :final playerId,
        :final card,
        :final newCount,
        :final pointsScored,
      ) =>
        (
          actorId: playerId,
          text: 'played ${card.rank.display}${card.suit.symbol}'
              ' · count $newCount${pointsScored > 0 ? ' · +$pointsScored' : ''}',
          emphasize: false,
        ),
      GoAnnounced(:final playerId, :final pointsScored) => (
          actorId: playerId,
          text: 'said Go${pointsScored > 0 ? ' · +$pointsScored' : ''}',
          emphasize: false,
        ),
      PeggingEnded() => (
          actorId: null,
          text: 'Pegging ended',
          emphasize: false,
        ),
      HandCounted(:final playerId, :final totalPoints, :final scoreBreakdown) =>
        (
          actorId: playerId,
          text: 'counted $totalPoints${_breakdownSummary(scoreBreakdown)}',
          emphasize: false,
        ),
      CribCounted(
        :final dealerPlayerId,
        :final totalPoints,
        :final scoreBreakdown,
      ) =>
        (
          actorId: dealerPlayerId,
          text: 'counted $totalPoints in crib'
              '${_breakdownSummary(scoreBreakdown)}',
          emphasize: false,
        ),
      GameEnded(:final winnerPlayerId, :final finalScore) => (
          actorId: winnerPlayerId,
          text: '${winnerPlayerId == viewerId ? 'win' : 'wins'}'
              ' with $finalScore',
          emphasize: true,
        ),
      GameForfeited(:final forfeitingPlayerId, :final reason) => (
          actorId: forfeitingPlayerId,
          text: 'forfeited ($reason)',
          emphasize: true,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    return Container(
      constraints: const BoxConstraints(maxHeight: 340),
      decoration: BoxDecoration(
        color: colors.surfaceDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: ListView.builder(
        reverse: true,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[events.length - 1 - index];
          final entry = _entry(event, playerId);

          if (entry.actorId == null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Center(
                child: Text(
                  entry.text.toUpperCase(),
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            );
          }

          final isYou = entry.actorId == playerId;
          final identity = isYou ? colors.pegPlayer : colors.pegOpponent;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                color: isYou
                    ? colors.pegPlayer.withValues(alpha: 0.08)
                    : Colors.transparent,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 3, color: identity),
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(9, 6, 10, 6),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: isYou ? 'You ' : 'Opponent ',
                                  style: TextStyle(
                                    color: identity,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: entry.text,
                                  style: TextStyle(
                                    color: entry.emphasize
                                        ? colors.textPrimary
                                        : colors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: entry.emphasize
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            style: const TextStyle(height: 1.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
