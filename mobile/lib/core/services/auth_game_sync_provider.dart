import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import 'achievement_service.dart';
import 'local_game_history_provider.dart';

/// Listens for auth state transitions and uploads local games on login.
final authGameSyncProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authProvider, (previous, next) {
    final wasLoggedIn = previous?.isLoggedIn ?? false;
    final isNowLoggedIn = next.isLoggedIn;

    // Trigger upload on login transition (not logged in → logged in)
    if (!wasLoggedIn && isNowLoggedIn) {
      Future(() async {
        await ref.read(gameUploadServiceProvider).uploadAllLocalGames();
        // Uploads can unlock offline-earned achievements, so sync after —
        // this also catches this device up on unlocks earned elsewhere.
        await ref.read(platformAchievementsProvider).signIn();
        await ref.read(achievementSyncServiceProvider).sync();
      });
    }
  });
});
