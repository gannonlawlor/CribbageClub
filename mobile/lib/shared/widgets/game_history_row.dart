import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme/app_colors.dart';
import '../../core/models/local_game_record.dart';
import '../../core/models/server_history_game.dart';

/// "+12" / "−8" for a rating change, rounded to whole points.
String formatRatingDelta(double delta) {
  final rounded = delta.round();
  return rounded >= 0 ? '+$rounded' : '$rounded';
}

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

  /// Server id of the opponent when they're a real account — tapping the name
  /// opens their public profile. Null for engine opponents and local games.
  final String? opponentId;

  /// Second line: "Engine · Medium", "Rated", "Not uploaded".
  final String subtitle;
  final int playerScore;
  final int opponentScore;

  /// How much this game moved the viewer's rating; null when unrated/unknown.
  final double? ratingDelta;

  /// Groups the list under a day heading. Null games fall under "Earlier".
  final DateTime? completedAt;

  const GameSummary({
    required this.gameId,
    required this.isWin,
    required this.opponentName,
    required this.subtitle,
    required this.playerScore,
    required this.opponentScore,
    this.opponentId,
    this.ratingDelta,
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

  factory GameSummary.fromServer(ServerHistoryGame entry, String playerId) {
    final game = entry.gameState;
    final index = game.players.indexWhere((p) => p.id == playerId);
    final me = index >= 0 ? game.players[index] : game.players.first;
    final them = game.players[index >= 0 ? 1 - index : 1];
    final isEngine = them.id.startsWith('ai_');
    final oppRating = entry.opponentRating?.round();
    return GameSummary(
      gameId: game.gameId,
      isWin: me.score > them.score,
      opponentName: them.name,
      opponentId: isEngine ? null : them.id,
      subtitle: isEngine
          ? 'Engine'
          : oppRating != null
          ? 'Online · $oppRating'
          : 'Online',
      playerScore: me.score,
      opponentScore: them.score,
      ratingDelta: entry.myRatingDelta,
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
                  // A real opponent's name links to their public profile;
                  // engine opponents have none, so their name is inert.
                  GestureDetector(
                    onTap: game.opponentId == null
                        ? null
                        : () => context.push('/profile/${game.opponentId}'),
                    child: Text(
                      game.opponentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        decoration: game.opponentId == null
                            ? null
                            : TextDecoration.underline,
                        decorationColor: colors.textDisabled,
                      ),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${game.playerScore}–${game.opponentScore}',
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 13.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (game.ratingDelta != null)
                  Text(
                    formatRatingDelta(game.ratingDelta!),
                    style: TextStyle(
                      color: game.ratingDelta! >= 0
                          ? colors.success
                          : colors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
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
