import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/game_state.dart';

class GameControls extends StatelessWidget {
  final GameStage stage;
  final bool isMyTurn;
  final int selectedCardCount;
  final bool isDiscarding;
  final bool canGo;
  final VoidCallback? onDiscard;
  final VoidCallback? onCut;
  final VoidCallback? onGo;
  final VoidCallback? onCount;

  const GameControls({
    super.key,
    required this.stage,
    required this.isMyTurn,
    this.selectedCardCount = 0,
    this.isDiscarding = false,
    this.canGo = true,
    this.onDiscard,
    this.onCut,
    this.onGo,
    this.onCount,
  });

  @override
  Widget build(BuildContext context) {
    if (!isMyTurn && stage != GameStage.gameOver) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildButtons(),
      ),
    );
  }

  List<Widget> _buildButtons() {
    switch (stage) {
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
        return [
          _ActionButton(
            label: 'Cut Deck',
            onPressed: onCut,
            icon: Icons.content_cut,
          ),
        ];
      case GameStage.pegging:
        return [
          _ActionButton(
            label: 'Go',
            onPressed: canGo ? onGo : null,
            icon: Icons.skip_next,
          ),
        ];
      case GameStage.counting:
        return [
          _ActionButton(
            label: 'Count Hand',
            onPressed: onCount,
            icon: Icons.calculate,
          ),
        ];
      case GameStage.gameOver:
        return [];
      default:
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null
              ? AppTheme.feltGreen
              : Colors.grey.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}
