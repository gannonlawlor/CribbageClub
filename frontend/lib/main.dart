import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/auth_service.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  final authService = AuthService();
  final savedAuth = await authService.loadSavedAuth();
  setInitialAuthData(savedAuth);

  runApp(const ProviderScope(child: App()));
}
