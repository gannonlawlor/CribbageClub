import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/constants.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/models/card.dart';
import '../../game/widgets/card_widget.dart';
import '../state/practice_puzzle_provider.dart';
import '../state/puzzle_provider.dart';
import '../widgets/keep_rank_tile.dart';

class PracticePuzzleScreen extends ConsumerStatefulWidget {
  const PracticePuzzleScreen({super.key});

  @override
  ConsumerState<PracticePuzzleScreen> createState() =>
      _PracticePuzzleScreenState();
}

class _PracticePuzzleScreenState extends ConsumerState<PracticePuzzleScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final state = ref.read(practicePuzzleProvider);
      if (state.puzzle == null || state.phase == PuzzlePhase.revealed) {
        ref.read(practicePuzzleProvider.notifier).loadPuzzle();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final state = ref.watch(practicePuzzleProvider);
    final puzzle = state.puzzle;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.gameGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: puzzle == null
                  ? const Center(child: CircularProgressIndicator())
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: state.phase == PuzzlePhase.playing
                          ? _PlayingView(key: const ValueKey('playing'))
                          : _RevealedView(key: const ValueKey('revealed')),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayingView extends ConsumerWidget {
  const _PlayingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final state = ref.watch(practicePuzzleProvider);
    final puzzle = state.puzzle!;
    final canSubmit = state.selectedCards.length == 4;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                onPressed: () => context.go('/'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice Puzzle',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Puzzle #${state.puzzleNumber}',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.totalSolved > 0)
                _StatsBadge(
                  totalSolved: state.totalSolved,
                  optimalCount: state.optimalCount,
                ),
            ],
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
            style: TextStyle(color: colors.textSecondary, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${state.selectedCards.length}/4 selected',
          style: TextStyle(
            color: canSubmit ? colors.accent : colors.textDisabled,
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
              ref.read(practicePuzzleProvider.notifier).toggleCard(card);
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
                  ? () =>
                      ref.read(practicePuzzleProvider.notifier).submitKeep()
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
    final colors = context.appColors;
    final state = ref.watch(practicePuzzleProvider);
    final puzzle = state.puzzle!;
    final results = puzzle.results!;
    final playerRank = state.playerRank;
    final isOptimalPick = playerRank == 1;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                onPressed: () => context.go('/'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice Puzzle',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Puzzle #${state.puzzleNumber}',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.totalSolved > 0)
                _StatsBadge(
                  totalSolved: state.totalSolved,
                  optimalCount: state.optimalCount,
                ),
            ],
          ),
        ),
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
                      : colors.divider,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    isOptimalPick
                        ? 'Optimal!'
                        : 'Your pick: #$playerRank of 15',
                    style: TextStyle(
                      color: isOptimalPick ? Colors.green : colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${state.optimalCount}/${state.totalSolved} optimal',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
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
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Average points per hand across all possible cut cards.',
            style: TextStyle(color: colors.textDisabled, fontSize: 12),
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
        // Bottom buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.textDisabled),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Back to Home'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(practicePuzzleProvider.notifier).nextPuzzle();
                  },
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Next Puzzle'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsBadge extends StatelessWidget {
  final int totalSolved;
  final int optimalCount;

  const _StatsBadge({
    required this.totalSolved,
    required this.optimalCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: colors.divider),
      ),
      child: Text(
        '$optimalCount/$totalSolved',
        style: TextStyle(
          color: colors.accent,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
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
        final cardHeight = cardWidth / AppConstants.cardAspectRatio;
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
