import 'package:flutter/material.dart';

/// Edge-swipe that does whatever the screen's back button does.
///
/// The app navigates with `go`, so most screens replace the location rather
/// than pushing a route — there is nothing for the system pop gesture to pop.
/// This listens on a narrow strip down the left edge instead and calls
/// [onBack], so the gesture and the button always agree.
///
/// The strip is translucent: it only claims horizontal drags that start at the
/// edge, so taps and any scrolling underneath still work.
class CcSwipeBack extends StatefulWidget {
  final Widget child;

  /// Null disables the gesture — used for screens with nothing to go back to.
  final VoidCallback? onBack;

  /// Height at the bottom the strip keeps clear, for screens with a control
  /// that takes horizontal drags of its own down there (the replay scrubber).
  final double bottomInset;

  /// How far in from the left edge a drag has to start.
  static const double edgeWidth = 24;

  /// Drag past this, or flick faster than [_commitVelocity], to go back.
  static const double _commitDistance = 56;
  static const double _commitVelocity = 350;

  /// The content follows your thumb this far and no further.
  static const double _maxDrag = 90;

  const CcSwipeBack({
    super.key,
    required this.child,
    required this.onBack,
    this.bottomInset = 0,
  });

  @override
  State<CcSwipeBack> createState() => _CcSwipeBackState();
}

class _CcSwipeBackState extends State<CcSwipeBack> {
  double _dragX = 0;
  bool _dragging = false;

  void _update(DragUpdateDetails details) {
    setState(() {
      _dragging = true;
      _dragX = (_dragX + details.delta.dx).clamp(0.0, CcSwipeBack._maxDrag);
    });
  }

  void _end(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final commit =
        _dragX >= CcSwipeBack._commitDistance ||
        velocity >= CcSwipeBack._commitVelocity;

    setState(() {
      _dragging = false;
      _dragX = 0;
    });

    if (commit) widget.onBack?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onBack == null) return widget.child;

    return Stack(
      children: [
        // Snaps back at the page-transition duration when you let go without
        // committing (design language §7).
        AnimatedContainer(
          duration: _dragging
              ? Duration.zero
              : const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(_dragX, 0, 0),
          child: widget.child,
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: widget.bottomInset,
          width: CcSwipeBack.edgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: _update,
            onHorizontalDragEnd: _end,
            onHorizontalDragCancel: () => setState(() {
              _dragging = false;
              _dragX = 0;
            }),
          ),
        ),
      ],
    );
  }
}
