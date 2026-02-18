import 'package:flutter/material.dart';
import '../../../core/models/card.dart';
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < sorted.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: CardWidget(
                card: sorted[i],
                faceUp: true,
                selected: selectedIndices.contains(i),
                enabled: enabled,
                onTap: onCardTap != null ? () => onCardTap!(i) : null,
              ),
            ),
        ],
      ),
    );
  }
}

class OpponentHand extends StatelessWidget {
  final int cardCount;

  const OpponentHand({super.key, required this.cardCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < cardCount; i++)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: CardWidget(
              faceUp: false,
              width: 45,
              height: 67,
            ),
          ),
      ],
    );
  }
}
