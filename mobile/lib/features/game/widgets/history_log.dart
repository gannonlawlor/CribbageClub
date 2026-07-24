import 'package:flutter/material.dart';
import '../../../config/constants.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/card.dart';
import '../../../core/models/game_history_event.dart';
import '../../../core/models/score_breakdown.dart';
import '../../../shared/utils/forfeit_text.dart';
import 'card_widget.dart';

/// One line of the log: an actor (null = neutral separator), the predicate
/// text, and any cards the event turned over — a hand is worth seeing rather
/// than reading.
class _Entry {
  final String? actorId;
  final String text;
  final bool emphasize;

  /// Rendered as small card faces between [text] and [textAfter].
  final List<PlayingCard> cards;
  final String textAfter;

  const _Entry({
    this.actorId,
    required this.text,
    this.emphasize = false,
    this.cards = const [],
    this.textAfter = '',
  });
}

/// Chronological game log. Each entry is attributed with the design language's
/// player identity colours — `--player-self` (green) for you, `--player-opp`
/// (ivory) for the opponent — via a left identity edge, a coloured actor
/// label, and a subtle wash on your own rows. Events with no actor (round
/// start, deal, pegging end) render as centred separators.
class HistoryLog extends StatelessWidget {
  /// Small enough for a log row, large enough that the index still reads.
  static const double _logCardWidth = 34;

  /// A hand gets its own line, so it can afford a little more width.
  static const double _logHandCardWidth = 38;

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

  /// The cards an entry turned over. A single card sits inside the sentence;
  /// a whole hand gets its own line under it, where there's room to lay it
  /// out without the text wrapping around it.
  Widget _cardRow(List<PlayingCard> cards, double width) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          CardWidget(
            card: cards[i],
            faceUp: true,
            enabled: false,
            width: width,
            height: width / AppConstants.cardAspectRatio,
          ),
        ],
      ],
    );
  }

  /// Splits an event into its actor (null = neutral) and the predicate text
  /// that follows the actor label.
  _Entry _entry(GameHistoryEvent event, String? viewerId) {
    return switch (event) {
      RoundStarted(:final roundNumber) => _Entry(text: 'Round $roundNumber'),
      CardsDealt() => const _Entry(text: 'Cards dealt'),
      DeckCut(
        :final cuttingPlayerId,
        :final cutCard,
        :final dealerScoredNobs,
      ) =>
        _Entry(
          actorId: cuttingPlayerId,
          text: 'cut',
          cards: [cutCard],
          textAfter: dealerScoredNobs ? '· nobs +2' : '',
        ),
      CardPlayed(
        :final playerId,
        :final card,
        :final newCount,
        :final pointsScored,
      ) =>
        _Entry(
          actorId: playerId,
          text: 'played',
          cards: [card],
          textAfter:
              'count $newCount${pointsScored > 0 ? ' · +$pointsScored' : ''}',
        ),
      GoAnnounced(:final playerId, :final pointsScored) => _Entry(
        actorId: playerId,
        text: 'said Go${pointsScored > 0 ? ' · +$pointsScored' : ''}',
      ),
      PeggingEnded() => const _Entry(text: 'Pegging ended'),
      HandCounted(
        :final playerId,
        :final hand,
        :final totalPoints,
        :final scoreBreakdown,
      ) =>
        _Entry(
          actorId: playerId,
          text: 'counted $totalPoints',
          cards: hand,
          textAfter: _breakdownSummary(scoreBreakdown).trimLeft(),
        ),
      CribCounted(
        :final dealerPlayerId,
        :final cribCards,
        :final totalPoints,
        :final scoreBreakdown,
      ) =>
        _Entry(
          actorId: dealerPlayerId,
          text: 'counted $totalPoints in crib',
          cards: cribCards,
          textAfter: _breakdownSummary(scoreBreakdown).trimLeft(),
        ),
      GameEnded(:final winnerPlayerId, :final finalScore) => _Entry(
        actorId: winnerPlayerId,
        text:
            '${winnerPlayerId == viewerId ? 'win' : 'wins'}'
            ' with $finalScore',
        emphasize: true,
      ),
      GameForfeited(:final forfeitingPlayerId, :final reason) => _Entry(
        actorId: forfeitingPlayerId,
        text: forfeitVerb(reason),
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
                          padding: const EdgeInsets.fromLTRB(9, 6, 10, 6),
                          child: Builder(
                            builder: (context) {
                              final bodyStyle = TextStyle(
                                color: entry.emphasize
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                                fontSize: 13,
                                fontWeight: entry.emphasize
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              );
                              // One card reads as part of the sentence; a hand
                              // goes underneath it on its own line.
                              final inline = entry.cards.length == 1;
                              final sentence = Text.rich(
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
                                      style: bodyStyle,
                                    ),
                                    if (inline)
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          child: _cardRow(
                                            entry.cards,
                                            _logCardWidth,
                                          ),
                                        ),
                                      ),
                                    if (entry.textAfter.isNotEmpty)
                                      TextSpan(
                                        text: inline
                                            ? entry.textAfter
                                            : ' ${entry.textAfter}',
                                        style: bodyStyle,
                                      ),
                                  ],
                                ),
                                style: const TextStyle(height: 1.3),
                              );

                              if (inline || entry.cards.isEmpty) {
                                return sentence;
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  sentence,
                                  const SizedBox(height: 6),
                                  _cardRow(entry.cards, _logHandCardWidth),
                                ],
                              );
                            },
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
