import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/player.dart';

class ScoreDisplay extends StatelessWidget {
  final Player player;
  final Player opponent;
  final bool isDealer;

  const ScoreDisplay({
    super.key,
    required this.player,
    required this.opponent,
    required this.isDealer,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ScoreChip(
          name: 'You${isDealer ? ' (D)' : ''}',
          score: player.score,
          color: AppTheme.pegGold,
          isPlayer: true,
        ),
        const SizedBox(width: 8),
        _ScoreChip(
          name: '${opponent.name}${!isDealer ? ' (D)' : ''}',
          score: opponent.score,
          color: AppTheme.pegWhite,
          isPlayer: false,
        ),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String name;
  final int score;
  final Color color;
  final bool isPlayer;

  const _ScoreChip({
    required this.name,
    required this.score,
    required this.color,
    required this.isPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$score',
            style: TextStyle(
              color: isPlayer ? Colors.white : Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
