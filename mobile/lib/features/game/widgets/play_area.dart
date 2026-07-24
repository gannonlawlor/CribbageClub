import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/card.dart';
import '../../../shared/utils/card_dimensions.dart';
import 'card_widget.dart';
import 'pegging_pile.dart' show spentGreyMatrix;

class PlayArea extends StatelessWidget {
  final List<PlayingCard> playedCards;

  /// Cards from counts already closed this round (31 or a go) — kept on the
  /// table as a tight, faded stack beside the live count.
  final List<PlayingCard> previousCards;
  final int peggingCount;

  const PlayArea({
    super.key,
    required this.playedCards,
    this.previousCards = const [],
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

              if (playedCards.isEmpty && previousCards.isEmpty) {
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

              final prevVisible = cardW * 0.24;
              final prevWidth = previousCards.isEmpty
                  ? 0.0
                  : cardW +
                        (previousCards.length - 1) * prevVisible +
                        cardW * 0.3;
              final stackWidth =
                  prevWidth + dims.playStackWidth(playedCards.length);
              final startX = (constraints.maxWidth - stackWidth) / 2;

              return SizedBox(
                height: cardH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (int i = 0; i < previousCards.length; i++)
                      Positioned(
                        left: startX + i * prevVisible,
                        top: 0,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.matrix(spentGreyMatrix(1)),
                          child: CardWidget(
                            card: previousCards[i],
                            faceUp: true,
                            enabled: false,
                            width: cardW,
                            height: cardH,
                          ),
                        ),
                      ),
                    for (int i = 0; i < playedCards.length; i++)
                      Positioned(
                        left: startX + prevWidth + i * dims.playCardVisible,
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
