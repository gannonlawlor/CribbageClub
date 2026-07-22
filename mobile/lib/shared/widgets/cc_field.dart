import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

/// Labelled text field in the design language: a caption above the input
/// (12/500 uppercase `--text-3`), then an r8 `--surface-2` box with a
/// `--border-strong` hairline that thickens to the green focus ring.
///
/// Every auth form uses this so field metrics can't drift between screens.
class CcTextField extends StatelessWidget {
  /// Caption above the field; also the placeholder unless [hint] overrides it.
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final bool autofocus;

  const CcTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
  });

  static InputDecoration decoration(AppColors colors, String hint) {
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.72,
              ),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          autofocus: autofocus,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          onFieldSubmitted: onSubmitted,
          decoration: decoration(colors, hint ?? label),
          style: TextStyle(color: colors.textPrimary, fontSize: 15),
        ),
      ],
    );
  }
}
