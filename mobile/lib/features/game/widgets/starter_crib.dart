import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/card.dart';
import 'card_widget.dart';

/// Starter card + the crib stack, anchored at the dealer's end of the table.
class StarterCribCluster extends StatelessWidget {
  final PlayingCard? starter;
  final List<PlayingCard> crib;
  final bool cribRevealed;

  /// Whose crib it is — "YOURS" or the opponent's possessive.
  final String cribOwner;
  final double cardWidth;

  /// Anchors the discard flight's landing point on the crib stack.
  final GlobalKey? cribKey;

  /// False while the starter is shown large in the middle of the table — it
  /// belongs in one place at a time.
  final bool showStarter;

  const StarterCribCluster({
    super.key,
    required this.starter,
    required this.crib,
    required this.cribRevealed,
    required this.cribOwner,
    required this.cardWidth,
    this.cribKey,
    this.showStarter = true,
  });

  double get _cardHeight => cardWidth / (2.5 / 3.5);

  /// Total height the cluster occupies — the table reserves this so the
  /// centred count block never runs into it.
  static double heightFor(double cardWidth) =>
      cardWidth / (2.5 / 3.5) + 6 + 13 + 2;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showStarter) ...[
          _Labelled(
            label: 'Starter',
            labelWidth: cardWidth + 8,
            child: starter != null
                ? FlippableCardWidget(
                    card: starter,
                    faceUp: true,
                    width: cardWidth,
                    height: _cardHeight,
                    duration: const Duration(milliseconds: 240),
                  )
                : CardWidget(
                    faceUp: false,
                    enabled: false,
                    width: cardWidth,
                    height: _cardHeight,
                  ),
          ),
          const SizedBox(width: 14),
        ],
        _Labelled(
          key: cribKey,
          label: cribOwner,
          labelWidth: cardWidth + 14,
          child: cribRevealed && crib.isNotEmpty
              ? _RevealedCrib(
                  crib: crib,
                  cardWidth: cardWidth,
                  cardHeight: _cardHeight,
                )
              : _CribStack(cardWidth: cardWidth, cardHeight: _cardHeight),
        ),
      ],
    );
  }
}

class _Labelled extends StatelessWidget {
  final String label;

  /// Keeps a long opponent name from running into the centre of the table.
  final double labelWidth;
  final Widget child;

  const _Labelled({
    super.key,
    required this.label,
    required this.labelWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 6),
        SizedBox(
          width: labelWidth,
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// Two face-down cards, slightly splayed, with a CRIB tab.
class _CribStack extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;

  const _CribStack({required this.cardWidth, required this.cardHeight});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: cardWidth + 6,
      height: cardHeight + 2,
      child: Stack(
        children: [
          Positioned(
            left: 6,
            top: 0,
            child: Transform.rotate(
              angle: 3 * math.pi / 180,
              child: CardWidget(
                faceUp: false,
                enabled: false,
                width: cardWidth,
                height: cardHeight,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 2,
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CardWidget(
                    faceUp: false,
                    enabled: false,
                    width: cardWidth,
                    height: cardHeight,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'CRIB',
                      style: TextStyle(
                        color: colors.cardFace.withValues(alpha: 0.85),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The crib laid face-up during the count.
class _RevealedCrib extends StatelessWidget {
  final List<PlayingCard> crib;
  final double cardWidth;
  final double cardHeight;

  const _RevealedCrib({
    required this.crib,
    required this.cardWidth,
    required this.cardHeight,
  });

  @override
  Widget build(BuildContext context) {
    final visible = cardWidth * 0.34;
    return SizedBox(
      width: cardWidth + (crib.length - 1) * visible,
      height: cardHeight + 2,
      child: Stack(
        children: [
          for (int i = 0; i < crib.length; i++)
            Positioned(
              left: i * visible,
              top: 0,
              child: FlippableCardWidget(
                card: crib[i],
                faceUp: true,
                width: cardWidth,
                height: cardHeight,
                duration: const Duration(milliseconds: 240),
                delay: Duration(milliseconds: 80 * i),
              ),
            ),
        ],
      ),
    );
  }
}
