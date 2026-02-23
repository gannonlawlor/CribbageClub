import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';

class StreakBadge extends StatelessWidget {
  final int streak;
  final double fontSize;

  const StreakBadge({super.key, required this.streak, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    if (streak <= 0) return const SizedBox.shrink();
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.streak.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.streak.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: colors.streak,
            size: fontSize + 2,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: TextStyle(
              color: colors.streak,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
