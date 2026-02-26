import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/routes.dart';
import 'config/theme/theme_provider.dart';
import 'core/providers/push_notification_provider.dart';
import 'core/services/auth_game_sync_provider.dart';
import 'core/services/connectivity_sync_provider.dart';
import 'features/game/state/game_providers.dart';
import 'shared/utils/responsive.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _enforceOrientationPolicy(BuildContext context) {
    if (Responsive.isTabletDevice(context)) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(webSocketClientProvider).reconnectIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    ref.watch(authGameSyncProvider);
    ref.watch(connectivitySyncProvider);
    ref.watch(pushNotificationSyncProvider);

    return MaterialApp.router(
      title: 'Cribbage Club',
      theme: buildThemeData(themeMode),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        _enforceOrientationPolicy(context);
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
