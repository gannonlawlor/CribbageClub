import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/models/card.dart';
import '../../../shared/widgets/cc_buttons.dart';
import '../../../shared/widgets/cc_screen.dart';
import '../../game/widgets/card_widget.dart';
import '../models/daily_puzzle.dart';
import '../../../shared/widgets/cc_dialog.dart';
import '../services/puzzle_generator.dart';
import 'explain_dialog.dart';
import 'keep_rank_tile.dart';
import 'puzzle_prompt.dart';
import 'streak_badge.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

class PuzzleSummary extends StatefulWidget {
  final DailyPuzzleSet puzzleSet;
  final List<double?> playerScores;
  final List<int?> playerRanks;
  final List<List<KeepOption>?> allResults;
  final List<List<PlayingCard>?> playerKeeps;
  final int streak;
  final VoidCallback onBackToHome;

  const PuzzleSummary({
    super.key,
    required this.puzzleSet,
    required this.playerScores,
    required this.playerRanks,
    required this.allResults,
    required this.playerKeeps,
    required this.streak,
    required this.onBackToHome,
  });

  @override
  State<PuzzleSummary> createState() => _PuzzleSummaryState();
}

class _PuzzleSummaryState extends State<PuzzleSummary> {
  int? _expandedIndex;

  bool get _allResultsReady => widget.allResults.every((r) => r != null);

  double get _totalScore =>
      widget.playerScores.whereType<double>().fold(0.0, (a, b) => a + b);

  double get _maxScore {
    var total = 0.0;
    for (final results in widget.allResults) {
      if (results != null && results.isNotEmpty) {
        total += results.first.netScore;
      }
    }
    return total;
  }

  bool get _allOptimal =>
      _allResultsReady && widget.playerRanks.every((r) => r == 1);

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(widget.puzzleSet.date);

    return Column(
      children: [
        CcScreenHeader(
          title: 'Daily puzzle',
          subtitle: dateStr,
          onBack: widget.onBackToHome,
          actions: [if (widget.streak > 0) StreakBadge(streak: widget.streak)],
        ),
        // Total score banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _allResultsReady
              ? _ScoreBanner(
                  totalScore: _totalScore,
                  maxScore: _maxScore,
                  allOptimal: _allOptimal,
                  streak: widget.streak,
                )
              : _LoadingBanner(),
        ),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 0, 22, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: CcSectionCaption('Your five'),
          ),
        ),
        // Per-puzzle rows
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            itemCount: PuzzleGenerator.puzzlesPerDay,
            itemBuilder: (context, index) => _PuzzleRow(
              puzzle: widget.puzzleSet.puzzles[index],
              rank: widget.playerRanks[index],
              score: widget.playerScores[index],
              maxScore: widget.allResults[index]?.first.netScore,
              results: widget.allResults[index],
              playerRank: widget.playerRanks[index],
              playerKeep: widget.playerKeeps[index],
              isExpanded: _expandedIndex == index,
              onTap: () {
                setState(() {
                  _expandedIndex = _expandedIndex == index ? null : index;
                });
              },
            ),
          ),
        ),
        // Bottom buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: CcSecondaryButton(
                  label: 'Share',
                  icon: Icons.ios_share,
                  height: 48,
                  onPressed: _allResultsReady
                      ? () => _shareResults(context)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CcPrimaryButton(
                  label: 'Done',
                  height: 48,
                  fontSize: 15,
                  onPressed: widget.onBackToHome,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _shareResults(BuildContext context) {
    final dateStr = _formatDate(widget.puzzleSet.date);
    final buffer = StringBuffer()
      ..writeln('Cribbage Club Daily Challenge - $dateStr')
      ..writeln(
        'Score: ${_totalScore.toStringAsFixed(1)} / ${_maxScore.toStringAsFixed(1)} avg pts',
      );
    for (var i = 0; i < PuzzleGenerator.puzzlesPerDay; i++) {
      final rank = widget.playerRanks[i];
      final emoji = rank == 1 ? '\u2B50' : '  ';
      buffer.writeln('$emoji Puzzle ${i + 1}: #${rank ?? '?'} / 15');
    }
    if (_allOptimal) {
      buffer.writeln('Perfect score');
    }
    if (widget.streak > 0) {
      buffer.writeln(
        'Streak: ${widget.streak} day${widget.streak > 1 ? 's' : ''}',
      );
    }
    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Results copied to clipboard')),
    );
  }
}

class _ScoreBanner extends StatelessWidget {
  final double totalScore;
  final double maxScore;
  final bool allOptimal;
  final int streak;

  const _ScoreBanner({
    required this.totalScore,
    required this.maxScore,
    required this.allOptimal,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // Stat card (design language §4): caption label over a large tabular
    // value, with what was on the table beside it.
    return CcPanel(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CcSectionCaption('Average points'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      totalScore.toStringAsFixed(1),
                      style: TextStyle(
                        color: allOptimal
                            ? colors.evOptimal
                            : colors.textPrimary,
                        fontSize: 28,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (maxScore > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        'of ${maxScore.toStringAsFixed(1)} on the table',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 12.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (allOptimal)
            const Padding(
              padding: EdgeInsets.only(left: 10, bottom: 2),
              child: CcChip(label: 'ALL BEST'),
            )
          else if (streak > 0)
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 2),
              child: Text(
                'streak $streak',
                style: TextStyle(
                  color: colors.streak,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.surfaceDim,
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.textDisabled,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Analyzing...',
            style: TextStyle(color: colors.textTertiary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _PuzzleRow extends StatelessWidget {
  final DailyPuzzle puzzle;
  final int? rank;
  final double? score;
  final double? maxScore;
  final List<KeepOption>? results;
  final int? playerRank;
  final List<PlayingCard>? playerKeep;
  final bool isExpanded;
  final VoidCallback onTap;

  const _PuzzleRow({
    required this.puzzle,
    required this.rank,
    required this.score,
    required this.maxScore,
    required this.results,
    required this.playerRank,
    required this.playerKeep,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isOptimal = rank == 1;
    final hasResults = results != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CcPanel(
        child: Column(
          children: [
            // Collapsed row
            GestureDetector(
              onTap: hasResults ? onTap : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: hasResults && isOptimal
                      ? colors.evOptimal.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: isExpanded
                      ? const BorderRadius.vertical(top: Radius.circular(10))
                      : BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // Puzzle number
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${puzzle.index + 1}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Mini card icons for kept cards
                    if (playerKeep != null)
                      ..._buildKeptCards()
                    else
                      const SizedBox(width: 80),
                    const Spacer(),
                    // Score or loading
                    if (hasResults) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                score?.toStringAsFixed(1) ?? '-',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              Text(
                                ' / ${maxScore?.toStringAsFixed(1) ?? '-'}',
                                style: TextStyle(
                                  color: colors.textTertiary,
                                  fontSize: 12,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      _RankBadge(rank: rank),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: colors.textDisabled,
                        size: 20,
                      ),
                    ] else ...[
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.textDisabled,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
              ),
            ),
            // Expanded: full keep list
            if (isExpanded && results != null)
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CribBadge(isDealer: puzzle.isDealer),
                      ),
                    ),
                    for (final option in results!)
                      KeepRankTile(
                        option: option,
                        isPlayerPick: option.rank == playerRank,
                        isOptimal: option.rank == 1,
                        isDealer: puzzle.isDealer,
                        onExplain: () => _showExplain(
                          context,
                          puzzle.hand,
                          option,
                          puzzle.isDealer,
                        ),
                      ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildKeptCards() {
    return playerKeep!
        .map(
          (card) => Padding(
            padding: const EdgeInsets.only(right: 2),
            child: CardWidget(
              card: card,
              width: 22,
              height: 31,
              enabled: false,
            ),
          ),
        )
        .toList();
  }
}

void _showExplain(
  BuildContext context,
  List<dynamic> hand,
  KeepOption option,
  bool isDealer,
) {
  showCcDialog(
    context: context,
    builder: (_) => ExplainDialog(
      rank: option.rank,
      keep: option.keep,
      discard: option.discard,
      hand: hand,
      isDealer: isDealer,
    ),
  );
}

class _RankBadge extends StatelessWidget {
  final int? rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (rank == null) {
      return const SizedBox(width: 28);
    }

    final isOptimal = rank == 1;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOptimal
            ? colors.evOptimal.withValues(alpha: 0.3)
            : colors.surfaceDim,
        border: Border.all(
          color: isOptimal
              ? colors.evOptimal.withValues(alpha: 0.6)
              : colors.divider,
        ),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          color: isOptimal ? colors.success : colors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
