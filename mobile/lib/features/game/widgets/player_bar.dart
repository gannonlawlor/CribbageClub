import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

/// In-game player identity bar (design language §4 "Player bar"):
/// chrome surface, 3px identity edge on the left, avatar initial,
/// name + rating + DEALER chip, and a large tabular score on the right
/// keyed by a dot in the player's lane colour.
///
/// Progress to 121 is carried by the perimeter board, not a bar in here.
class PlayerBar extends StatelessWidget {
  /// Height of the bar — the game screen reserves this when laying out.
  static const double height = 46;

  final String name;
  final int score;
  final bool isSelf;
  final bool isDealer;
  final bool isActive;
  final int? rating;

  const PlayerBar({
    super.key,
    required this.name,
    required this.score,
    required this.isSelf,
    this.isDealer = false,
    this.isActive = false,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final identity = isSelf ? colors.pegPlayer : colors.pegOpponent;
    final edge = isActive ? identity : identity.withValues(alpha: 0.4);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: height,
        color: colors.surfaceChrome,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 3,
              color: edge,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colors.surfaceDim,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelf
                              ? colors.textPrimary
                              : colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(width: 7),
                      Text(
                        '($rating)',
                        style: TextStyle(
                          color: colors.ratingGold,
                          fontSize: 12,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                    if (isDealer) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceDim,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DEALER',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.54,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: identity,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$score',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 22,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
