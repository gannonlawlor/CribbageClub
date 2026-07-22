import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/card.dart';
import '../../../shared/utils/card_utils.dart';

/// Playing card (design language §4 "Playing card"): corner index — rank over
/// suit — plus one large pip in the far corner. No pip grids; that is what
/// keeps the face readable down to 40px.
class CardWidget extends StatelessWidget {
  final PlayingCard? card;
  final bool faceUp;
  final bool selected;
  final bool enabled;

  /// Illegal-to-play cards sit at 45% opacity.
  final bool dimmed;

  /// Drops the large corner pip, leaving the index alone. Used when cards
  /// overlap and the pip would be half-hidden by its neighbour.
  final bool indexOnly;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const CardWidget({
    super.key,
    this.card,
    this.faceUp = true,
    this.selected = false,
    this.enabled = true,
    this.dimmed = false,
    this.indexOnly = false,
    this.onTap,
    this.width = 60,
    this.height = 84,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = width * 0.08;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        transform: Matrix4.translationValues(0, selected ? -8 : 0, 0),
        decoration: BoxDecoration(
          color: faceUp ? colors.cardFace : colors.cardBackPrimary,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.selectedBorder,
                    spreadRadius: 2,
                    blurRadius: 0,
                  ),
                  const BoxShadow(
                    color: Color(0x73000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Opacity(
          opacity: dimmed ? 0.45 : 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: faceUp && card != null
                ? _buildFace(colors)
                : _buildBack(colors),
          ),
        ),
      ),
    );
  }

  Widget _buildFace(AppColors colors) {
    final color = CardUtils.suitColor(card!.suit, colors);
    final pad = width * 0.09;
    final rankSize = width * 0.26;
    final suitSize = width * 0.19;
    final pipSize = width * 0.34;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: pad,
          top: pad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                card!.rank.display,
                style: TextStyle(
                  color: color,
                  fontSize: rankSize,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              SizedBox(height: pad * 0.35),
              Text(
                card!.suit.symbol,
                style: TextStyle(color: color, fontSize: suitSize, height: 1),
              ),
            ],
          ),
        ),
        if (!indexOnly)
          Positioned(
            right: width * 0.125,
            bottom: pad,
            child: Text(
              card!.suit.symbol,
              style: TextStyle(color: color, fontSize: pipSize, height: 1),
            ),
          ),
      ],
    );
  }

  Widget _buildBack(AppColors colors) {
    final border = width * 0.055;
    return CustomPaint(
      painter: _CardBackPainter(
        slate: colors.cardBackPrimary,
        stripe: colors.cardBackDetail,
        border: colors.cardFace,
        borderWidth: border.clamp(2.0, 4.0),
        radius: width * 0.08,
      ),
      size: Size(width, height),
    );
  }
}

/// Card back: cool slate, 45° hairline stripes, card-stock border, no logo.
class _CardBackPainter extends CustomPainter {
  final Color slate;
  final Color stripe;
  final Color border;
  final double borderWidth;
  final double radius;

  _CardBackPainter({
    required this.slate,
    required this.stripe,
    required this.border,
    required this.borderWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = slate);

    canvas.save();
    canvas.clipRect(rect);
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = 2;
    // 45° hairlines on a 6px perpendicular pitch.
    const pitch = 6 * math.sqrt2;
    for (double d = 0; d < size.width + size.height; d += pitch) {
      canvas.drawLine(Offset(d, 0), Offset(d - size.height, size.height), paint);
    }
    canvas.restore();

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(borderWidth / 2),
        Radius.circular(math.max(radius - borderWidth / 2, 0)),
      ),
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  bool shouldRepaint(_CardBackPainter old) =>
      old.slate != slate ||
      old.stripe != stripe ||
      old.border != border ||
      old.borderWidth != borderWidth ||
      old.radius != radius;
}

/// A card widget that animates a flip from back to face.
/// Trigger by setting [faceUp] from false to true.
class FlippableCardWidget extends StatefulWidget {
  final PlayingCard? card;
  final bool faceUp;
  final double width;
  final double height;
  final Duration duration;
  final Duration delay;

  const FlippableCardWidget({
    super.key,
    this.card,
    this.faceUp = false,
    this.width = 60,
    this.height = 84,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
  });

  @override
  State<FlippableCardWidget> createState() => _FlippableCardWidgetState();
}

class _FlippableCardWidgetState extends State<FlippableCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFace = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _showFace = widget.faceUp;
    if (widget.faceUp) {
      _controller.value = 1.0;
    }
    _animation.addListener(() {
      final shouldShowFace = _animation.value >= 0.5;
      if (shouldShowFace != _showFace) {
        setState(() => _showFace = shouldShowFace);
      }
    });
  }

  @override
  void didUpdateWidget(FlippableCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.faceUp && !oldWidget.faceUp) {
      if (widget.delay > Duration.zero) {
        Future.delayed(widget.delay, () {
          if (mounted) _controller.forward(from: 0);
        });
      } else {
        _controller.forward(from: 0);
      }
    } else if (!widget.faceUp && oldWidget.faceUp) {
      _controller.reverse(from: 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        final angle = value <= 0.5 ? value * math.pi : (1.0 - value) * math.pi;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);
        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: CardWidget(
            card: widget.card,
            faceUp: _showFace,
            enabled: false,
            width: widget.width,
            height: widget.height,
          ),
        );
      },
    );
  }
}
