import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme/app_colors.dart';
import '../../core/auth/auth_provider.dart';

class AuthRequired {
  AuthRequired._();

  /// Returns true if the user is already authenticated.
  /// If not, shows a dialog prompting login and returns false.
  static Future<bool> ensureAuthenticated(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final auth = ref.read(authProvider);
    if (auth.isLoggedIn) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.appColors;
        return AlertDialog(
          backgroundColor: colors.surfacePrimary,
          title: Text(
            'Login Required',
            style: TextStyle(color: colors.textPrimary),
          ),
          content: Text(
            'You need to log in to access multiplayer features.',
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Log In'),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      context.go('/login');
    }
    return false;
  }
}
