import 'package:flutter/material.dart';
import '../../../config/constants.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/card.dart';
import '../../../core/models/game_history_event.dart';
import '../../../shared/utils/forfeit_text.dart';
import '../../../shared/utils/score_calculator.dart';
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
  static const double _logHandCardWidth = 34;

  /// The scoring-group rows sit narrower still — a few cards plus a label.
  static const double _logComboCardWidth = 26;

  final List<GameHistoryEvent> events;
  final String? playerId;

  const HistoryLog({super.key, required this.events, this.playerId});

  /// The starter for the round [eventIndex] falls in — a hand or crib count
  /// needs it to work out which cards formed each score. There's exactly one
  /// DeckCut per round, always before the count, so the nearest earlier one is
  /// this round's.
  PlayingCard? _cutFor(int eventIndex) {
    for (int i = eventIndex; i >= 0; i--) {
      final e = events[i];
      if (e is DeckCut) return e.cutCard;
    }
    return null;
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
      // Hand/crib counts render as their own score block (see itemBuilder);
      // these cases keep the switch exhaustive and are otherwise unused.
      HandCounted(:final playerId, :final totalPoints) => _Entry(
        actorId: playerId,
        text: 'counted $totalPoints',
      ),
      CribCounted(:final dealerPlayerId, :final totalPoints) => _Entry(
        actorId: dealerPlayerId,
        text: 'counted $totalPoints in crib',
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
          final eventIndex = events.length - 1 - index;
          final event = events[eventIndex];

          // Hand and crib counts get a full breakdown: the whole hand, then a
          // line per scoring group showing just the cards that made it.
          if (event is HandCounted) {
            return _scoreBlock(
              context,
              actorId: event.playerId,
              title: 'Hand score',
              total: event.totalPoints,
              cards: event.hand,
              cutCard: _cutFor(eventIndex),
              isCrib: false,
            );
          }
          if (event is CribCounted) {
            return _scoreBlock(
              context,
              actorId: event.dealerPlayerId,
              title: 'Crib score',
              total: event.totalPoints,
              cards: event.cribCards,
              cutCard: _cutFor(eventIndex),
              isCrib: true,
            );
          }

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

  /// A counted hand or crib: the identity edge, a "You · Hand score · 5"
  /// header, the whole hand and starter, then a line for each scoring group
  /// showing only the cards that earned it.
  Widget _scoreBlock(
    BuildContext context, {
    required String actorId,
    required String title,
    required int total,
    required List<PlayingCard> cards,
    required PlayingCard? cutCard,
    required bool isCrib,
  }) {
    final colors = context.appColors;
    final isYou = actorId == playerId;
    final identity = isYou ? colors.pegPlayer : colors.pegOpponent;
    final combos = cutCard == null
        ? const <ScoringCombination>[]
        : calculateDetailedBreakdown(
            cards,
            cutCard,
            isCrib: isCrib,
          ).combinations;

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
                    padding: const EdgeInsets.fromLTRB(9, 7, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: isYou ? 'You' : 'Opponent',
                                style: TextStyle(
                                  color: identity,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: ' · $title · ',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              TextSpan(
                                text: '$total',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 7),
                        // The whole hand, then the starter set a little apart.
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _cardRow(cards, _logHandCardWidth),
                            if (cutCard != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 1,
                                height:
                                    _logHandCardWidth /
                                    AppConstants.cardAspectRatio *
                                    0.8,
                                color: colors.border,
                              ),
                              const SizedBox(width: 6),
                              _cardRow([cutCard], _logHandCardWidth),
                            ],
                          ],
                        ),
                        if (combos.isEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            cutCard == null ? '' : 'Nothing to count',
                            style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ] else
                          for (final c in combos)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  _cardRow(c.cards, _logComboCardWidth),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${c.points} for ${scoringReason(c)}',
                                      style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
