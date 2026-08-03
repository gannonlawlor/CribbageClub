import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/models/card.dart';
import '../../../core/services/achievement_service.dart';
import '../models/daily_puzzle.dart';
import '../services/puzzle_generator.dart';
import '../services/puzzle_persistence.dart';

enum PuzzlePhase { playing, revealed, summary }

class DailyPuzzleState {
  final DailyPuzzleSet? puzzleSet;
  final int currentPuzzleIndex;
  final Set<PlayingCard> selectedCards;
  final PuzzlePhase phase;
  final int streak;
  final bool completedToday;
  final List<int?> playerRanks;
  final List<double?> playerScores;
  final List<List<KeepOption>?> allResults;
  final List<List<PlayingCard>?> playerKeeps;

  const DailyPuzzleState({
    this.puzzleSet,
    this.currentPuzzleIndex = 0,
    this.selectedCards = const {},
    this.phase = PuzzlePhase.playing,
    this.streak = 0,
    this.completedToday = false,
    this.playerRanks = const [null, null, null, null, null],
    this.playerScores = const [null, null, null, null, null],
    this.allResults = const [null, null, null, null, null],
    this.playerKeeps = const [null, null, null, null, null],
  });

  DailyPuzzle? get currentPuzzle {
    if (puzzleSet == null) return null;
    if (currentPuzzleIndex >= puzzleSet!.puzzles.length) return null;
    return puzzleSet!.puzzles[currentPuzzleIndex];
  }

  bool get isLastPuzzle =>
      currentPuzzleIndex >= PuzzleGenerator.puzzlesPerDay - 1;

  double get totalScore =>
      playerScores.whereType<double>().fold(0.0, (a, b) => a + b);

  double get maxPossibleScore {
    var total = 0.0;
    for (final results in allResults) {
      if (results != null && results.isNotEmpty) {
        total += results.first.netScore; // rank 1 is first
      }
    }
    return total;
  }

  DailyPuzzleState copyWith({
    DailyPuzzleSet? puzzleSet,
    int? currentPuzzleIndex,
    Set<PlayingCard>? selectedCards,
    PuzzlePhase? phase,
    int? streak,
    bool? completedToday,
    List<int?>? playerRanks,
    List<double?>? playerScores,
    List<List<KeepOption>?>? allResults,
    List<List<PlayingCard>?>? playerKeeps,
  }) {
    return DailyPuzzleState(
      puzzleSet: puzzleSet ?? this.puzzleSet,
      currentPuzzleIndex: currentPuzzleIndex ?? this.currentPuzzleIndex,
      selectedCards: selectedCards ?? this.selectedCards,
      phase: phase ?? this.phase,
      streak: streak ?? this.streak,
      completedToday: completedToday ?? this.completedToday,
      playerRanks: playerRanks ?? this.playerRanks,
      playerScores: playerScores ?? this.playerScores,
      allResults: allResults ?? this.allResults,
      playerKeeps: playerKeeps ?? this.playerKeeps,
    );
  }
}

class DailyPuzzleNotifier extends StateNotifier<DailyPuzzleState> {
  final PuzzlePersistence _persistence;

  /// Called once per freshly solved puzzle with whether the keep was
  /// optimal (rank 1) — the achievement report. Null when nobody listens.
  final void Function(bool optimal)? _onSolved;

  DailyPuzzleNotifier(
    this._persistence, {
    void Function(bool optimal)? onSolved,
  }) : _onSolved = onSolved,
       super(const DailyPuzzleState());

  Future<void> loadPuzzle() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final puzzleSet = PuzzleGenerator.generateSet(today);
    final streak = await _persistence.getStreak();
    final progress = await _persistence.getProgress(today);

    final n = PuzzleGenerator.puzzlesPerDay;
    final ranks = List<int?>.from(progress.ranks);
    final scores = List<double?>.from(progress.scores);
    final allResults = List<List<KeepOption>?>.from(progress.allResults);
    final keeps = List<List<PlayingCard>?>.from(progress.keeps);

    final allComplete = progress.nextIndex >= n;

    if (allComplete) {
      state = DailyPuzzleState(
        puzzleSet: puzzleSet,
        currentPuzzleIndex: n - 1,
        streak: streak,
        completedToday: true,
        phase: PuzzlePhase.summary,
        playerRanks: ranks,
        playerScores: scores,
        allResults: allResults,
        playerKeeps: keeps,
      );
    } else {
      state = DailyPuzzleState(
        puzzleSet: puzzleSet,
        currentPuzzleIndex: progress.nextIndex,
        streak: streak,
        completedToday: false,
        phase: PuzzlePhase.playing,
        playerRanks: ranks,
        playerScores: scores,
        allResults: allResults,
        playerKeeps: keeps,
      );
    }

    // Re-run analysis for any puzzles that have keeps but no results
    for (var i = 0; i < n; i++) {
      if (keeps[i] != null && allResults[i] == null) {
        _runAnalysisInBackground(puzzleSet.puzzles[i], keeps[i]!, i, today);
      }
    }
  }

  /// Drops the current picks — used when the puzzle switches between asking
  /// for the keep and asking for the throw, so a half-made choice under the
  /// old question can't be submitted under the new one.
  void clearSelection() {
    if (state.selectedCards.isEmpty) return;
    state = state.copyWith(selectedCards: {});
  }

  /// [limit] is how many cards the puzzle is asking for — four when picking
  /// the keep, two when picking the throw.
  void toggleCard(PlayingCard card, {int limit = 4}) {
    if (state.phase != PuzzlePhase.playing) return;
    final selected = Set<PlayingCard>.from(state.selectedCards);
    if (selected.contains(card)) {
      selected.remove(card);
    } else if (selected.length < limit) {
      selected.add(card);
    }
    state = state.copyWith(selectedCards: selected);
  }

  /// Submits the current keep selection.
  /// Saves the keep immediately and advances to the next puzzle.
  /// Analysis runs in the background and updates state when complete.
  /// [pickedDiscards] flips what the taps meant: the keep is then the four
  /// cards the player left alone.
  Future<void> submitKeep({bool pickedDiscards = false}) async {
    final puzzle = state.currentPuzzle;
    final needed = pickedDiscards ? 2 : 4;
    if (state.selectedCards.length != needed || puzzle == null) return;

    final keep = pickedDiscards
        ? puzzle.hand.where((c) => !state.selectedCards.contains(c)).toList()
        : state.selectedCards.toList();
    final idx = state.currentPuzzleIndex;
    final date = puzzle.date;

    // Save keep immediately
    await _persistence.savePlayerKeep(date, idx, keep);

    // Update state — advance immediately with no analysis feedback
    final keeps = List<List<PlayingCard>?>.from(state.playerKeeps);
    keeps[idx] = keep;

    if (state.isLastPuzzle) {
      state = state.copyWith(
        phase: PuzzlePhase.summary,
        completedToday: true,
        selectedCards: {},
        playerKeeps: keeps,
      );
    } else {
      state = state.copyWith(
        currentPuzzleIndex: state.currentPuzzleIndex + 1,
        selectedCards: {},
        phase: PuzzlePhase.playing,
        playerKeeps: keeps,
      );
    }

    // Run analysis in background (after UI has advanced)
    _runAnalysisInBackground(puzzle, keep, idx, date, report: true);
  }

  /// [report] marks a fresh solve; the restore path re-runs interrupted
  /// analysis without re-reporting it for achievements.
  void _runAnalysisInBackground(
    DailyPuzzle puzzle,
    List<PlayingCard> keep,
    int idx,
    DateTime date, {
    bool report = false,
  }) {
    Future(() async {
      final results = PuzzleGenerator.evaluateAllKeeps(
        puzzle.hand,
        puzzle.isDealer,
      );

      // Find player's rank and score
      final keepSet = keep.toSet();
      int? playerRank;
      double? playerScore;
      for (final option in results) {
        if (option.keep.toSet().containsAll(keepSet) &&
            keepSet.containsAll(option.keep)) {
          playerRank = option.rank;
          playerScore = option.netScore;
          break;
        }
      }

      if (report) _onSolved?.call(playerRank == 1);

      // Persist analysis results
      await _persistence.savePuzzleResult(
        date,
        idx,
        playerRank ?? 0,
        playerScore ?? 0,
        results,
      );

      // Update state with results
      if (!mounted) return;
      final ranks = List<int?>.from(state.playerRanks);
      final scores = List<double?>.from(state.playerScores);
      final allResults = List<List<KeepOption>?>.from(state.allResults);
      ranks[idx] = playerRank;
      scores[idx] = playerScore;
      allResults[idx] = results;

      state = state.copyWith(
        playerRanks: ranks,
        playerScores: scores,
        allResults: allResults,
      );

      // If all puzzles have results and we're on summary, finalize streak
      if (allResults.every((r) => r != null) &&
          state.phase == PuzzlePhase.summary) {
        await _persistence.finalizeDayResults(date);
        final streak = await _persistence.getStreak();
        if (mounted) {
          state = state.copyWith(streak: streak);
        }
      }
    });
  }
}

final puzzlePersistenceProvider = Provider<PuzzlePersistence>((ref) {
  return PuzzlePersistence();
});

final dailyPuzzleProvider =
    StateNotifierProvider<DailyPuzzleNotifier, DailyPuzzleState>((ref) {
      final persistence = ref.read(puzzlePersistenceProvider);
      return DailyPuzzleNotifier(
        persistence,
        onSolved: (optimal) async {
          // The puzzle runs on-device; the server only hears about solves
          // for achievement credit. Best-effort.
          if (!ref.read(authProvider).isLoggedIn) return;
          try {
            await ref.read(restClientProvider).reportPuzzleSolved(optimal);
            await ref.read(achievementSyncServiceProvider).sync();
          } catch (_) {
            // Next sync catches up.
          }
        },
      );
    });

/// Lightweight status provider for the home screen Daily Challenge button.
/// autoDispose ensures it re-fetches each time the home screen is shown.
final dailyPuzzleStatusProvider =
    FutureProvider.autoDispose<
      ({bool completedToday, int streak, int completedCount})
    >((ref) async {
      final persistence = ref.read(puzzlePersistenceProvider);
      final completedCount = await persistence.getCompletedCount();
      final streak = await persistence.getStreak();
      final completedToday = completedCount >= PuzzleGenerator.puzzlesPerDay;
      return (
        completedToday: completedToday,
        streak: streak,
        completedCount: completedCount,
      );
    });
