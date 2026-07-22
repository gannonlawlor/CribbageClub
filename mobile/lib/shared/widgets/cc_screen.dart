import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import 'cc_buttons.dart';

/// Screen chrome for a full-page view: back arrow, title, optional trailing
/// actions. Replaces the stock AppBar — the design language has no mobile app
/// bar, and the settings/home screens already carry their title in the body.
class CcScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;

  /// Sits under the title as a single line of context (a count, a status).
  final String? subtitle;

  const CcScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(onBack == null ? 20 : 6, 4, 10, 4),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                size: 20,
                color: colors.textSecondary,
              ),
              onPressed: onBack,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Centred title + detail + one surface button. Every empty, error and
/// signed-out state in the app uses this instead of a large icon and red text.
class CcMessage extends StatelessWidget {
  final String title;
  final String? detail;
  final String? action;
  final VoidCallback? onAction;

  const CcMessage({
    super.key,
    required this.title,
    this.detail,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: CcSecondaryButton(label: action!, onPressed: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Section label — 11/600 uppercase, the caption step from the type scale.
class CcSectionCaption extends StatelessWidget {
  final String text;

  /// Right-hand affordance, e.g. a "See all" link.
  final Widget? trailing;

  const CcSectionCaption(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final label = Text(
      text.toUpperCase(),
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.7,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: trailing == null
          ? label
          : Row(children: [label, const Spacer(), trailing!]),
    );
  }
}

/// Panel card: `--surface-2` fill, hairline border, r10. Pass [rows] to get
/// hairline dividers between children (grouped-list form), or [child] for a
/// single block of content.
class CcPanel extends StatelessWidget {
  final List<Widget>? rows;
  final Widget? child;
  final EdgeInsets? padding;

  const CcPanel({super.key, this.rows, this.child, this.padding})
    : assert(rows != null || child != null, 'CcPanel needs rows or a child');

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget content;
    if (rows != null) {
      final laid = <Widget>[];
      for (var i = 0; i < rows!.length; i++) {
        if (i > 0) laid.add(Divider(height: 1, color: colors.border));
        laid.add(rows![i]);
      }
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: laid,
      );
    } else {
      content = child!;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        padding: padding,
        child: content,
      ),
    );
  }
}

/// Round avatar-ish initial mark used in player rows across friends, lobbies
/// and the leaderboard.
class CcAvatar extends StatelessWidget {
  final String name;
  final double size;

  /// Draws the online dot at the bottom-right when non-null.
  final bool? isOnline;

  const CcAvatar({
    super.key,
    required this.name,
    this.size = 34,
    this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colors.surfaceDim,
              borderRadius: BorderRadius.circular(size * 0.24),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (isOnline == true)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.scaffoldBg, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Segmented switch — chrome trough with a green pill on the active segment.
/// The in-page alternative to a Material TabBar, matching the settings
/// screen's theme picker.
class CcSegmented extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  /// Optional count badge per segment; zero or null draws nothing.
  final List<int?>? badges;

  const CcSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.badges,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceChrome,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: selected == i ? colors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected == i
                                ? colors.accentOnSurface
                                : colors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if ((badges?.elementAtOrNull(i) ?? 0) > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: selected == i
                                ? colors.accentOnSurface.withValues(alpha: 0.2)
                                : colors.error,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${badges![i]}',
                            style: TextStyle(
                              color: selected == i
                                  ? colors.accentOnSurface
                                  : colors.accentOnSurface,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Neutral metadata chip — `--surface-3` fill with `--text-2`, or a tinted
/// variant when [color] is given.
class CcChip extends StatelessWidget {
  final String label;
  final Color? color;

  const CcChip({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color == null
            ? colors.surfaceDim
            : color!.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? colors.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.54,
        ),
      ),
    );
  }
}
