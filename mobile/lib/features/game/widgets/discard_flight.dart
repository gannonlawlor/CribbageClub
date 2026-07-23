import 'package:flutter/material.dart';

import '../../../config/constants.dart';
import 'card_widget.dart';

/// Flies the cards you just threw from your hand across to the crib.
///
/// The crib is a face-down stack that looks the same before and after, so
/// nothing has to be hidden while the cards are in the air — these are drawn
/// face-down too, and simply arrive.
///
/// Both ends are measured from [handKey] and [cribKey] at launch time, so the
/// flight follows wherever the layout actually put them.
class DiscardFlight extends StatefulWidget {
  final GlobalKey handKey;
  final GlobalKey cribKey;

  /// Bumped by the caller each time a discard happens; the change is what
  /// launches the flight.
  final int token;

  /// How many cards went across.
  final int count;

  /// Coordinate space the flight is drawn in — the game screen's stack.
  final GlobalKey stackKey;

  static const Duration duration = Duration(milliseconds: 260);

  const DiscardFlight({
    super.key,
    required this.handKey,
    required this.cribKey,
    required this.stackKey,
    required this.token,
    this.count = 2,
  });

  @override
  State<DiscardFlight> createState() => _DiscardFlightState();
}

class _DiscardFlightState extends State<DiscardFlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: DiscardFlight.duration,
  );

  Rect? _from;
  Rect? _to;

  @override
  void didUpdateWidget(DiscardFlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.token != oldWidget.token && widget.token > 0) _launch();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Measures both ends against the stack and runs the flight. Silently does
  /// nothing if either end isn't laid out — a missing animation beats a
  /// mis-placed one.
  void _launch() {
    final stack = widget.stackKey.currentContext?.findRenderObject();
    final hand = widget.handKey.currentContext?.findRenderObject();
    final crib = widget.cribKey.currentContext?.findRenderObject();
    if (stack is! RenderBox || hand is! RenderBox || crib is! RenderBox) return;
    if (!stack.hasSize || !hand.hasSize || !crib.hasSize) return;

    Rect rectOf(RenderBox box) {
      final origin = box.localToGlobal(Offset.zero, ancestor: stack);
      return origin & box.size;
    }

    setState(() {
      _from = rectOf(hand);
      _to = rectOf(crib);
    });
    _controller.forward(from: 0).then((_) {
      if (mounted) setState(() => _from = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final from = _from;
    final to = _to;
    if (from == null || to == null) return const SizedBox.shrink();

    // Land on the crib's card size, starting at the hand's.
    final endWidth = to.width.clamp(24.0, 80.0);
    final startWidth = (from.height * AppConstants.cardAspectRatio).clamp(
      24.0,
      90.0,
    );

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_controller.value);
            final width = startWidth + (endWidth - startWidth) * t;
            final height = width / AppConstants.cardAspectRatio;

            return Stack(
              children: [
                for (int i = 0; i < widget.count; i++)
                  _flyingCard(
                    index: i,
                    t: t,
                    from: from,
                    to: to,
                    width: width,
                    height: height,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _flyingCard({
    required int index,
    required double t,
    required Rect from,
    required Rect to,
    required double width,
    required double height,
  }) {
    // Fan the pair apart at the hand end so they read as two cards, and
    // converge on the crib.
    final spread = (index - (widget.count - 1) / 2) * width * 0.9;
    final startCentre = Offset(from.center.dx + spread, from.center.dy);
    final endCentre = to.center;

    final centre = Offset.lerp(startCentre, endCentre, t)!;
    // A shallow arc reads as a toss rather than a slide.
    final lift = -26 * (t * (1 - t) * 4);

    return Positioned(
      left: centre.dx - width / 2,
      top: centre.dy - height / 2 + lift,
      child: Transform.rotate(
        angle: (index.isEven ? 1 : -1) * 0.18 * (1 - t),
        child: Opacity(
          opacity: t > 0.88 ? (1 - t) / 0.12 : 1,
          child: CardWidget(
            faceUp: false,
            enabled: false,
            width: width,
            height: height,
          ),
        ),
      ),
    );
  }
}
