import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/card.dart';
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
    );
  }
}

class DailyPuzzleNotifier extends StateNotifier<DailyPuzzleState> {
  final PuzzlePersistence _persistence;

  DailyPuzzleNotifier(this._persistence) : super(const DailyPuzzleState());

  Future<void> loadPuzzle() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final puzzleSet = PuzzleGenerator.generateSet(today);
    final streak = await _persistence.getStreak();
    final progress = await _persistence.getProgress(today);

    final n = PuzzleGenerator.puzzlesPerDay;
    final ranks = List<int?>.from(progress.ranks);
    final scores = List<double?>.from(progress.scores);
    final allResults = List<List<KeepOption>?>.filled(n, null);

    final allComplete = progress.nextIndex >= n;

    // If partially or fully complete, compute results for completed puzzles
    for (var i = 0; i < progress.nextIndex && i < n; i++) {
      final puzzle = puzzleSet.puzzles[i];
      final results = PuzzleGenerator.evaluateAllKeeps(
        puzzle.hand,
        puzzle.isDealer,
      );
      puzzle.results = results;
      allResults[i] = results;
    }

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
      );
    }
  }

  void toggleCard(PlayingCard card) {
    if (state.phase != PuzzlePhase.playing) return;
    final selected = Set<PlayingCard>.from(state.selectedCards);
    if (selected.contains(card)) {
      selected.remove(card);
    } else if (selected.length < 4) {
      selected.add(card);
    }
    state = state.copyWith(selectedCards: selected);
  }

  Future<void> submitKeep() async {
    final puzzle = state.currentPuzzle;
    if (state.selectedCards.length != 4 || puzzle == null) return;

    final results = PuzzleGenerator.evaluateAllKeeps(
      puzzle.hand,
      puzzle.isDealer,
    );
    puzzle.results = results;

    // Find player's rank and score
    final playerKeep = state.selectedCards;
    int? playerRank;
    double? playerScore;
    for (final option in results) {
      if (option.keep.toSet().containsAll(playerKeep) &&
          playerKeep.containsAll(option.keep)) {
        playerRank = option.rank;
        playerScore = option.netScore;
        break;
      }
    }

    final idx = state.currentPuzzleIndex;
    final date = puzzle.date;

    // Persist this puzzle's result
    await _persistence.savePuzzleResult(
      date,
      idx,
      playerRank ?? 0,
      playerScore ?? 0,
    );

    final ranks = List<int?>.from(state.playerRanks);
    final scores = List<double?>.from(state.playerScores);
    final allResults = List<List<KeepOption>?>.from(state.allResults);
    ranks[idx] = playerRank;
    scores[idx] = playerScore;
    allResults[idx] = results;

    state = state.copyWith(
      phase: PuzzlePhase.revealed,
      playerRanks: ranks,
      playerScores: scores,
      allResults: allResults,
    );
  }

  Future<void> nextPuzzle() async {
    if (state.isLastPuzzle) {
      // All done — finalize streak and show summary
      final date = state.puzzleSet!.date;
      await _persistence.finalizeDayResults(date);
      final streak = await _persistence.getStreak();
      state = state.copyWith(
        phase: PuzzlePhase.summary,
        streak: streak,
        completedToday: true,
      );
    } else {
      state = state.copyWith(
        currentPuzzleIndex: state.currentPuzzleIndex + 1,
        selectedCards: {},
        phase: PuzzlePhase.playing,
      );
    }
  }
}

final puzzlePersistenceProvider = Provider<PuzzlePersistence>((ref) {
  return PuzzlePersistence();
});

final dailyPuzzleProvider =
    StateNotifierProvider<DailyPuzzleNotifier, DailyPuzzleState>((ref) {
      final persistence = ref.read(puzzlePersistenceProvider);
      return DailyPuzzleNotifier(persistence);
    });
