import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';

/// Whose crib the thrown cards feed, said in the identity colours the rest of
/// the app uses for the two players: green is you, ivory is your opponent
/// (design language §2). The two face-down cards are the same crib mark the
/// game table uses, so the answer reads before the words do.
class CribBadge extends StatelessWidget {
  final bool isDealer;

  const CribBadge({super.key, required this.isDealer});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final identity = isDealer ? colors.pegPlayer : colors.pegOpponent;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
      decoration: BoxDecoration(
        color: identity.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: identity.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CribMark(color: identity),
          const SizedBox(width: 8),
          Text(
            isDealer ? 'YOUR CRIB' : "OPPONENT'S CRIB",
            style: TextStyle(
              color: identity,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.63,
            ),
          ),
        ],
      ),
    );
  }
}

/// Two cards face-down and splayed — the crib, at badge scale.
class _CribMark extends StatelessWidget {
  final Color color;

  const _CribMark({required this.color});

  @override
  Widget build(BuildContext context) {
    Widget card(double angle) => Transform.rotate(
      angle: angle * math.pi / 180,
      child: Container(
        width: 9,
        height: 13,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: color, width: 0.8),
        ),
      ),
    );

    return SizedBox(
      width: 15,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(left: 0, child: card(-12)),
          Positioned(right: 0, child: card(12)),
        ],
      ),
    );
  }
}

/// The puzzle's ask, in the shape the game screen uses for the discard step:
/// whose crib it is, what you're choosing, and how far along you are.
class PuzzlePrompt extends StatelessWidget {
  final bool isDealer;

  /// True when the player is picking the two cards to throw rather than the
  /// four to keep.
  final bool pickDiscards;
  final int picked;

  const PuzzlePrompt({
    super.key,
    required this.isDealer,
    required this.pickDiscards,
    required this.picked,
  });

  int get _needed => pickDiscards ? 2 : 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final done = picked == _needed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CribBadge(isDealer: isDealer),
        const SizedBox(height: 12),
        Text(
          pickDiscards ? 'Throw two' : 'Keep four',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: Text(
            '$picked of $_needed selected',
            key: ValueKey('$picked$_needed'),
            style: TextStyle(
              color: done ? colors.accent : colors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
