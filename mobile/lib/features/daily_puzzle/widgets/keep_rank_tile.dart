import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../game/widgets/card_widget.dart';
import '../models/daily_puzzle.dart';

class KeepRankTile extends StatelessWidget {
  final KeepOption option;
  final bool isPlayerPick;
  final bool isOptimal;
  final VoidCallback? onExplain;

  const KeepRankTile({
    super.key,
    required this.option,
    this.isPlayerPick = false,
    this.isOptimal = false,
    this.onExplain,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Green = "you". Only the player's own pick gets the ring + wash so the two
    // greens (best vs. yours) never fight; the best keep is marked by its "#1"
    // rank and score reading in the win color instead.
    final Color? borderColor = isPlayerPick ? colors.accent : null;
    final Color bgColor = isPlayerPick
        ? colors.accent.withValues(alpha: 0.12)
        : colors.surfaceDim;
    final Color rankColor = isOptimal
        ? colors.success
        : (isPlayerPick ? colors.accent : colors.textSecondary);
    final Color scoreColor = isOptimal ? colors.success : colors.textPrimary;

    return GestureDetector(
      onTap: onExplain,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1.5)
              : Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 36,
              child: Text(
                '#${option.rank}',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  color: rankColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
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
                    '  ·  crib ${option.averageCribScore > 0 ? '+' : ''}${option.averageCribScore.toStringAsFixed(1)}',
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
            if (isPlayerPick)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.person, color: colors.accent, size: 16),
              ),
            if (onExplain != null)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.info_outline,
                  color: colors.textTertiary,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
