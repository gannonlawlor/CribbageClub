import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
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
    final colors = context.appColors;
    return Row(
      children: [
        // Played cards stack
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dims = CardDimensions(constraints.maxWidth);
              final cardW = dims.playCardWidth;
              final cardH = dims.playCardHeight;

              if (playedCards.isEmpty) {
                return SizedBox(
                  height: cardH,
                  child: Center(
                    child: Text(
                      'No cards played yet',
                      style: TextStyle(
                        color: colors.textDisabled,
                        fontSize: 12,
                      ),
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
        ),
        // The count is always legible at a glance — largest live number
        // on screen (design language §1).
        SizedBox(
          width: 88,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'COUNT',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 120),
                child: Text(
                  '$peggingCount',
                  key: ValueKey(peggingCount),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 44,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
