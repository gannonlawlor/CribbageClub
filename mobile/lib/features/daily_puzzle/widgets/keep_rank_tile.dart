import 'package:flutter/material.dart';

import '../../../config/theme.dart';
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
    Color? borderColor;
    Color? bgColor;
    if (isPlayerPick && isOptimal) {
      borderColor = AppTheme.goldAccent;
      bgColor = AppTheme.goldAccent.withValues(alpha: 0.15);
    } else if (isPlayerPick) {
      borderColor = AppTheme.goldAccent;
      bgColor = AppTheme.goldAccent.withValues(alpha: 0.1);
    } else if (isOptimal) {
      borderColor = Colors.green;
      bgColor = Colors.green.withValues(alpha: 0.1);
    }

    return GestureDetector(
      onTap: onExplain,
      child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '#${option.rank}',
              style: TextStyle(
                color: isOptimal ? Colors.green : Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Mini cards
          ...option.keep.map(
            (card) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: CardWidget(
                card: card,
                width: 32,
                height: 45,
                enabled: false,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Scores
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      option.netScore.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'avg pts',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
                Text(
                  'hand ${option.averageHandScore.toStringAsFixed(1)}'
                  '  crib ${option.averageCribScore > 0 ? '+' : ''}${option.averageCribScore.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          // Info icon (when explain is available)
          if (onExplain != null)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(
                Icons.info_outline,
                color: Colors.white38,
                size: 18,
              ),
            ),
          // Player pick indicator
          if (isPlayerPick)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.person, color: AppTheme.goldAccent, size: 18),
            ),
        ],
      ),
    ),
    );
  }
}
