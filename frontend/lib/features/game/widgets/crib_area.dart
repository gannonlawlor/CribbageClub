import 'package:flutter/material.dart';
import '../../../core/models/card.dart';
import 'card_widget.dart';

class CribArea extends StatelessWidget {
  final List<PlayingCard> crib;
  final bool revealed;

  const CribArea({
    super.key,
    required this.crib,
    this.revealed = false,
  });

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
          children: revealed && crib.isNotEmpty
              ? crib
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
                  .toList()
              : List.generate(
                  4,
                  (_) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1),
                    child: CardWidget(
                      faceUp: false,
                      width: 40,
                      height: 60,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
