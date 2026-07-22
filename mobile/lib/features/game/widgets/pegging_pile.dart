import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/card.dart';
import 'card_widget.dart';

/// The pegging pile: played cards overlap left-to-right, each nudged 12px
/// toward the player who played it so the exchange reads at a glance.
class PeggingPile extends StatelessWidget {
  final List<PlayingCard> cards;

  /// Parallel to [cards]: true when the local player played that card.
  final List<bool> playedByMe;
  final double cardWidth;

  /// Vertical nudge toward each player.
  static const double lean = 12;

  const PeggingPile({
    super.key,
    required this.cards,
    required this.playedByMe,
    required this.cardWidth,
  });

  double get _cardHeight => cardWidth / (2.5 / 3.5);
  double get _visible => cardWidth * 0.535;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final height = _cardHeight + lean * 2;

    if (cards.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No cards played',
            style: TextStyle(color: colors.textDisabled, fontSize: 12),
          ),
        ),
      );
    }

    final stackWidth = cardWidth + (cards.length - 1) * _visible;

    return SizedBox(
      height: height,
      width: stackWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < cards.length; i++)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              left: i * _visible,
              top:
                  lean +
                  ((i < playedByMe.length && playedByMe[i]) ? lean : -lean),
              child: CardWidget(
                card: cards[i],
                faceUp: true,
                enabled: false,
                width: cardWidth,
                height: _cardHeight,
              ),
            ),
        ],
      ),
    );
  }
}
