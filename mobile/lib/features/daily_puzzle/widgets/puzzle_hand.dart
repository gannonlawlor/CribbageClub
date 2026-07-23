import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../config/constants.dart';
import '../../../core/models/card.dart';
import '../../game/widgets/card_widget.dart';

/// The six dealt cards, laid out as one row the way a hand reads at the table
/// rather than a grid of oversized tiles. Selection is the in-game affordance:
/// the card lifts 8px and takes a green ring (design language §4).
class PuzzleHand extends StatelessWidget {
  final List<PlayingCard> cards;
  final Set<PlayingCard> selected;
  final void Function(PlayingCard card) onTap;

  /// The hand never grows past the in-game card size.
  static const double maxCardWidth = 74;
  static const double _gap = 6;

  /// Room above the cards for the selected-card lift.
  static const double _liftRoom = 8;

  const PuzzleHand({
    super.key,
    required this.cards,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = cards.length;
        final available = constraints.maxWidth - _gap * (n - 1);
        final cardWidth = math.min(maxCardWidth, available / n);
        final cardHeight = cardWidth / AppConstants.cardAspectRatio;

        return SizedBox(
          height: cardHeight + _liftRoom,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                CardWidget(
                  card: cards[i],
                  selected: selected.contains(cards[i]),
                  onTap: () => onTap(cards[i]),
                  width: cardWidth,
                  height: cardHeight,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
