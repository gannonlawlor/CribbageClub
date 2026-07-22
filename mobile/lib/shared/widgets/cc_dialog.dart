import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';

/// App-standard modal dialog shell (design language "Game-over panel"):
/// a `--surface-2` card, r12, `--border-strong`, soft shadow over a 55% scrim.
///
/// Reusable across the app — pass a [title] (or a custom [titleWidget] for a
/// richer header), the body [child], and an optional [actions] row rendered as
/// equal-width buttons. Present it with [showCcDialog], which applies the scrim
/// and the 160ms fade + 4px-rise entrance (design language motion "Page /
/// panel"). The body scrolls when it exceeds [maxHeightFactor] of the screen.
class CcDialog extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget child;
  final List<Widget>? actions;

  /// Small widgets (e.g. a help button) rendered in the header row, between
  /// the title and the close button.
  final List<Widget>? headerActions;
  final bool showCloseButton;
  final double maxWidth;
  final double maxHeightFactor;

  /// Exact card height. When set, the card is fixed at this height (still
  /// capped by [maxHeightFactor]) and the body scrolls — used to keep two
  /// faces of a flipped dialog the same size. Null sizes to content.
  final double? height;

  /// Attached to the card container so callers can measure its rendered size
  /// (e.g. to fix a counterpart dialog to the same [height]).
  final Key? cardKey;

  const CcDialog({
    super.key,
    this.title,
    this.titleWidget,
    required this.child,
    this.actions,
    this.headerActions,
    this.showCloseButton = true,
    this.maxWidth = 340,
    this.maxHeightFactor = 0.82,
    this.height,
    this.cardKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final size = MediaQuery.of(context).size;
    final hasHeader = title != null ||
        titleWidget != null ||
        headerActions != null ||
        showCloseButton;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: size.height * maxHeightFactor,
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              key: cardKey,
              height: height,
              decoration: BoxDecoration(
                color: colors.surfacePrimary, // --surface-2
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderStrong),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x80000000), // rgba(0,0,0,0.5)
                    blurRadius: 40,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize:
                    height != null ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasHeader)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: titleWidget ??
                                (title != null
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          title!,
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink()),
                          ),
                          if (headerActions != null) ...[
                            for (final action in headerActions!)
                              Padding(
                                padding: const EdgeInsets.only(left: 2),
                                child: action,
                              ),
                          ],
                          if (showCloseButton)
                            _CloseButton(
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                        ],
                      ),
                    ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        hasHeader ? 0 : 20,
                        20,
                        actions != null ? 12 : 20,
                      ),
                      child: child,
                    ),
                  ),
                  if (actions != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: Row(
                        children: [
                          for (var i = 0; i < actions!.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(child: actions![i]),
                          ],
                        ],
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

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(Icons.close, size: 20, color: colors.textTertiary),
        ),
      ),
    );
  }
}

/// Presents [builder]'s widget (typically a [CcDialog]) over a 55% scrim with
/// the design language "Page / panel" entrance: 160ms ease-out fade + 4px rise.
Future<T?> showCcDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0x8C000000), // rgba(0,0,0,0.55)
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (context, _, _) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.2, 0, 0, 1), // --ease-out
      );
      return FadeTransition(
        opacity: curved,
        child: AnimatedBuilder(
          animation: curved,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, (1 - curved.value) * 4),
            child: child,
          ),
          child: child,
        ),
      );
    },
  );
}
