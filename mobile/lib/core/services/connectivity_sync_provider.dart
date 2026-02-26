import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/game/state/game_providers.dart';
import '../auth/auth_provider.dart';
import '../providers/push_notification_provider.dart';
import 'analysis_cache_service.dart';
import 'local_game_history_provider.dart';

/// Listens for connectivity changes and performs a full sync when
/// connectivity is restored while the user is logged in:
/// 1. Reconnect WebSocket
/// 2. Re-register push token
/// 3. Upload local games
/// 4. Retry pending analysis uploads
final connectivitySyncProvider = Provider<void>((ref) {
  var previouslyDisconnected = false;
  StreamSubscription<List<ConnectivityResult>>? sub;

  sub = Connectivity().onConnectivityChanged.listen((results) {
    final isConnected =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (previouslyDisconnected && isConnected) {
      final isLoggedIn = ref.read(authProvider).isLoggedIn;
      if (isLoggedIn) {
        debugPrint('[ConnectivitySync] Connectivity restored, syncing...');

        // 1. Reconnect WebSocket
        ref.read(webSocketClientProvider).reconnectIfNeeded();

        // 2. Re-register push token if needed
        ref.read(pushNotificationServiceProvider).reRegisterTokenIfNeeded();

        // 3. Upload local games
        ref.read(gameUploadServiceProvider).uploadAllLocalGames();

        // 4. Retry pending analysis uploads
        ref
            .read(analysisCacheServiceProvider)
            .uploadPendingAnalyses(ref.read(restClientProvider));
      }
    }

    previouslyDisconnected = !isConnected;
  });

  ref.onDispose(() {
    sub?.cancel();
  });
});
