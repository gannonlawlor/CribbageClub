import 'package:flutter/material.dart';
import '../../../core/models/card.dart';
import '../../../shared/utils/card_dimensions.dart';
import '../../../shared/utils/card_utils.dart';
import 'card_widget.dart';

class HandFan extends StatelessWidget {
  final List<PlayingCard> cards;
  final Set<int> selectedIndices;
  final bool enabled;
  final void Function(int index)? onCardTap;

  const HandFan({
    super.key,
    required this.cards,
    this.selectedIndices = const {},
    this.enabled = true,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = CardUtils.sorted(cards);

    return LayoutBuilder(
      builder: (context, constraints) {
        final dims = CardDimensions(constraints.maxWidth);
        final cardW = dims.handCardWidth;
        final cardH = dims.handCardHeight;

        if (sorted.isEmpty) {
          return SizedBox(height: cardH + 12);
        }
        final available = constraints.maxWidth;
        final visibleW = dims.handCardVisibleForCount(sorted.length, available);
        final stackWidth = dims.handStackWidthForCount(sorted.length, available);
        // Center the stack
        final startX = (available - stackWidth) / 2;

        return SizedBox(
          height: cardH + 12, // extra for selection lift
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < sorted.length; i++)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  left: startX + i * visibleW,
                  bottom: 0,
                  child: CardWidget(
                    card: sorted[i],
                    faceUp: true,
                    selected: selectedIndices.contains(i),
                    enabled: enabled,
                    onTap: onCardTap != null ? () => onCardTap!(i) : null,
                    width: cardW,
                    height: cardH,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class OpponentHand extends StatelessWidget {
  final int cardCount;

  const OpponentHand({super.key, required this.cardCount});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dims = CardDimensions(constraints.maxWidth);
        final cardW = dims.smallCardWidth;
        final cardH = dims.smallCardHeight;

        if (cardCount <= 0) {
          return SizedBox(height: cardH);
        }

        final stackWidth = dims.opponentStackWidth(cardCount);
        final startX = (constraints.maxWidth - stackWidth) / 2;

        return SizedBox(
          height: cardH,
          child: Stack(
            children: [
              for (int i = 0; i < cardCount; i++)
                Positioned(
                  left: startX + i * dims.opponentCardVisible,
                  top: 0,
                  child: CardWidget(faceUp: false, width: cardW, height: cardH),
                ),
            ],
          ),
        );
      },
    );
  }
}
