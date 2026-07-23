import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_colors.dart';
import '../../../shared/widgets/cc_buttons.dart';
import '../../../shared/widgets/cc_dialog.dart';
import '../../../shared/widgets/cc_screen.dart';
import '../../game/widgets/count_block.dart';
import '../models/daily_puzzle.dart';
import '../state/practice_puzzle_provider.dart';
import '../state/puzzle_provider.dart';
import '../widgets/explain_dialog.dart';
import '../widgets/keep_rank_tile.dart';
import '../widgets/puzzle_hand.dart';

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
    final state = ref.watch(practicePuzzleProvider);
    final puzzle = state.puzzle!;
    final picked = state.selectedCards.length;

    return Column(
      children: [
        CcScreenHeader(
          title: 'Puzzle mode',
          subtitle: 'Puzzle ${state.puzzleNumber}',
          onBack: () => context.go('/'),
          actions: [
            if (state.totalSolved > 0)
              _StatsBadge(
                totalSolved: state.totalSolved,
                optimalCount: state.optimalCount,
              ),
          ],
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
                ref.read(practicePuzzleProvider.notifier).toggleCard(card),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: CcPrimaryButton(
            label: 'Submit',
            onPressed: picked == 4
                ? () => ref.read(practicePuzzleProvider.notifier).submitKeep()
                : null,
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
    final foundBest = playerRank == 1;

    return Column(
      children: [
        CcScreenHeader(
          title: 'Puzzle mode',
          subtitle: 'Puzzle ${state.puzzleNumber}',
          onBack: () => context.go('/'),
          actions: [
            if (state.totalSolved > 0)
              _StatsBadge(
                totalSolved: state.totalSolved,
                optimalCount: state.optimalCount,
              ),
          ],
        ),
        // Verdict — the result word is never coloured; the rank carries it.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(
            children: [
              Text(
                foundBest ? 'Best keep' : 'Rank $playerRank of 15',
                style: TextStyle(
                  color: foundBest ? colors.evOptimal : colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${state.optimalCount} of ${state.totalSolved} solved best · '
                '${puzzle.isDealer ? 'your crib' : "opponent's crib"}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 12.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: CcSectionCaption('All 15 keeps · average points'),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            children: [
              CcPanel(
                rows: [
                  for (final option in results)
                    KeepRankTile(
                      option: option,
                      isPlayerPick:
                          playerRank != null && option.rank == playerRank,
                      isOptimal: option.rank == 1,
                      isDealer: puzzle.isDealer,
                      onExplain: () => _showExplain(
                        context,
                        puzzle.hand,
                        option,
                        puzzle.isDealer,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: CcSecondaryButton(
                  label: 'Done',
                  height: 48,
                  onPressed: () => context.go('/'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CcPrimaryButton(
                  label: 'Next puzzle',
                  icon: Icons.arrow_forward,
                  height: 48,
                  fontSize: 15,
                  onPressed: () =>
                      ref.read(practicePuzzleProvider.notifier).nextPuzzle(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

class _StatsBadge extends StatelessWidget {
  final int totalSolved;
  final int optimalCount;

  const _StatsBadge({required this.totalSolved, required this.optimalCount});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colors.surfaceDim,
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
