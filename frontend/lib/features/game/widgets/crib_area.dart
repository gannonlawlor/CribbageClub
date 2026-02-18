import 'package:flutter/material.dart';
import '../../../core/models/card.dart';
import 'card_widget.dart';

class CribArea extends StatefulWidget {
  final List<PlayingCard> crib;
  final bool revealed;

  const CribArea({
    super.key,
    required this.crib,
    this.revealed = false,
  });

  @override
  State<CribArea> createState() => _CribAreaState();
}

class _CribAreaState extends State<CribArea> {
  bool _wasRevealed = false;
  bool _shouldAnimate = false;

  @override
  void didUpdateWidget(CribArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealed && !oldWidget.revealed && widget.crib.isNotEmpty) {
      _shouldAnimate = true;
      _wasRevealed = true;
    } else if (!widget.revealed && _wasRevealed) {
      _shouldAnimate = false;
      _wasRevealed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Crib',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: _buildCards(),
        ),
      ],
    );
  }

  List<Widget> _buildCards() {
    if (_shouldAnimate && widget.crib.isNotEmpty) {
      // Staggered flip: each card flips with 100ms delay
      return [
        for (int i = 0; i < widget.crib.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: FlippableCardWidget(
              card: widget.crib[i],
              faceUp: widget.revealed,
              width: 40,
              height: 60,
              duration: const Duration(milliseconds: 400),
              delay: Duration(milliseconds: 100 * i),
            ),
          ),
      ];
    }

    if (widget.revealed && widget.crib.isNotEmpty) {
      return widget.crib
          .map((card) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: CardWidget(
                  card: card,
                  faceUp: true,
                  enabled: false,
                  width: 40,
                  height: 60,
                ),
              ))
          .toList();
    }

    return List.generate(
      4,
      (_) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 1),
        child: CardWidget(
          faceUp: false,
          width: 40,
          height: 60,
        ),
      ),
    );
  }
}
