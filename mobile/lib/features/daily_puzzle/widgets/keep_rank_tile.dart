import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../config/constants.dart';
import '../../../config/theme/app_colors.dart';
import '../../game/widgets/card_widget.dart';
import '../models/daily_puzzle.dart';

class KeepRankTile extends StatelessWidget {
  final KeepOption option;
  final bool isPlayerPick;
  final bool isOptimal;

  /// The crib is only added to your total when it's yours; otherwise the
  /// engine subtracts it, so the sign has to say which.
  final bool isDealer;
  final VoidCallback? onExplain;

  /// Cards stop growing here — past this they crowd the score column.
  static const double _maxCardWidth = 40;
  static const double _cardGap = 3;

  const KeepRankTile({
    super.key,
    required this.option,
    this.isPlayerPick = false,
    this.isOptimal = false,
    this.isDealer = false,
    this.onExplain,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Green = "you". Only the player's own pick gets the wash so the two
    // greens (best vs. yours) never fight; the best keep is marked by its
    // rank and score reading in the win color instead.
    final Color rankColor = isOptimal
        ? colors.evOptimal
        : (isPlayerPick ? colors.accent : colors.textTertiary);
    final Color scoreColor = isOptimal ? colors.evOptimal : colors.textPrimary;
    final crib = option.averageCribScore;

    // A row in a grouped panel, not a floating tile: your own pick takes the
    // data-table "you" wash and an accent rank (design language §4) — no room
    // for a label, and colour is how identity reads everywhere else.
    //
    // The hand/crib breakdown sits on its own line so the six cards get the
    // width instead of competing with it.
    return InkWell(
      onTap: onExplain,
      child: Container(
        color: isPlayerPick
            ? colors.pegPlayer.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '${option.rank}',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: rankColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Expanded(child: _Cards(option: option)),
                const SizedBox(width: 10),
                Text(
                  option.netScore.toStringAsFixed(1),
                  maxLines: 1,
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (onExplain != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.info_outline,
                    color: colors.textDisabled,
                    size: 15,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(
                'hand ${option.averageHandScore.toStringAsFixed(1)}'
                '  ·  crib ${isDealer ? '+' : '−'}${crib.toStringAsFixed(1)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The four kept cards, then the two thrown at 40% — the same keep-then-
/// dimmed-discard reading the analysis screen uses.
class _Cards extends StatelessWidget {
  final KeepOption option;

  const _Cards({required this.option});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const count = 6;
        // Every card carries a trailing gap, and the keep/throw split adds
        // two more — eight in total to subtract before dividing.
        final available = constraints.maxWidth - KeepRankTile._cardGap * 8;
        final width = math.min(KeepRankTile._maxCardWidth, available / count);
        final height = width / AppConstants.cardAspectRatio;

        Widget card(dynamic c) => Padding(
          padding: const EdgeInsets.only(right: KeepRankTile._cardGap),
          child: CardWidget(
            card: c,
            width: width,
            height: height,
            enabled: false,
          ),
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in option.keep) card(c),
            const SizedBox(width: KeepRankTile._cardGap * 2),
            Opacity(
              opacity: 0.4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [for (final c in option.discard) card(c)],
              ),
            ),
          ],
        );
      },
    );
  }
}
