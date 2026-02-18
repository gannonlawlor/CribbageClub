import 'package:flutter/material.dart';
import '../../../config/constants.dart';
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPlayerScore(
            name: 'You${isDealer ? ' (D)' : ''}',
            score: player.score,
            isPlayer: true,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildPlayerScore(
            name: '${opponent.name}${!isDealer ? ' (D)' : ''}',
            score: opponent.score,
            isPlayer: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore({
    required String name,
    required int score,
    required bool isPlayer,
  }) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            color: isPlayer ? AppTheme.goldAccent : Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$score / ${AppConstants.winningScore}',
          style: TextStyle(
            color: isPlayer ? Colors.white : Colors.white70,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
