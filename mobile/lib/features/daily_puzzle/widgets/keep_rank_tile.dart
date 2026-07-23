import 'package:flutter/material.dart';

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
    // Green = "you". Only the player's own pick gets the ring + wash so the two
    // greens (best vs. yours) never fight; the best keep is marked by its "#1"
    // rank and score reading in the win color instead.
    final Color rankColor = isOptimal
        ? colors.evOptimal
        : (isPlayerPick ? colors.accent : colors.textTertiary);
    final Color scoreColor = isOptimal ? colors.evOptimal : colors.textPrimary;

    // A row in a grouped panel, not a floating tile: your own pick takes the
    // data-table "you" wash and an accent rank (design language §4) — no room
    // for a label, and colour is how identity reads everywhere else.
    return InkWell(
      onTap: onExplain,
      child: Container(
        color: isPlayerPick
            ? colors.pegPlayer.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 26,
              child: Text(
                '${option.rank}',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  color: rankColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 2),
            // Kept cards
            for (final card in option.keep)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: CardWidget(
                  card: card,
                  width: 20,
                  height: 28,
                  enabled: false,
                ),
              ),
            const SizedBox(width: 4),
            // Discarded cards (dimmed)
            Opacity(
              opacity: 0.4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final card in option.discard)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: CardWidget(
                        card: card,
                        width: 20,
                        height: 28,
                        enabled: false,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Scores (fills remaining width, right-aligned)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  const SizedBox(height: 1),
                  Text(
                    'hand ${option.averageHandScore.toStringAsFixed(1)}'
                    '  ·  crib ${isDealer ? '+' : '−'}'
                    '${option.averageCribScore.toStringAsFixed(1)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 11,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            // Trailing indicators
            if (onExplain != null)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.info_outline,
                  color: colors.textDisabled,
                  size: 15,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
