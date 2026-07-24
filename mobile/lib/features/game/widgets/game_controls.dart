import 'package:flutter/material.dart';
import '../../../core/models/game_state.dart';
import '../../../shared/widgets/cc_buttons.dart';

class GameControls extends StatelessWidget {
  final GameStage stage;
  final bool isMyTurn;
  final int selectedCardCount;
  final bool isDiscarding;
  final bool showCountingOverlay;
  final VoidCallback? onDiscard;
  final VoidCallback? onCut;
  final VoidCallback? onCount;

  /// Opens the counting panel so the player can call the score themselves.
  final VoidCallback? onManualCount;
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
    this.onManualCount,
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
            _ActionButton(label: 'Deal', onPressed: onDeal, icon: Icons.style),
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
            _ActionButton(label: 'Go', onPressed: onGo, icon: Icons.front_hand),
          ];
        }
        // Manual pegging: the button waits, disabled, until a card is
        // selected — appearing out of nowhere invites a mis-tap.
        if (!autoPlayPegging && canPlayCard) {
          return [
            _ActionButton(
              label: hasSelectedCard ? 'Play Card' : 'Select a card',
              onPressed: hasSelectedCard ? onPlayCard : null,
              icon: Icons.play_arrow,
            ),
          ];
        }
        return [];
      case GameStage.counting:
        // The panel takes over once the player chooses to count it themselves.
        if (showCountingOverlay) return [];
        return [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 5),
              child: CcSecondaryButton(
                label: 'Count it for me',
                icon: Icons.bolt,
                height: 42,
                fontSize: 13,
                onPressed: onCount,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 5, right: 12),
              child: CcPrimaryButton(
                label: "I'll count",
                icon: Icons.calculate,
                height: 42,
                fontSize: 14,
                onPressed: onManualCount,
              ),
            ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 180),
        child: CcPrimaryButton(
          label: label,
          icon: icon,
          onPressed: onPressed,
          height: 42,
          fontSize: 14,
        ),
      ),
    );
  }
}
