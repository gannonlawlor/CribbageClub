import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import 'local_game_history_provider.dart';

/// Listens for auth state transitions and uploads local games on login.
final authGameSyncProvider = Provider<void>((ref) {
  ref.listen<AuthState>(authProvider, (previous, next) {
    final wasLoggedIn = previous?.isLoggedIn ?? false;
    final isNowLoggedIn = next.isLoggedIn;

    // Trigger upload on login transition (not logged in → logged in)
    if (!wasLoggedIn && isNowLoggedIn) {
      ref.read(gameUploadServiceProvider).uploadAllLocalGames();
    }
  });
});
