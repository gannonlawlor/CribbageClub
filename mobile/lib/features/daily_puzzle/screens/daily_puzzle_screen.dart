import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/models/card.dart';
import '../../../shared/widgets/cc_buttons.dart';
import '../../../shared/widgets/cc_screen.dart';
import '../../game/widgets/count_block.dart';
import '../services/puzzle_generator.dart';
import '../state/puzzle_provider.dart';
import '../widgets/puzzle_summary.dart';
import '../widgets/puzzle_hand.dart';
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
    final colors = context.appColors;
    final state = ref.watch(dailyPuzzleProvider);
    final puzzleSet = state.puzzleSet;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.gameGradient),
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
                        PuzzlePhase.revealed ||
                        PuzzlePhase.summary => PuzzleSummary(
                          key: const ValueKey('summary'),
                          puzzleSet: puzzleSet,
                          playerScores: state.playerScores,
                          playerRanks: state.playerRanks,
                          allResults: state.allResults,
                          playerKeeps: state.playerKeeps,
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
  final List<List<PlayingCard>?> keeps;

  const _ProgressDots({
    required this.total,
    required this.current,
    required this.keeps,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
              color: keeps[i] != null ? colors.textSecondary : colors.divider,
              border: i == current
                  ? Border.all(color: colors.textPrimary, width: 1.5)
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _PlayingView extends ConsumerWidget {
  const _PlayingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyPuzzleProvider);
    final puzzle = state.currentPuzzle!;
    final picked = state.selectedCards.length;
    final puzzleNum = state.currentPuzzleIndex + 1;
    final total = PuzzleGenerator.puzzlesPerDay;

    return Column(
      children: [
        CcScreenHeader(
          title: 'Daily puzzle',
          subtitle: '${_formatDate(puzzle.date)} · $puzzleNum of $total',
          onBack: () => context.go('/'),
          actions: [if (state.streak > 0) StreakBadge(streak: state.streak)],
        ),
        const SizedBox(height: 4),
        _ProgressDots(
          total: total,
          current: state.currentPuzzleIndex,
          keeps: state.playerKeeps,
        ),
        const Spacer(),
        // The same block the game screen uses for the discard step, asking
        // the same question.
        CountBlock(
          label: puzzle.isDealer ? 'Your crib' : "Opponent's crib",
          headline: 'Keep four',
          instruction: '$picked of 4 selected',
          isMyTurn: picked == 4,
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: PuzzleHand(
            cards: puzzle.hand,
            selected: state.selectedCards,
            onTap: (card) =>
                ref.read(dailyPuzzleProvider.notifier).toggleCard(card),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: CcPrimaryButton(
            label: 'Submit',
            onPressed: picked == 4
                ? () => ref.read(dailyPuzzleProvider.notifier).submitKeep()
                : null,
          ),
        ),
      ],
    );
  }
}
