import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart' show ExternalLibrary;
import 'app.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/auth_service.dart';
import 'core/services/local_game_history_provider.dart';
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

  final container = ProviderContainer();

  // If already logged in from a previous session, upload any remaining local games
  if (savedAuth != null) {
    container.read(gameUploadServiceProvider).uploadAllLocalGames();
  }

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
