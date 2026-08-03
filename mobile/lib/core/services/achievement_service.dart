import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widgets/achievement_banner.dart';
import '../auth/auth_provider.dart';
import '../models/achievement.dart';
import 'platform_achievements.dart';

/// How many unlocks a first-ever sync will celebrate. A reinstall or a new
/// device catches up on a whole account history at once — a veteran's ten
/// banners in a row is noise, not celebration, so a large first batch is
/// persisted silently instead.
const int _maxFirstSyncBanners = 3;

/// Fetch-and-diff achievement sync (the plan's chosen mechanism — the client
/// doesn't subscribe to /user/queue/notifications).
///
/// At key moments (game over, import, puzzle solve, friend accept, login) the
/// caller runs [sync]: fetch the merged view, diff earned keys against the
/// per-user celebrated set in SharedPreferences, banner the new ones, and
/// re-push all earned to Game Center / Play Games. Platform unlocks are
/// idempotent, so the re-push doubles as reconciliation. One code path covers
/// online unlocks, offline-earned-then-imported unlocks, and multi-device
/// catch-up.
class AchievementSyncService {
  final Ref _ref;
  final PlatformAchievements _platform;

  AchievementSyncService(this._ref, this._platform);

  static String celebratedKey(String userId) =>
      'celebrated_achievements_$userId';

  Future<void> sync() async {
    final auth = _ref.read(authProvider);
    final userId = auth.userId;
    if (!auth.isLoggedIn || userId == null) return;

    try {
      final response = await _ref
          .read(restClientProvider)
          .getAchievements(userId);
      final unlocked = response.achievements.where((a) => a.unlocked).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final prefs = await SharedPreferences.getInstance();
      final key = celebratedKey(userId);
      final firstSync = !prefs.containsKey(key);
      final celebrated = (prefs.getStringList(key) ?? const []).toSet();

      final fresh = unlocked.where((a) => !celebrated.contains(a.key)).toList();
      if (fresh.isNotEmpty) {
        await prefs.setStringList(key, [
          ...{...celebrated, ...unlocked.map((a) => a.key)},
        ]);
        if (!firstSync || fresh.length <= _maxFirstSyncBanners) {
          _ref.read(achievementBannerQueueProvider.notifier).enqueue(fresh);
        }
        // The profile section is stale the moment something unlocks.
        _ref.invalidate(myAchievementsProvider);
      } else if (firstSync) {
        // Remember that this device has synced, so later unlocks banner.
        await prefs.setStringList(key, const []);
      }

      await _platform.unlockAll(unlocked.map((a) => a.key));
    } catch (e) {
      // Sync is opportunistic — a dead network just means the next moment
      // catches up.
      debugPrint('Achievement sync failed: $e');
    }
  }
}

final platformAchievementsProvider = Provider<PlatformAchievements>(
  (ref) => PlatformAchievements(),
);

final achievementSyncServiceProvider = Provider<AchievementSyncService>(
  (ref) => AchievementSyncService(ref, ref.read(platformAchievementsProvider)),
);

/// The signed-in user's achievements, for the profile screen. Null when
/// logged out.
final myAchievementsProvider = FutureProvider<AchievementsResponse?>((
  ref,
) async {
  final auth = ref.watch(authProvider);
  final userId = auth.userId;
  if (!auth.isLoggedIn || userId == null) return null;
  return ref.read(restClientProvider).getAchievements(userId);
});

/// Another player's achievements, for their public profile.
final achievementsForUserProvider = FutureProvider.autoDispose
    .family<AchievementsResponse, String>(
      (ref, userId) => ref.read(restClientProvider).getAchievements(userId),
    );
