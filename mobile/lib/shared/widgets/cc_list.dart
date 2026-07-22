import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';

/// Tappable option row (design language "Nav sidebar item" family): a tinted
/// leading icon, title + optional subtitle, and a trailing chevron, on a
/// `--surface-3` panel with a hairline border. Used for pickers and menus.
class CcOptionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool showChevron;

  const CcOptionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tint = iconColor ?? colors.accent;
    return Material(
      color: colors.surfaceDim,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: tint, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 12.5,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 18, color: colors.textDisabled),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Title (+ optional subtitle) with a trailing switch, styled to the design
/// language. Disabled when [onChanged] is null. Meant to sit inside a
/// [CcGroup] or directly in a dialog body.
class CcToggleRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const CcToggleRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = onChanged != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: enabled ? colors.textPrimary : colors.textDisabled,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeTrackColor: colors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Grouped rows on a `--surface-3` card with hairline dividers between them —
/// the dialog-context counterpart of the settings screen's grouped card
/// (which sits one elevation lower, on `--surface-2`).
class CcGroup extends StatelessWidget {
  final List<Widget> children;

  const CcGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(Divider(height: 1, color: colors.border));
      rows.add(children[i]);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceDim,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Column(children: rows),
      ),
    );
  }
}
