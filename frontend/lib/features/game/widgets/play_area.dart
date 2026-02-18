import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/card.dart';
import 'card_widget.dart';

class PlayArea extends StatelessWidget {
  final List<PlayingCard> playedCards;
  final int peggingCount;

  const PlayArea({
    super.key,
    required this.playedCards,
    required this.peggingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Count: $peggingCount',
            style: const TextStyle(
              color: AppTheme.goldAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: playedCards.isEmpty
              ? const Center(
                  child: Text(
                    'No cards played yet',
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final card in playedCards)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: CardWidget(
                            card: card,
                            faceUp: true,
                            enabled: false,
                            width: 50,
                            height: 75,
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
