import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/card.dart';
import '../../../core/models/game_analysis.dart';
import '../../../core/models/puzzle.dart';
import '../../game/widgets/card_widget.dart';

final _dailyPuzzleProvider =
    FutureProvider.autoDispose<PuzzleResponse>((ref) async {
  final restClient = ref.read(restClientProvider);
  return restClient.getDailyPuzzle();
});

class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({super.key});

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  final Set<int> _selected = {};
  PuzzleSolveResponse? _result;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final puzzleAsync = ref.watch(_dailyPuzzleProvider);

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Puzzle')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.white38),
              const SizedBox(height: 16),
              const Text('Log in to play the daily puzzle',
                  style: TextStyle(color: Colors.white54, fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Puzzle')),
      body: puzzleAsync.when(
        data: (puzzle) => _buildPuzzle(context, puzzle),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Failed to load puzzle: $error',
              style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }

  Widget _buildPuzzle(BuildContext context, PuzzleResponse puzzle) {
    if (puzzle.alreadySolved && _result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 48, color: Colors.greenAccent),
            const SizedBox(height: 16),
            const Text("You've already solved today's puzzle!",
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Come back tomorrow for a new one.',
                style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Select 2 cards to discard${puzzle.isDealer ? " (you're the dealer)" : " (you're the pone)"}',
                  style:
                      const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  puzzle.isDealer
                      ? 'Maximize hand + crib expected value'
                      : 'Maximize hand - crib expected value',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Hand display
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(puzzle.hand.length, (i) {
              final card = puzzle.hand[i];
              final isSelected = _selected.contains(i);
              return GestureDetector(
                onTap: _result != null
                    ? null
                    : () {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(i);
                          } else if (_selected.length < 2) {
                            _selected.add(i);
                          }
                        });
                      },
                child: Opacity(
                  opacity: _result != null && isSelected ? 0.5 : 1.0,
                  child: CardWidget(
                    card: card,
                    selected: isSelected,
                    width: 60,
                    height: 84,
                    enabled: _result == null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Submit button
          if (_result == null)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed:
                    _selected.length == 2 && !_submitting ? _submit : null,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_selected.length == 2
                        ? 'Submit Discard'
                        : 'Select 2 cards'),
              ),
            ),

          // Results
          if (_result != null) ...[
            const SizedBox(height: 16),
            _PuzzleResult(result: _result!, hand: puzzle.hand),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final puzzle = ref.read(_dailyPuzzleProvider).valueOrNull;
    if (puzzle == null) return;

    final chosenDiscard =
        _selected.map((i) => puzzle.hand[i]).toList();

    setState(() => _submitting = true);
    try {
      final restClient = ref.read(restClientProvider);
      final result =
          await restClient.solvePuzzle(puzzle.id, chosenDiscard);
      setState(() {
        _result = result;
        _submitting = false;
      });
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }
}

class _PuzzleResult extends StatelessWidget {
  final PuzzleSolveResponse result;
  final List<PlayingCard> hand;

  const _PuzzleResult({required this.result, required this.hand});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result.isOptimal
              ? Colors.greenAccent.withValues(alpha: 0.5)
              : Colors.orangeAccent.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                result.isOptimal ? Icons.check_circle : Icons.info_outline,
                color: result.isOptimal ? Colors.greenAccent : Colors.orangeAccent,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                result.isOptimal ? 'Optimal!' : 'Not quite...',
                style: TextStyle(
                  color: result.isOptimal
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!result.isOptimal) ...[
            const SizedBox(height: 8),
            Text(
              'EV difference: ${result.evDifference.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 12),

          // Your discard vs optimal
          Row(
            children: [
              Expanded(
                child: _ComparisonColumn(
                  label: 'Your Discard',
                  option: result.yourOption,
                ),
              ),
              if (!result.isOptimal) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _ComparisonColumn(
                    label: 'Optimal',
                    option: result.optimalOption,
                    isOptimal: true,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // All options ranked
          const Text('All Options',
              style: TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...result.allOptions.asMap().entries.map((entry) {
            final i = entry.key;
            final opt = entry.value;
            final isYours = opt.discard.toSet().difference(result.yourOption.discard.toSet()).isEmpty &&
                result.yourOption.discard.toSet().difference(opt.discard.toSet()).isEmpty;
            final isOpt = i == 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('#${i + 1}',
                        style: TextStyle(
                          color: isOpt ? Colors.greenAccent : Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  ...opt.discard.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: CardWidget(
                          card: c,
                          width: 24,
                          height: 34,
                          enabled: false,
                        ),
                      )),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'EV ${opt.expectedCombinedValue.toStringAsFixed(2)}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  if (isYours)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('You',
                          style:
                              TextStyle(color: Colors.blueAccent, fontSize: 10)),
                    ),
                  if (isOpt)
                    Container(
                      margin: const EdgeInsets.only(left: 3),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Best',
                          style: TextStyle(
                              color: Colors.greenAccent, fontSize: 10)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ComparisonColumn extends StatelessWidget {
  final String label;
  final DiscardOption option;
  final bool isOptimal;

  const _ComparisonColumn({
    required this.label,
    required this.option,
    this.isOptimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isOptimal
            ? Colors.greenAccent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                color: isOptimal ? Colors.greenAccent : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 4),
          Row(
            children: option.discard
                .map((c) => Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: CardWidget(
                        card: c,
                        width: 32,
                        height: 45,
                        enabled: false,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          Text('EV: ${option.expectedCombinedValue.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
