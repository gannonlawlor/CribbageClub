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
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        transform: Matrix4.translationValues(0, selected ? -12 : 0, 0),
        decoration: BoxDecoration(
          color: faceUp ? AppTheme.cardWhite : AppTheme.feltGreenDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.goldAccent : AppTheme.cardBorder,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppTheme.goldAccent.withValues(alpha: 0.4)
                  : Colors.black26,
              blurRadius: selected ? 8 : 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: faceUp && card != null ? _buildFace() : _buildBack(),
      ),
    );
  }

  Widget _buildFace() {
    final color = CardUtils.suitColor(card!.suit);
    final scale = height / 90; // scale relative to default card height
    final rankText = card!.rank.display;
    final suitText = card!.suit.symbol;
    return Padding(
      padding: EdgeInsets.all(3 * scale),
      child: Stack(
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
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                Text(
                  suitText,
                  style: TextStyle(color: color, fontSize: 11 * scale, height: 1.0),
                ),
              ],
            ),
          ),
          // Center: large suit
          Center(
            child: Text(
              suitText,
              style: TextStyle(color: color, fontSize: 26 * scale),
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
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    suitText,
                    style: TextStyle(color: color, fontSize: 11 * scale, height: 1.0),
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
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          colors: [AppTheme.feltGreen, AppTheme.feltGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.style, color: Colors.white38, size: 30),
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
    this.height = 90,
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
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _showFace = widget.faceUp;
    if (widget.faceUp) {
      _controller.value = 1.0;
    }
    _animation.addListener(() {
      // Swap face/back at the halfway point
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
      // Flip from back to face
      if (widget.delay > Duration.zero) {
        Future.delayed(widget.delay, () {
          if (mounted) _controller.forward(from: 0);
        });
      } else {
        _controller.forward(from: 0);
      }
    } else if (!widget.faceUp && oldWidget.faceUp) {
      // Flip from face to back
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
        // Animate 0→π/2 then π/2→0 so the card never appears mirrored.
        // First half (0→0.5): back rotates away from viewer (0→π/2)
        // Second half (0.5→1): face rotates toward viewer (π/2→0)
        final value = _animation.value;
        final angle = value <= 0.5
            ? value * math.pi // 0 → π/2
            : (1.0 - value) * math.pi; // π/2 → 0
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
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
