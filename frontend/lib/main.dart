import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/auth_service.dart';
import 'core/services/local_game_history_provider.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
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
