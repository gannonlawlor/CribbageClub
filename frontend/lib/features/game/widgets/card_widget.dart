import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/card.dart';
import '../../../shared/utils/card_utils.dart';

class CardWidget extends StatelessWidget {
  final PlayingCard? card;
  final bool faceUp;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const CardWidget({
    super.key,
    this.card,
    this.faceUp = true,
    this.selected = false,
    this.enabled = true,
    this.onTap,
    this.width = 60,
    this.height = 84,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        transform: Matrix4.translationValues(0, selected ? -10 : 0, 0),
        decoration: BoxDecoration(
          color: faceUp ? AppTheme.cardWhite : null,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppTheme.goldAccent : Colors.white24,
            width: selected ? 2.0 : 0.5,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: AppTheme.goldAccent.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 1,
              )
            else
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 3,
                offset: Offset(1, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: faceUp && card != null ? _buildFace() : _buildBack(),
        ),
      ),
    );
  }

  Widget _buildFace() {
    final color = CardUtils.suitColor(card!.suit);
    final scale = height / 84;
    final rankText = card!.rank.display;
    final suitText = card!.suit.symbol;
    return Padding(
      padding: EdgeInsets.all(2 * scale),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Top-left: rank + suit
          Positioned(
            top: 0,
            left: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rankText,
                  style: TextStyle(
                    color: color,
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  suitText,
                  style: TextStyle(
                    color: color,
                    fontSize: 12 * scale,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          // Center: large suit
          Center(
            child: Text(
              suitText,
              style: TextStyle(color: color, fontSize: 28 * scale),
            ),
          ),
          // Bottom-right: rank + suit (rotated 180)
          Positioned(
            bottom: 0,
            right: 0,
            child: Transform.rotate(
              angle: math.pi,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rankText,
                    style: TextStyle(
                      color: color,
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    suitText,
                    style: TextStyle(
                      color: color,
                      fontSize: 12 * scale,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        margin: EdgeInsets.all(width * 0.08),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.style,
            color: Colors.white.withValues(alpha: 0.2),
            size: width * 0.4,
          ),
        ),
      ),
    );
  }
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
