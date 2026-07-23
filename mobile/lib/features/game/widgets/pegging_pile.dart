import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/card.dart';
import 'card_widget.dart';

/// The pegging pile: played cards overlap left-to-right, each nudged 12px
/// toward the player who played it so the exchange reads at a glance.
///
/// A card arrives from its owner's side of the table and settles into place
/// (design language §7: 180ms ease-out, translate plus a small settle
/// rotation), so you see where it came from rather than finding it already
/// there.
class PeggingPile extends StatefulWidget {
  final List<PlayingCard> cards;

  /// Parallel to [cards]: true when the local player played that card.
  final List<bool> playedByMe;
  final double cardWidth;

  /// Vertical nudge toward each player.
  static const double lean = 12;

  /// How far outside the pile a card starts its flight.
  static const double _entryDistance = 150;

  /// AnimatedRotation counts turns, not radians — 3° of settle.
  static const double _entryTilt = 3 / 360;
  static const Duration _entryDuration = Duration(milliseconds: 180);

  const PeggingPile({
    super.key,
    required this.cards,
    required this.playedByMe,
    required this.cardWidth,
  });

  @override
  State<PeggingPile> createState() => _PeggingPileState();
}

class _PeggingPileState extends State<PeggingPile> {
  /// How many cards have finished arriving. Anything past this is still in
  /// flight and gets drawn at its entry offset for one frame.
  late int _settled = widget.cards.length;

  @override
  void didUpdateWidget(PeggingPile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cards.length > oldWidget.cards.length) {
      // The new card renders offset first, then settles on the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _settled = widget.cards.length);
      });
    } else if (widget.cards.length < oldWidget.cards.length) {
      // Pile reset between rounds — nothing to fly in.
      _settled = widget.cards.length;
    }
  }

  double get _cardHeight => widget.cardWidth / (2.5 / 3.5);
  double get _visible => widget.cardWidth * 0.535;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final cards = widget.cards;
    final height = _cardHeight + PeggingPile.lean * 2;

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

    final stackWidth = widget.cardWidth + (cards.length - 1) * _visible;

    return SizedBox(
      height: height,
      width: stackWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [for (int i = 0; i < cards.length; i++) _card(i)],
      ),
    );
  }

  Widget _card(int i) {
    final mine = i < widget.playedByMe.length && widget.playedByMe[i];
    final resting =
        PeggingPile.lean + (mine ? PeggingPile.lean : -PeggingPile.lean);
    final arriving = i >= _settled;

    return AnimatedPositioned(
      duration: PeggingPile._entryDuration,
      curve: Curves.easeOutCubic,
      left: i * _visible,
      // Cards fly in from their owner's edge of the table.
      top: arriving
          ? resting +
                (mine
                    ? PeggingPile._entryDistance
                    : -PeggingPile._entryDistance)
          : resting,
      child: AnimatedRotation(
        duration: PeggingPile._entryDuration,
        curve: Curves.easeOutCubic,
        turns: arriving
            ? (mine ? PeggingPile._entryTilt : -PeggingPile._entryTilt)
            : 0,
        child: CardWidget(
          card: widget.cards[i],
          faceUp: true,
          enabled: false,
          width: widget.cardWidth,
          height: _cardHeight,
        ),
      ),
    );
  }
}
