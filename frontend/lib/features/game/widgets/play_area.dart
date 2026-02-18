import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/card.dart';
import '../../../shared/utils/card_dimensions.dart';
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
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compact pegging count badge
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(peggingCount),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Count: $peggingCount',
              style: const TextStyle(
                color: AppTheme.goldAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final dims = CardDimensions(constraints.maxWidth);
            final cardW = dims.playCardWidth;
            final cardH = dims.playCardHeight;

            if (playedCards.isEmpty) {
              return SizedBox(
                height: cardH,
                child: const Center(
                  child: Text(
                    'No cards played yet',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              );
            }

            final stackWidth = dims.playStackWidth(playedCards.length);
            final startX = (constraints.maxWidth - stackWidth) / 2;

            return SizedBox(
              height: cardH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int i = 0; i < playedCards.length; i++)
                    Positioned(
                      left: startX + i * dims.playCardVisible,
                      top: 0,
                      child: CardWidget(
                        card: playedCards[i],
                        faceUp: true,
                        enabled: false,
                        width: cardW,
                        height: cardH,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
