import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import 'cc_buttons.dart';
import 'cc_dialog.dart';

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

    final result = await showCcDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.appColors;
        return CcDialog(
          title: 'Sign in required',
          showCloseButton: false,
          actions: [
            CcSecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            CcPrimaryButton(
              label: 'Sign in',
              height: 44,
              fontSize: 14,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
          child: Text(
            'Sign in to play online, add friends, and keep a rating.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        );
      },
    );

    if (result == true && context.mounted) {
      context.go('/login');
    }
    return false;
  }
}
