import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

/// Compact cribbage board for phones (design language §5, mobile variant):
/// each player's lane compresses to a recessed linear track with a peg dot.
/// The 121 hole gets the only gold on the field.
class BoardStrip extends StatelessWidget {
  final int playerScore;
  final int opponentScore;

  const BoardStrip({
    super.key,
    required this.playerScore,
    required this.opponentScore,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.boardPrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          _Lane(score: playerScore, color: colors.pegPlayer, emphasized: true),
          const SizedBox(height: 10),
          _Lane(
            score: opponentScore,
            color: colors.pegOpponent,
            emphasized: false,
          ),
        ],
      ),
    );
  }
}

class _Lane extends StatelessWidget {
  final int score;
  final Color color;
  final bool emphasized;

  const _Lane({
    required this.score,
    required this.color,
    required this.emphasized,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final target = (score / 121).clamp(0.0, 1.0);

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: target),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            builder: (context, fraction, _) {
              return SizedBox(
                height: 12,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.centerLeft,
                      children: [
                        // Recessed track
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 3,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        // Progress wash
                        Positioned(
                          left: 0,
                          top: 3,
                          child: Container(
                            height: 6,
                            width: w * fraction,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        // Hole 121 — the only gold on the field
                        Positioned(
                          right: 0,
                          top: 2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.boardHole,
                              border: Border.all(
                                color: colors.ratingGold.withValues(alpha: 0.55),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        // Front peg
                        Positioned(
                          left: (w * fraction - 6).clamp(0.0, w - 12),
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 30,
          child: Text(
            '$score',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: emphasized ? colors.textPrimary : colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
