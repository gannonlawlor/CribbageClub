import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme/app_colors.dart';
import '../../core/models/game_state.dart';
import '../../core/models/local_game_record.dart';

const _monthAbbr = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

/// One finished game, flattened out of whichever source it came from — the
/// on-device record or a server GameState.
class GameSummary {
  final String gameId;
  final bool isWin;
  final String opponentName;

  /// Second line: "Engine · Medium", "Rated", "Not uploaded".
  final String subtitle;
  final int playerScore;
  final int opponentScore;

  /// Groups the list under a day heading. Null games fall under "Earlier".
  final DateTime? completedAt;

  const GameSummary({
    required this.gameId,
    required this.isWin,
    required this.opponentName,
    required this.subtitle,
    required this.playerScore,
    required this.opponentScore,
    this.completedAt,
  });

  factory GameSummary.fromLocal(LocalGameRecord record, {String? subtitle}) {
    return GameSummary(
      gameId: record.gameId,
      isWin: record.isWin,
      opponentName: record.opponentName,
      subtitle: subtitle ?? 'Engine · ${record.difficulty}',
      playerScore: record.playerScore,
      opponentScore: record.opponentScore,
      completedAt: record.completedAt,
    );
  }

  factory GameSummary.fromGameState(GameState game, String playerId) {
    final index = game.players.indexWhere((p) => p.id == playerId);
    final me = index >= 0 ? game.players[index] : game.players.first;
    final them = game.players[index >= 0 ? 1 - index : 1];
    return GameSummary(
      gameId: game.gameId,
      isWin: me.score > them.score,
      opponentName: them.name,
      subtitle: them.id.startsWith('ai_') ? 'Engine' : 'Online',
      playerScore: me.score,
      opponentScore: them.score,
    );
  }
}

/// Finished games as one grouped card: day headings, hairline separators
/// between rows, W/L mark, opponent, and the score right-aligned in tabular
/// figures. Tapping a row opens its replay.
class GameHistoryList extends StatelessWidget {
  final List<GameSummary> games;

  /// Shown in place of the card when there is nothing to list.
  final String emptyMessage;

  const GameHistoryList({
    super.key,
    required this.games,
    this.emptyMessage = 'No games yet. Your first game starts your record.',
  });

  static String dayLabel(DateTime when) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(when.year, when.month, when.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return '${_monthAbbr[when.month - 1]} ${when.day}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (games.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          emptyMessage,
          style: TextStyle(color: colors.textTertiary, fontSize: 12.5),
        ),
      );
    }

    final children = <Widget>[];
    String? currentLabel;
    for (final game in games) {
      final label = game.completedAt == null
          ? null
          : dayLabel(game.completedAt!);
      if (label != null && label != currentLabel) {
        currentLabel = label;
        children.add(
          Container(
            width: double.infinity,
            color: colors.surfacePrimary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
              ),
            ),
          ),
        );
      } else if (children.isNotEmpty) {
        children.add(Divider(height: 1, color: colors.border));
      }
      children.add(GameHistoryRow(game: game));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Column(children: children),
      ),
    );
  }
}

class GameHistoryRow extends StatelessWidget {
  final GameSummary game;

  const GameHistoryRow({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final resultColor = game.isWin ? colors.success : colors.error;

    return InkWell(
      onTap: () => context.push('/replay/${game.gameId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: Text(
                  game.isWin ? 'W' : 'L',
                  style: TextStyle(
                    color: resultColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.opponentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    game.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${game.playerScore}–${game.opponentScore}',
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 13.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => context.push('/analysis/${game.gameId}'),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.insights,
                  size: 17,
                  color: colors.textDisabled,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
