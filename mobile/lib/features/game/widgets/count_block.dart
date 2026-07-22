import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

/// The centred stage block: a caption, the live number (or a stage headline
/// when there is no count to show), and one instruction line.
///
/// Design principle §1 — the pegging count is the largest live number on
/// screen and nothing restyles it mid-play.
class CountBlock extends StatelessWidget {
  final String label;

  /// The pegging count. Null outside pegging, where [headline] shows instead.
  final int? count;
  final String? headline;
  final String instruction;

  /// Instruction turns green when the move is the local player's.
  final bool isMyTurn;

  const CountBlock({
    super.key,
    required this.label,
    required this.instruction,
    this.count,
    this.headline,
    this.isMyTurn = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.88,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 52,
          child: Center(
            child: count != null
                ? AnimatedSwitcher(
                    duration: const Duration(milliseconds: 120),
                    child: Text(
                      '$count',
                      key: ValueKey(count),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 52,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  )
                : Text(
                    headline ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: Text(
            instruction,
            key: ValueKey('$instruction$isMyTurn'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isMyTurn ? colors.accent : colors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
