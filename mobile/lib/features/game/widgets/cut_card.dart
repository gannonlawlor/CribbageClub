import 'package:flutter/material.dart';
import '../../../core/models/card.dart';
import '../../../shared/utils/card_dimensions.dart';
import 'card_widget.dart';

class CutCardDisplay extends StatefulWidget {
  final PlayingCard? cutCard;

  const CutCardDisplay({super.key, this.cutCard});

  @override
  State<CutCardDisplay> createState() => _CutCardDisplayState();
}

class _CutCardDisplayState extends State<CutCardDisplay> {
  bool _wasRevealed = false;
  bool _shouldAnimate = false;

  @override
  void didUpdateWidget(CutCardDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cutCard != null && oldWidget.cutCard == null) {
      _shouldAnimate = true;
      _wasRevealed = true;
    } else if (widget.cutCard == null && _wasRevealed) {
      _shouldAnimate = false;
      _wasRevealed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final dims = CardDimensions(availableWidth);
        final cardW = dims.playCardWidth;
        final cardH = dims.playCardHeight;

        if (_shouldAnimate) {
          return FlippableCardWidget(
            card: widget.cutCard,
            faceUp: widget.cutCard != null,
            width: cardW,
            height: cardH,
            duration: const Duration(milliseconds: 400),
          );
        }

        return CardWidget(
          card: widget.cutCard,
          faceUp: widget.cutCard != null,
          enabled: false,
          width: cardW,
          height: cardH,
        );
      },
    );
  }
}
