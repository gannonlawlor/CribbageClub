import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart' show ExternalLibrary;
import 'app.dart';
import 'config/theme/theme_provider.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/auth_service.dart';
import 'core/services/local_game_history_provider.dart';
import 'core/services/settings_provider.dart';
import 'core/services/settings_service.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init(
    externalLibrary: Platform.isIOS
        ? ExternalLibrary.process(iKnowHowToUseIt: true)
        : null,
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final authService = AuthService();
  final savedAuth = await authService.loadSavedAuth();
  setInitialAuthData(savedAuth);

  // Load persisted settings before runApp to prevent flash of wrong theme
  final settingsService = SettingsService();
  final saved = await settingsService.loadAll();
  final initialTheme = saved.themeMode == 'dark'
      ? AppThemeMode.classicDark
      : AppThemeMode.classicLight;
  setInitialSettings(SettingsState(
    soundEnabled: saved.soundEnabled,
    hapticsEnabled: saved.hapticsEnabled,
    themeMode: initialTheme,
    autoDeal: saved.autoDeal,
    autoCut: saved.autoCut,
    autoGo: saved.autoGo,
    autoPlayAll: saved.autoPlayAll,
    autoPlayPegging: saved.autoPlayPegging,
    animationSpeed: saved.animationSpeed,
  ));

  final container = ProviderContainer(
    overrides: [
      themeProvider.overrideWith((_) => initialTheme),
    ],
  );

  // If already logged in from a previous session, upload any remaining local games
  if (savedAuth != null) {
    container.read(gameUploadServiceProvider).uploadAllLocalGames();
  }

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
