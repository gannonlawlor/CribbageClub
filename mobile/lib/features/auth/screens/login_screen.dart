import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/widgets/cc_buttons.dart';
import '../../../shared/widgets/loading_overlay.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(
    text: kDebugMode ? 'gannon' : null,
  );
  final _passwordController = TextEditingController(
    text: kDebugMode ? 'password' : null,
  );
  bool _isRegister = false;
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

    if (_isRegister) {
      ref.read(authProvider.notifier).register(username, password);
    } else {
      ref.read(authProvider.notifier).login(username, password);
    }
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
    if (_isRegister && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  InputDecoration _fieldDecoration(AppColors colors, String hint) {
    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.textDisabled, fontSize: 15),
      filled: true,
      fillColor: colors.surfacePrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: border(colors.borderStrong),
      focusedBorder: border(colors.selectedBorder, width: 2),
      errorBorder: border(colors.error),
      focusedErrorBorder: border(colors.error, width: 2),
      errorStyle: TextStyle(
        color: colors.error,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _fieldCaption(AppColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.72,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: LoadingOverlay(
        isLoading: auth.isLoading,
        child: Center(
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
                      'Cribbage Club',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _fieldCaption(colors, 'Username'),
                    TextFormField(
                      controller: _usernameController,
                      validator: _validateUsername,
                      decoration: _fieldDecoration(colors, 'Username'),
                      style: TextStyle(color: colors.textPrimary, fontSize: 15),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    _fieldCaption(colors, 'Password'),
                    TextFormField(
                      controller: _passwordController,
                      validator: _validatePassword,
                      decoration: _fieldDecoration(colors, 'Password'),
                      style: TextStyle(color: colors.textPrimary, fontSize: 15),
                      obscureText: true,
                      onFieldSubmitted: (_) => _submit(),
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
                      label: _isRegister ? 'Register' : 'Login',
                      onPressed: auth.isLoading ? null : _submit,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() {
                        _isRegister = !_isRegister;
                        _autovalidate = false;
                        _formKey.currentState?.reset();
                      }),
                      child: Text(
                        _isRegister
                            ? 'Already have an account? Login'
                            : "Don't have an account? Register",
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: colors.border, height: 1),
                    const SizedBox(height: 16),
                    CcSecondaryButton(
                      label: 'Play as Guest',
                      icon: Icons.person_outline,
                      onPressed: auth.isLoading
                          ? null
                          : () =>
                              ref.read(authProvider.notifier).loginAsGuest(),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: Text(
                        'Skip for now',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
