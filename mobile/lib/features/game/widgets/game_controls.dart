import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/game_state.dart';

class GameControls extends StatelessWidget {
  final GameStage stage;
  final bool isMyTurn;
  final int selectedCardCount;
  final bool isDiscarding;
  final bool showCountingOverlay;
  final VoidCallback? onDiscard;
  final VoidCallback? onCut;
  final VoidCallback? onCount;
  final VoidCallback? onDeal;
  final VoidCallback? onGo;
  final VoidCallback? onPlayCard;
  final bool autoDeal;
  final bool autoCut;
  final bool autoGo;
  final bool autoPlayPegging;
  final bool canPlayCard;
  final bool hasSelectedCard;

  const GameControls({
    super.key,
    required this.stage,
    required this.isMyTurn,
    this.selectedCardCount = 0,
    this.isDiscarding = false,
    this.showCountingOverlay = false,
    this.onDiscard,
    this.onCut,
    this.onCount,
    this.onDeal,
    this.onGo,
    this.onPlayCard,
    this.autoDeal = true,
    this.autoCut = true,
    this.autoGo = true,
    this.autoPlayPegging = true,
    this.canPlayCard = true,
    this.hasSelectedCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = (!isMyTurn && stage != GameStage.gameOver)
        ? <Widget>[]
        : _buildButtons(context);

    // Always reserve the same height so the layout doesn't shift.
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons,
      ),
    );
  }

  List<Widget> _buildButtons(BuildContext context) {
    switch (stage) {
      case GameStage.dealing:
        if (!autoDeal) {
          return [
            _ActionButton(
              label: 'Deal',
              onPressed: onDeal,
              icon: Icons.style,
            ),
          ];
        }
        return [];
      case GameStage.discardingToCrib:
        return [
          _ActionButton(
            label: isDiscarding
                ? 'Discarding...'
                : 'Discard ($selectedCardCount/2)',
            onPressed: selectedCardCount == 2 && !isDiscarding
                ? onDiscard
                : null,
            icon: Icons.arrow_downward,
          ),
        ];
      case GameStage.cutting:
        if (!autoCut) {
          return [
            _ActionButton(
              label: 'Cut Deck',
              onPressed: onCut,
              icon: Icons.content_cut,
            ),
          ];
        }
        return [];
      case GameStage.pegging:
        if (!canPlayCard && !autoGo) {
          return [
            _ActionButton(
              label: 'Go',
              onPressed: onGo,
              icon: Icons.front_hand,
            ),
          ];
        }
        if (!autoPlayPegging && hasSelectedCard) {
          return [
            _ActionButton(
              label: 'Play Card',
              onPressed: onPlayCard,
              icon: Icons.play_arrow,
            ),
          ];
        }
        return [];
      case GameStage.counting:
        if (showCountingOverlay) return [];
        return [
          _ActionButton(
            label: 'Count Hand',
            onPressed: onCount,
            icon: Icons.calculate,
          ),
        ];
      case GameStage.gameOver:
        return [];
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  const _ActionButton({
    required this.label,
    this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null
              ? colors.buttonPrimary
              : Colors.grey.shade700,
          foregroundColor: colors.accentOnSurface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}
