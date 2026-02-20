import 'package:flutter/material.dart';
import '../../../config/constants.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/game_state.dart';

class StageIndicator extends StatelessWidget {
  final GameStage stage;
  final bool isMyTurn;
  final bool isDealer;
  final bool isLocalGame;
  final String? currentPlayerName;
  final int selectedCardCount;

  const StageIndicator({
    super.key,
    required this.stage,
    required this.isMyTurn,
    this.isDealer = false,
    this.isLocalGame = false,
    this.currentPlayerName,
    this.selectedCardCount = 0,
  });

  String get _message {
    switch (stage) {
      case GameStage.dealing:
        return 'Dealing cards...';
      case GameStage.discardingToCrib:
        final cribOwner = isDealer ? 'your' : "opponent's";
        return isMyTurn
            ? 'Discard 2 to $cribOwner crib ($selectedCardCount/2 selected)'
            : 'Discard to $cribOwner crib';
      case GameStage.cutting:
        return isMyTurn ? 'Tap to cut the deck' : 'Cutting the deck';
      case GameStage.pegging:
        return isMyTurn && !isLocalGame ? 'Your turn to play' : 'Pegging';
      case GameStage.counting:
        return isMyTurn ? 'Count your cards!' : 'Counting';
      case GameStage.gameOver:
        return 'Game Over!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isMyTurn
              ? colors.accentSubtle
              : colors.surfaceDim,
          borderRadius: BorderRadius.circular(16),
          border: isMyTurn
              ? Border.all(color: colors.accentBorder)
              : null,
        ),
        child: AnimatedSwitcher(
          duration: AppConstants.stageTransitionDuration,
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            _message,
            key: ValueKey('${stage.name}_$isMyTurn'),
            style: TextStyle(
              color: isMyTurn ? colors.accent : colors.textSecondary,
              fontSize: 13,
              fontWeight: isMyTurn ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
