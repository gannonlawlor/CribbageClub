import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/widgets/card_widget.dart';
import '../models/daily_puzzle.dart';
import '../services/puzzle_generator.dart';
import 'keep_rank_tile.dart';
import 'streak_badge.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

class PuzzleSummary extends StatefulWidget {
  final DailyPuzzleSet puzzleSet;
  final List<double?> playerScores;
  final List<int?> playerRanks;
  final List<List<KeepOption>?> allResults;
  final int streak;
  final VoidCallback onBackToHome;

  const PuzzleSummary({
    super.key,
    required this.puzzleSet,
    required this.playerScores,
    required this.playerRanks,
    required this.allResults,
    required this.streak,
    required this.onBackToHome,
  });

  @override
  State<PuzzleSummary> createState() => _PuzzleSummaryState();
}

class _PuzzleSummaryState extends State<PuzzleSummary> {
  int? _expandedIndex;

  double get _totalScore => widget.playerScores
      .whereType<double>()
      .fold(0.0, (a, b) => a + b);

  double get _maxScore {
    var total = 0.0;
    for (final results in widget.allResults) {
      if (results != null && results.isNotEmpty) {
        total += results.first.netScore;
      }
    }
    return total;
  }

  bool get _allOptimal => widget.playerRanks.every((r) => r == 1);

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(widget.puzzleSet.date);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: widget.onBackToHome,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Challenge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.streak > 0) StreakBadge(streak: widget.streak),
            ],
          ),
        ),
        // Total score banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _allOptimal
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: _allOptimal
                    ? Colors.green.withValues(alpha: 0.5)
                    : Colors.white24,
              ),
            ),
            child: Column(
              children: [
                if (_allOptimal)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Perfect!',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _totalScore.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (_maxScore > 0) ...[
                      Text(
                        '/ ${_maxScore.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    const Text(
                      'avg pts',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
                if (_allOptimal && widget.streak > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.streak} day streak!',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Per-puzzle rows
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: PuzzleGenerator.puzzlesPerDay,
            itemBuilder: (context, index) => _PuzzleRow(
              puzzle: widget.puzzleSet.puzzles[index],
              rank: widget.playerRanks[index],
              score: widget.playerScores[index],
              maxScore: widget.allResults[index]?.first.netScore,
              results: widget.allResults[index],
              playerRank: widget.playerRanks[index],
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareResults(context),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onBackToHome,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Back to Home'),
                  ),
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
      final emoji = rank == 1 ? '⭐' : '  ';
      buffer.writeln(
        '$emoji Puzzle ${i + 1}: #${rank ?? '?'} / 15',
      );
    }
    if (_allOptimal) {
      buffer.writeln('Perfect score!');
    }
    if (widget.streak > 0) {
      buffer.writeln(
        'Streak: ${widget.streak} day${widget.streak > 1 ? 's' : ''}',
      );
    }
    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Results copied to clipboard!')),
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
  final bool isExpanded;
  final VoidCallback onTap;

  const _PuzzleRow({
    required this.puzzle,
    required this.rank,
    required this.score,
    required this.maxScore,
    required this.results,
    required this.playerRank,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOptimal = rank == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          // Collapsed row
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isOptimal
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(8))
                    : BorderRadius.circular(8),
                border: isOptimal
                    ? Border.all(
                        color: Colors.green.withValues(alpha: 0.4),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Puzzle number
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${puzzle.index + 1}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Mini card icons for kept cards (find player's kept cards)
                  if (results != null && playerRank != null)
                    ..._buildKeptCards()
                  else
                    const SizedBox(width: 80),
                  const Spacer(),
                  // Score
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' / ${maxScore?.toStringAsFixed(1) ?? '-'}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Rank badge
                  _RankBadge(rank: rank),
                  const SizedBox(width: 4),
                  // Expand indicator
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white38,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Expanded: full keep list
          if (isExpanded && results != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
                    child: Text(
                      puzzle.isDealer
                          ? 'Dealer (crib is yours)'
                          : 'Non-dealer (crib is opponent\'s)',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  for (final option in results!)
                    KeepRankTile(
                      option: option,
                      isPlayerPick: option.rank == playerRank,
                      isOptimal: option.rank == 1,
                    ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildKeptCards() {
    // Find the player's kept cards from results
    final playerOption = results!.where((o) => o.rank == playerRank).firstOrNull;
    if (playerOption == null) return [const SizedBox(width: 80)];
    return playerOption.keep
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

class _RankBadge extends StatelessWidget {
  final int? rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
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
            ? Colors.green.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.1),
        border: Border.all(
          color: isOptimal
              ? Colors.green.withValues(alpha: 0.6)
              : Colors.white24,
        ),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          color: isOptimal ? Colors.green : Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
