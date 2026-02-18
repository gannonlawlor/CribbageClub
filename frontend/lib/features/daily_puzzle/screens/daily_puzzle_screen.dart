import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../core/models/card.dart';
import '../../game/widgets/card_widget.dart';
import '../models/daily_puzzle.dart';
import '../state/puzzle_provider.dart';
import '../widgets/keep_rank_tile.dart';
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

String _formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

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
    final puzzle = state.puzzle;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.feltGradient),
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
    final state = ref.watch(dailyPuzzleProvider);
    final puzzle = state.puzzle!;
    final dateStr = _formatDate(puzzle.date);
    final canSubmit = state.selectedCards.length == 4;

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
                    const Text(
                      'Daily Puzzle',
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
              if (state.streak > 0) StreakBadge(streak: state.streak),
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
    final puzzle = state.puzzle!;
    final results = puzzle.results!;
    final dateStr = _formatDate(puzzle.date);
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
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Puzzle',
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
              if (state.streak > 0) StreakBadge(streak: state.streak),
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
                      : Colors.white24,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    isOptimalPick
                        ? 'Optimal!'
                        : 'Your pick: #$playerRank of 15',
                    style: TextStyle(
                      color: isOptimalPick ? Colors.green : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isOptimalPick && state.streak > 0)
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
                            '${state.streak} day streak!',
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
        const SizedBox(height: 8),
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
                child: OutlinedButton.icon(
                  onPressed: () => _shareResult(context, state, puzzle),
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
                  onPressed: () => context.go('/'),
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

  void _shareResult(
    BuildContext context,
    DailyPuzzleState state,
    DailyPuzzle puzzle,
  ) {
    final dateStr = _formatDate(puzzle.date);
    final rank = state.playerRank ?? 0;
    final streak = state.streak;
    final buffer = StringBuffer()
      ..writeln('Cribbage Club Daily Puzzle - $dateStr')
      ..writeln('Result: #$rank / 15')
      ..writeln(rank == 1 ? 'Optimal pick!' : '');
    if (streak > 0) {
      buffer.writeln('Streak: $streak day${streak > 1 ? 's' : ''}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Result copied to clipboard!')),
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
