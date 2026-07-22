import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

/// 38px surface button used for the in-game utilities (design language §4,
/// "Secondary / surface button", compact variant).
class GameIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? iconColor;

  const GameIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.borderStrong),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor ?? colors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
