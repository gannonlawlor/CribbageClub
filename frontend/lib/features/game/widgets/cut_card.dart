import 'package:flutter/material.dart';
import '../../../core/models/card.dart';
import 'card_widget.dart';

class CutCardDisplay extends StatelessWidget {
  final PlayingCard? cutCard;

  const CutCardDisplay({super.key, this.cutCard});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Cut Card',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        CardWidget(
          card: cutCard,
          faceUp: cutCard != null,
          enabled: false,
          width: 50,
          height: 75,
        ),
      ],
    );
  }
}
