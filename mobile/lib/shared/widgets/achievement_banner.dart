import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_colors.dart';
import '../../core/models/achievement.dart';

/// FIFO of achievements waiting to be celebrated. The host shows the head of
/// the queue and pops it when its banner dismisses, so simultaneous unlocks
/// play one after another instead of stacking.
class AchievementBannerQueue extends StateNotifier<List<AchievementStatus>> {
  AchievementBannerQueue() : super(const []);

  void enqueue(List<AchievementStatus> achievements) {
    final pending = state.map((a) => a.key).toSet();
    state = [...state, ...achievements.where((a) => !pending.contains(a.key))];
  }

  void popCurrent() {
    if (state.isNotEmpty) state = state.sublist(1);
  }
}

final achievementBannerQueueProvider =
    StateNotifierProvider<AchievementBannerQueue, List<AchievementStatus>>(
      (ref) => AchievementBannerQueue(),
    );

/// App-wide overlay host: slides the current banner down from the top edge,
/// holds it, and slides it away. Sits above the router in [MaterialApp]'s
/// builder Stack so it survives navigation.
class AchievementBannerHost extends ConsumerWidget {
  const AchievementBannerHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(achievementBannerQueueProvider);
    if (queue.isEmpty) return const SizedBox.shrink();
    return _AchievementBanner(
      // Keyed so a new head restarts the entrance animation.
      key: ValueKey(queue.first.key),
      achievement: queue.first,
      onDismissed: () =>
          ref.read(achievementBannerQueueProvider.notifier).popCurrent(),
    );
  }
}

class _AchievementBanner extends StatefulWidget {
  final AchievementStatus achievement;
  final VoidCallback onDismissed;

  const _AchievementBanner({
    super.key,
    required this.achievement,
    required this.onDismissed,
  });

  @override
  State<_AchievementBanner> createState() => _AchievementBannerState();
}

class _AchievementBannerState extends State<_AchievementBanner>
    with SingleTickerProviderStateMixin {
  static const _holdFor = Duration(milliseconds: 3500);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 240),
  );
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, -1.2), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _holdTimer = Timer(_holdFor, _dismiss);
  }

  Future<void> _dismiss() async {
    _holdTimer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color _tierColor(AppColors colors) => switch (widget.achievement.tier) {
    AchievementTier.bronze => const Color(0xFFB0793A),
    AchievementTier.silver => const Color(0xFF9EA7B3),
    AchievementTier.gold => colors.ratingGold,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tierColor = _tierColor(colors);
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: _dismiss,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
              decoration: BoxDecoration(
                color: colors.surfaceChrome,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderStrong),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(Icons.emoji_events, color: tierColor, size: 22),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACHIEVEMENT UNLOCKED',
                          style: TextStyle(
                            color: colors.textTertiary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          widget.achievement.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.achievement.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
