import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/widgets/cc_buttons.dart';
import '../../../shared/widgets/cc_field.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/cc_swipe_back.dart';
import '../../../shared/utils/navigation.dart';

/// Guest → full account. Mirrors the login screen's layout so the two auth
/// forms read as one flow; the copy is the design language's guest upsell
/// (§8) rather than generic "save your progress" language.
class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _autovalidate = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_clearAuthError);
    _passwordController.addListener(_clearAuthError);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _clearAuthError() {
    final auth = ref.read(authProvider);
    if (auth.error != null) {
      ref.read(authProvider.notifier).clearError();
    }
  }

  void _submit() {
    setState(() => _autovalidate = true);
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final displayName = _displayNameController.text.trim();

    ref
        .read(authProvider.notifier)
        .upgradeGuest(
          username,
          password,
          displayName: displayName.isEmpty ? null : displayName,
        );
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final auth = ref.watch(authProvider);

    // Navigate home once upgrade succeeds (isGuest becomes false)
    ref.listen(authProvider, (prev, next) {
      if (prev?.isGuest == true && !next.isGuest && next.isLoggedIn) {
        context.go('/');
      }
    });

    return CcSwipeBack(
      onBack: () => context.backOrHome(),
      child: Scaffold(
        body: LoadingOverlay(
          isLoading: auth.isLoading,
          child: SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: colors.textSecondary),
                    onPressed: () => context.backOrHome(),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _autovalidate
                            ? AutovalidateMode.onUserInteraction
                            : AutovalidateMode.disabled,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: colors.accent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    'CC',
                                    style: TextStyle(
                                      color: colors.accentOnSurface,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Create an account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "You're playing unrated. Create an account to "
                              'keep a rating and your game history.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textTertiary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 32),
                            CcTextField(
                              label: 'Username',
                              controller: _usernameController,
                              validator: _validateUsername,
                            ),
                            const SizedBox(height: 16),
                            CcTextField(
                              label: 'Password',
                              controller: _passwordController,
                              validator: _validatePassword,
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),
                            CcTextField(
                              label: 'Display name',
                              hint: 'Optional',
                              controller: _displayNameController,
                              textInputAction: TextInputAction.done,
                              textCapitalization: TextCapitalization.words,
                              onSubmitted: (_) => _submit(),
                            ),
                            if (auth.error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                auth.error!,
                                style: TextStyle(color: colors.error),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 24),
                            CcPrimaryButton(
                              label: 'Create account',
                              onPressed: auth.isLoading ? null : _submit,
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => context.backOrHome(),
                              child: Text(
                                'Not now',
                                style: TextStyle(
                                  color: colors.textTertiary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Divider(color: colors.border, height: 1),
                            const SizedBox(height: 12),
                            Text(
                              'Your games so far carry over.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textTertiary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
