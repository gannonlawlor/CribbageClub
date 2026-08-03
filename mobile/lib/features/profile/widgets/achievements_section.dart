import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/models/achievement.dart';
import '../../../shared/widgets/cc_dialog.dart';

Color tierColor(AchievementTier tier, AppColors colors) => switch (tier) {
  AchievementTier.bronze => const Color(0xFFB0793A),
  AchievementTier.silver => const Color(0xFF9EA7B3),
  AchievementTier.gold => colors.ratingGold,
};

/// Achievements on a profile: "ACHIEVEMENTS n/25" over a grid of trophy
/// tiles. Unlocked tiles carry their tier colour; locked ones sit greyed
/// with a lock, counters adding a thin progress bar. Tap for the details.
class AchievementsSection extends StatelessWidget {
  final AchievementsResponse response;

  const AchievementsSection({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final achievements = [...response.achievements]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ACHIEVEMENTS',
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
              ),
            ),
            const Spacer(),
            Text(
              '${response.unlockedCount}/${response.totalCount}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final achievement in achievements)
              _AchievementTile(achievement: achievement),
          ],
        ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementStatus achievement;

  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final unlocked = achievement.unlocked;
    final tint = unlocked
        ? tierColor(achievement.tier, colors)
        : colors.textDisabled;
    final target = achievement.target;
    final showProgress = !unlocked && target != null;

    return InkWell(
      onTap: () => _showDetails(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: unlocked ? tint.withValues(alpha: 0.12) : colors.surfaceDim,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: unlocked ? tint.withValues(alpha: 0.45) : colors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              unlocked ? Icons.emoji_events : Icons.lock_outline,
              size: 20,
              color: tint,
            ),
            if (showProgress) ...[
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: ((achievement.progress ?? 0) / target).clamp(
                      0.0,
                      1.0,
                    ),
                    minHeight: 3,
                    backgroundColor: colors.border,
                    valueColor: AlwaysStoppedAnimation(colors.accent),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final colors = context.appColors;
    final tint = achievement.unlocked
        ? tierColor(achievement.tier, colors)
        : colors.textDisabled;
    final target = achievement.target;
    showCcDialog(
      context: context,
      builder: (_) => CcDialog(
        titleWidget: Row(
          children: [
            Icon(
              achievement.unlocked ? Icons.emoji_events : Icons.lock_outline,
              size: 20,
              color: tint,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                achievement.name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              achievement.description,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            if (achievement.unlocked)
              Text(
                _unlockedLine(),
                style: TextStyle(color: colors.textTertiary, fontSize: 12),
              )
            else if (target != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: ((achievement.progress ?? 0) / target).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation(colors.accent),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${achievement.progress ?? 0} of $target',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ] else
              Text(
                'Locked',
                style: TextStyle(color: colors.textTertiary, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  String _unlockedLine() {
    final at = achievement.unlockedAt;
    final date = at != null ? DateTime.tryParse(at)?.toLocal() : null;
    if (date == null) return 'Unlocked';
    return 'Unlocked ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
