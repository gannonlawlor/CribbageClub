import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

/// Pressed-bevel edge under the primary CTA. Theme-invariant like the fill
/// (design language §4: button fills don't change between themes).
const _green600 = Color(0xFF5D9948);

/// Primary CTA — green fill with a 4px darker bottom bevel (design language
/// "Play CTA"). Disabled state drops to 40% opacity with no bevel.
class CcPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final IconData? icon;

  const CcPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
    this.fontSize = 18,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = onPressed != null;
    final bevel = enabled ? 4.0 : 0.0;
    final radius = BorderRadius.circular(10);

    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Container(
        height: height,
        decoration: BoxDecoration(color: _green600, borderRadius: radius),
        child: Padding(
          padding: EdgeInsets.only(bottom: bevel),
          child: Material(
            color: colors.accent,
            borderRadius: radius,
            child: InkWell(
              onTap: onPressed,
              borderRadius: radius,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: fontSize + 2, color: colors.accentOnSurface),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.accentOnSurface,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
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

/// Secondary surface button — panel fill with a strong hairline border
/// (design language "Secondary / surface button").
class CcSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final IconData? icon;
  final bool filled;

  const CcSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 44,
    this.fontSize = 14,
    this.icon,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(8);

    return SizedBox(
      height: height,
      child: Material(
        color: filled ? colors.surfacePrimary : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: colors.borderStrong),
            ),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: fontSize + 3, color: colors.textSecondary),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
