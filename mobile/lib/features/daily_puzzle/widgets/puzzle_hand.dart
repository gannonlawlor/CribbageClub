import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../config/constants.dart';
import '../../../core/models/card.dart';
import '../../game/widgets/card_widget.dart';

/// The six dealt cards as two rows of three, big enough to read the whole
/// hand at a glance — a puzzle is a reading problem before it's a tapping
/// one. Selection is the in-game affordance: the card lifts 8px and takes a
/// green ring (design language §4).
class PuzzleHand extends StatelessWidget {
  final List<PlayingCard> cards;
  final Set<PlayingCard> selected;
  final void Function(PlayingCard card) onTap;

  static const int _perRow = 3;
  static const double _gap = 10;

  /// Room above each row for the selected-card lift.
  static const double _liftRoom = 8;

  /// Cards stop growing here so a tablet doesn't get playing-card posters.
  static const double maxCardWidth = 128;

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
        final rows = (cards.length / _perRow).ceil();

        // Fit the width, then shrink again if the rows would not fit the
        // height the screen has left for them.
        final byWidth = (constraints.maxWidth - _gap * (_perRow - 1)) / _perRow;
        var cardWidth = math.min(maxCardWidth, byWidth);

        if (constraints.hasBoundedHeight) {
          final slack = _gap * (rows - 1) + _liftRoom * rows;
          final byHeight =
              (constraints.maxHeight - slack) /
              rows *
              AppConstants.cardAspectRatio;
          cardWidth = math.min(cardWidth, byHeight);
        }

        final cardHeight = cardWidth / AppConstants.cardAspectRatio;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int row = 0; row < rows; row++) ...[
              if (row > 0) const SizedBox(height: _gap),
              SizedBox(
                height: cardHeight + _liftRoom,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (
                      int i = row * _perRow;
                      i < math.min((row + 1) * _perRow, cards.length);
                      i++
                    ) ...[
                      if (i > row * _perRow) const SizedBox(width: _gap),
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
              ),
            ],
          ],
        );
      },
    );
  }
}
