import 'package:flutter/material.dart';
import '../../../core/models/card.dart';
import 'card_widget.dart';

class CutCardDisplay extends StatefulWidget {
  final PlayingCard? cutCard;

  const CutCardDisplay({super.key, this.cutCard});

  @override
  State<CutCardDisplay> createState() => _CutCardDisplayState();
}

class _CutCardDisplayState extends State<CutCardDisplay> {
  bool _wasRevealed = false;
  bool _shouldAnimate = false;

  @override
  void didUpdateWidget(CutCardDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cutCard != null && oldWidget.cutCard == null) {
      // Cut card just appeared — animate the flip
      _shouldAnimate = true;
      _wasRevealed = true;
    } else if (widget.cutCard == null && _wasRevealed) {
      // New round: reset
      _shouldAnimate = false;
      _wasRevealed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Cut Card',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        if (_shouldAnimate)
          FlippableCardWidget(
            card: widget.cutCard,
            faceUp: widget.cutCard != null,
            width: 50,
            height: 75,
            duration: const Duration(milliseconds: 400),
          )
        else
          CardWidget(
            card: widget.cutCard,
            faceUp: widget.cutCard != null,
            enabled: false,
            width: 50,
            height: 75,
          ),
      ],
    );
  }
}
