import 'package:flutter/material.dart';
import '../../../core/models/card.dart';
import '../../../shared/utils/card_dimensions.dart';
import 'card_widget.dart';

class CribArea extends StatefulWidget {
  final List<PlayingCard> crib;
  final bool revealed;

  const CribArea({super.key, required this.crib, this.revealed = false});

  @override
  State<CribArea> createState() => _CribAreaState();
}

class _CribAreaState extends State<CribArea> {
  bool _wasRevealed = false;
  bool _shouldAnimate = false;

  @override
  void didUpdateWidget(CribArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealed && !oldWidget.revealed && widget.crib.isNotEmpty) {
      _shouldAnimate = true;
      _wasRevealed = true;
    } else if (!widget.revealed && _wasRevealed) {
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
        const count = 4;
        final stackWidth = dims.cribStackWidth(count);

        return SizedBox(
          width: stackWidth,
          height: cardH,
          child: Stack(children: _buildCards(dims, cardW, cardH)),
        );
      },
    );
  }

  List<Widget> _buildCards(CardDimensions dims, double cardW, double cardH) {
    const count = 4;

    if (_shouldAnimate && widget.crib.isNotEmpty) {
      return [
        for (int i = 0; i < widget.crib.length; i++)
          Positioned(
            left: i * dims.cribCardVisible,
            top: 0,
            child: FlippableCardWidget(
              card: widget.crib[i],
              faceUp: widget.revealed,
              width: cardW,
              height: cardH,
              duration: const Duration(milliseconds: 400),
              delay: Duration(milliseconds: 100 * i),
            ),
          ),
      ];
    }

    if (widget.revealed && widget.crib.isNotEmpty) {
      return [
        for (int i = 0; i < widget.crib.length; i++)
          Positioned(
            left: i * dims.cribCardVisible,
            top: 0,
            child: CardWidget(
              card: widget.crib[i],
              faceUp: true,
              enabled: false,
              width: cardW,
              height: cardH,
            ),
          ),
      ];
    }

    return [
      for (int i = 0; i < count; i++)
        Positioned(
          left: i * dims.cribCardVisible,
          top: 0,
          child: CardWidget(faceUp: false, width: cardW, height: cardH),
        ),
    ];
  }
}
