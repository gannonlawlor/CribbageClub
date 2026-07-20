import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

/// In-game player identity bar (design language §4 "Player bar"):
/// chrome surface, 3px identity edge, avatar initial, name + DEALER chip,
/// progress-to-121 track, and a large tabular score on the right.
class PlayerBar extends StatelessWidget {
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
    final progress = (score / 121).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 52,
        color: colors.surfaceChrome,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: edge),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.surfaceDim,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
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
                                const SizedBox(width: 6),
                                Text(
                                  '($rating)',
                                  style: TextStyle(
                                    color: colors.ratingGold,
                                    fontSize: 12,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                              if (isDealer) ...[
                                const SizedBox(width: 6),
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
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Container(
                              height: 3,
                              color: colors.surfaceDim,
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress,
                                child: Container(color: identity),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$score',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 24,
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
