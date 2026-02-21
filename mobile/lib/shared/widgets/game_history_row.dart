import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../core/models/game_state.dart';

class GameHistoryRow extends StatelessWidget {
  final GameState game;
  final String playerId;

  const GameHistoryRow({super.key, required this.game, required this.playerId});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final playerIndex = game.players.indexWhere((p) => p.id == playerId);
    final player = playerIndex >= 0 ? game.players[playerIndex] : game.players[0];
    final opponent = game.players[playerIndex >= 0 ? 1 - playerIndex : 1];
    final isWinner = player.score > opponent.score;

    return Material(
      color: colors.surfaceDim,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go('/game/${game.gameId}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                isWinner ? Icons.emoji_events : Icons.close,
                color: isWinner ? colors.accent : colors.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'vs ${opponent.name}',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${player.score} - ${opponent.score}',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isWinner ? 'Won' : 'Lost',
                style: TextStyle(
                  color: isWinner ? colors.accent : colors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.analytics,
                  size: 20,
                  color: colors.textDisabled,
                ),
                tooltip: 'Analyze',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => context.go('/analysis/${game.gameId}'),
              ),
              IconButton(
                icon: Icon(
                  Icons.replay,
                  size: 20,
                  color: colors.textDisabled,
                ),
                tooltip: 'Replay',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => context.go('/replay/${game.gameId}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
