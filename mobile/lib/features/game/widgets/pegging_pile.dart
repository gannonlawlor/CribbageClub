import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/card.dart';
import 'card_widget.dart';

/// Colour matrix greying out a spent card: desaturated and dimmed a touch,
/// but fully opaque. `t` runs 0 (untouched) → 1 (fully spent).
List<double> spentGreyMatrix(double t) {
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  final s = 1.0 - 0.70 * t; // keep 30% of the colour at rest
  final v = 1.0 - 0.18 * t; // and shave a little brightness
  return [
    v * (lr * (1 - s) + s),
    v * (lg * (1 - s)),
    v * (lb * (1 - s)),
    0,
    0,
    v * (lr * (1 - s)),
    v * (lg * (1 - s) + s),
    v * (lb * (1 - s)),
    0,
    0,
    v * (lr * (1 - s)),
    v * (lg * (1 - s)),
    v * (lb * (1 - s) + s),
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

/// The pegging pile: played cards overlap left-to-right, each nudged 12px
/// toward the player who played it so the exchange reads at a glance.
///
/// A card arrives from its owner's side of the table and settles into place
/// (design language §7: 180ms ease-out, translate plus a small settle
/// rotation), so you see where it came from rather than finding it already
/// there.
///
/// When a count closes (31 or a go), the engine clears its pile but the cards
/// stay on the table here: the first [previousCount] cards slide left into a
/// tight, faded stack so the new count plays out beside everything already
/// spent this round.
class PeggingPile extends StatefulWidget {
  /// Every card played this round, oldest first — spent piles then the live
  /// count.
  final List<PlayingCard> cards;

  /// Parallel to [cards]: true when the local player played that card.
  final List<bool> playedByMe;

  /// How many of [cards] belong to already-closed counts.
  final int previousCount;
  final double cardWidth;

  /// Vertical nudge toward each player.
  static const double lean = 12;

  /// How far outside the pile a card starts its flight.
  static const double _entryDistance = 150;

  /// AnimatedRotation counts turns, not radians — 3° of settle.
  static const double _entryTilt = 3 / 360;
  static const Duration _entryDuration = Duration(milliseconds: 180);

  /// How the pile reshuffles when a count closes and cards fade back.
  static const Duration _restackDuration = Duration(milliseconds: 300);

  const PeggingPile({
    super.key,
    required this.cards,
    required this.playedByMe,
    required this.cardWidth,
    this.previousCount = 0,
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

  /// Overlap step for the live count.
  double get _visible => widget.cardWidth * 0.535;

  /// Overlap step for spent cards — just enough to count them.
  double get _prevVisible => widget.cardWidth * 0.24;

  /// Breathing room between the spent stack and the live count.
  double get _gap => widget.cardWidth * 0.3;

  double _leftFor(int i) {
    final prev = widget.previousCount;
    if (i < prev) return i * _prevVisible;
    final prevWidth = prev > 0
        ? widget.cardWidth + (prev - 1) * _prevVisible + _gap
        : 0.0;
    return prevWidth + (i - prev) * _visible;
  }

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

    final stackWidth = _leftFor(cards.length - 1) + widget.cardWidth;

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
    final spent = i < widget.previousCount;
    final mine = i < widget.playedByMe.length && widget.playedByMe[i];
    // Spent cards keep their lean so who played what stays readable.
    final resting =
        PeggingPile.lean + (mine ? PeggingPile.lean : -PeggingPile.lean);
    final arriving = i >= _settled;

    return AnimatedPositioned(
      duration: arriving || !spent
          ? PeggingPile._entryDuration
          : PeggingPile._restackDuration,
      curve: Curves.easeOutCubic,
      left: _leftFor(i),
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
        // Spent cards stay fully opaque — they grey out (desaturate and
        // darken) instead, so the table never shows through them.
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: spent ? 1.0 : 0.0),
          duration: PeggingPile._restackDuration,
          builder: (context, g, child) => ColorFiltered(
            colorFilter: ColorFilter.matrix(spentGreyMatrix(g)),
            child: child,
          ),
          child: CardWidget(
            card: widget.cards[i],
            faceUp: true,
            enabled: false,
            width: widget.cardWidth,
            height: _cardHeight,
          ),
        ),
      ),
    );
  }
}
