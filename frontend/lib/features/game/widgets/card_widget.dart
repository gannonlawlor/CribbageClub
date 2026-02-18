import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/card.dart';
import '../../../shared/utils/card_utils.dart';

class CardWidget extends StatelessWidget {
  final PlayingCard? card;
  final bool faceUp;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const CardWidget({
    super.key,
    this.card,
    this.faceUp = true,
    this.selected = false,
    this.enabled = true,
    this.onTap,
    this.width = 60,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        transform: Matrix4.translationValues(0, selected ? -12 : 0, 0),
        decoration: BoxDecoration(
          color: faceUp ? AppTheme.cardWhite : AppTheme.feltGreenDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.goldAccent : AppTheme.cardBorder,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppTheme.goldAccent.withValues(alpha: 0.4)
                  : Colors.black26,
              blurRadius: selected ? 8 : 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: faceUp && card != null ? _buildFace() : _buildBack(),
      ),
    );
  }

  Widget _buildFace() {
    final color = CardUtils.suitColor(card!.suit);
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card!.rank.display,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            card!.suit.symbol,
            style: TextStyle(color: color, fontSize: 14),
          ),
          const Spacer(),
          Center(
            child: Text(
              card!.suit.symbol,
              style: TextStyle(color: color, fontSize: 28),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          colors: [AppTheme.feltGreen, AppTheme.feltGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.style, color: Colors.white38, size: 30),
      ),
    );
  }
}
