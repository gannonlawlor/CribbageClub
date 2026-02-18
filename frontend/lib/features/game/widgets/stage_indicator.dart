import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/game_state.dart';

class StageIndicator extends StatelessWidget {
  final GameStage stage;
  final bool isMyTurn;
  final String? currentPlayerName;
  final int selectedCardCount;

  const StageIndicator({
    super.key,
    required this.stage,
    required this.isMyTurn,
    this.currentPlayerName,
    this.selectedCardCount = 0,
  });

  String get _message {
    switch (stage) {
      case GameStage.dealing:
        return 'Dealing cards...';
      case GameStage.discardingToCrib:
        return isMyTurn
            ? 'Select 2 cards to discard ($selectedCardCount/2 selected)'
            : 'Waiting for ${currentPlayerName ?? "opponent"} to discard...';
      case GameStage.cutting:
        return isMyTurn ? 'Tap to cut the deck' : 'Waiting for cut...';
      case GameStage.pegging:
        return isMyTurn
            ? 'Play a card or tap Go if you can\'t play'
            : 'Waiting for opponent...';
      case GameStage.counting:
        return isMyTurn ? 'Tap to count your hand' : 'Waiting for count...';
      case GameStage.gameOver:
        return 'Game Over!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isMyTurn ? AppTheme.goldAccent.withValues(alpha: 0.2) : Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: isMyTurn
            ? Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.5))
            : null,
      ),
      child: Text(
        _message,
        style: TextStyle(
          color: isMyTurn ? AppTheme.goldAccent : Colors.white70,
          fontSize: 16,
          fontWeight: isMyTurn ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
