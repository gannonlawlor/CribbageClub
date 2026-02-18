import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../core/models/card.dart';
import '../../game/widgets/card_widget.dart';
import '../services/puzzle_generator.dart';
import '../state/puzzle_provider.dart';
import '../widgets/keep_rank_tile.dart';
import '../widgets/puzzle_summary.dart';
import '../widgets/streak_badge.dart';

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

String _formatDate(DateTime d) =>
    '${_months[d.month - 1]} ${d.day}, ${d.year}';

class DailyPuzzleScreen extends ConsumerStatefulWidget {
  const DailyPuzzleScreen({super.key});

  @override
  ConsumerState<DailyPuzzleScreen> createState() => _DailyPuzzleScreenState();
}

class _DailyPuzzleScreenState extends ConsumerState<DailyPuzzleScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dailyPuzzleProvider.notifier).loadPuzzle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyPuzzleProvider);
    final puzzleSet = state.puzzleSet;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.feltGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: puzzleSet == null
                  ? const Center(child: CircularProgressIndicator())
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: switch (state.phase) {
                        PuzzlePhase.playing => _PlayingView(
                            key: ValueKey('playing_${state.currentPuzzleIndex}'),
                          ),
                        PuzzlePhase.revealed => _RevealedView(
                            key: ValueKey('revealed_${state.currentPuzzleIndex}'),
                          ),
                        PuzzlePhase.summary => PuzzleSummary(
                            key: const ValueKey('summary'),
                            puzzleSet: puzzleSet,
                            playerScores: state.playerScores,
                            playerRanks: state.playerRanks,
                            allResults: state.allResults,
                            streak: state.streak,
                            onBackToHome: () => context.go('/'),
                          ),
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int total;
  final int current;
  final List<int?> ranks;

  const _ProgressDots({
    required this.total,
    required this.current,
    required this.ranks,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _dotColor(i),
              border: i == current
                  ? Border.all(color: Colors.white, width: 1.5)
                  : null,
            ),
          ),
        ],
      ],
    );
  }

  Color _dotColor(int index) {
    if (ranks[index] == null) {
      // Not yet played
      return Colors.white.withValues(alpha: 0.2);
    }
    if (ranks[index] == 1) return Colors.green;
    return AppTheme.goldAccent;
  }
}

class _PlayingView extends ConsumerWidget {
  const _PlayingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyPuzzleProvider);
    final puzzle = state.currentPuzzle!;
    final dateStr = _formatDate(puzzle.date);
    final canSubmit = state.selectedCards.length == 4;
    final puzzleNum = state.currentPuzzleIndex + 1;
    final total = PuzzleGenerator.puzzlesPerDay;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Daily Challenge',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$puzzleNum/$total',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ],
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
              if (state.streak > 0) StreakBadge(streak: state.streak),
            ],
          ),
        ),
        // Progress dots
        _ProgressDots(
          total: total,
          current: state.currentPuzzleIndex,
          ranks: state.playerRanks,
        ),
        // Running total if we have prior scores
        if (state.currentPuzzleIndex > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Running total: ${state.totalScore.toStringAsFixed(1)} avg pts',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
        const Spacer(),
        // Instruction
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'You are ${puzzle.isDealer ? 'the dealer' : 'not the dealer'}. '
            'Choose the best 4 cards to keep.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${state.selectedCards.length}/4 selected',
          style: TextStyle(
            color: canSubmit ? AppTheme.goldAccent : Colors.white38,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        // Cards — 2 rows of 3
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _CardGrid(
            cards: puzzle.hand,
            selectedCards: state.selectedCards,
            onCardTap: (card) {
              ref.read(dailyPuzzleProvider.notifier).toggleCard(card);
            },
          ),
        ),
        const Spacer(),
        // Submit button
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canSubmit
                  ? () => ref.read(dailyPuzzleProvider.notifier).submitKeep()
                  : null,
              child: const Text('Submit', style: TextStyle(fontSize: 18)),
            ),
          ),
        ),
      ],
    );
  }
}

class _RevealedView extends ConsumerWidget {
  const _RevealedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyPuzzleProvider);
    final puzzle = state.currentPuzzle!;
    final idx = state.currentPuzzleIndex;
    final results = state.allResults[idx]!;
    final dateStr = _formatDate(puzzle.date);
    final playerRank = state.playerRanks[idx];
    final isOptimalPick = playerRank == 1;
    final puzzleNum = idx + 1;
    final total = PuzzleGenerator.puzzlesPerDay;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Daily Challenge',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$puzzleNum/$total',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ],
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
              if (state.streak > 0) StreakBadge(streak: state.streak),
            ],
          ),
        ),
        // Progress dots
        _ProgressDots(
          total: total,
          current: idx,
          ranks: state.playerRanks,
        ),
        const SizedBox(height: 8),
        // Result banner
        if (playerRank != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isOptimalPick
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: isOptimalPick
                      ? Colors.green.withValues(alpha: 0.5)
                      : Colors.white24,
                ),
              ),
              child: Text(
                isOptimalPick
                    ? 'Optimal!'
                    : 'Your pick: #$playerRank of 15',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isOptimalPick ? Colors.green : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        // Dealer context
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            puzzle.isDealer
                ? 'Dealer (crib is yours)'
                : 'Non-dealer (crib is opponent\'s)',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Average points per hand across all possible cut cards.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final option = results[index];
              final isPlayerPick =
                  playerRank != null && option.rank == playerRank;
              return KeepRankTile(
                option: option,
                isPlayerPick: isPlayerPick,
                isOptimal: option.rank == 1,
              );
            },
          ),
        ),
        // Next / See Results button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                ref.read(dailyPuzzleProvider.notifier).nextPuzzle();
              },
              child: Text(
                state.isLastPuzzle ? 'See Results' : 'Next Puzzle',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardGrid extends StatelessWidget {
  final List<PlayingCard> cards;
  final Set<PlayingCard> selectedCards;
  final void Function(PlayingCard card) onCardTap;

  const _CardGrid({
    required this.cards,
    required this.selectedCards,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    // 2 rows of 3 cards
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 16) / 3; // 3 cards + gaps
        final cardHeight = cardWidth / AppTheme.cardAspectRatio;
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  CardWidget(
                    card: cards[i],
                    selected: selectedCards.contains(cards[i]),
                    onTap: () => onCardTap(cards[i]),
                    width: cardWidth,
                    height: cardHeight,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 3; i < 6; i++) ...[
                  if (i > 3) const SizedBox(width: 8),
                  CardWidget(
                    card: cards[i],
                    selected: selectedCards.contains(cards[i]),
                    onTap: () => onCardTap(cards[i]),
                    width: cardWidth,
                    height: cardHeight,
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}
