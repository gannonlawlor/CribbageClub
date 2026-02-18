import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/card.dart';
import '../models/daily_puzzle.dart';
import '../services/puzzle_generator.dart';
import '../services/puzzle_persistence.dart';

enum PuzzlePhase { playing, revealed }

class DailyPuzzleState {
  final DailyPuzzle? puzzle;
  final Set<PlayingCard> selectedCards;
  final PuzzlePhase phase;
  final int streak;
  final int? playerRank;
  final bool completedToday;

  const DailyPuzzleState({
    this.puzzle,
    this.selectedCards = const {},
    this.phase = PuzzlePhase.playing,
    this.streak = 0,
    this.playerRank,
    this.completedToday = false,
  });

  DailyPuzzleState copyWith({
    DailyPuzzle? puzzle,
    Set<PlayingCard>? selectedCards,
    PuzzlePhase? phase,
    int? streak,
    int? playerRank,
    bool? completedToday,
  }) {
    return DailyPuzzleState(
      puzzle: puzzle ?? this.puzzle,
      selectedCards: selectedCards ?? this.selectedCards,
      phase: phase ?? this.phase,
      streak: streak ?? this.streak,
      playerRank: playerRank ?? this.playerRank,
      completedToday: completedToday ?? this.completedToday,
    );
  }
}

class DailyPuzzleNotifier extends StateNotifier<DailyPuzzleState> {
  final PuzzlePersistence _persistence;

  DailyPuzzleNotifier(this._persistence) : super(const DailyPuzzleState());

  Future<void> loadPuzzle() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final puzzle = PuzzleGenerator.generate(today);
    final streak = await _persistence.getStreak();
    final completedToday = await _persistence.hasCompletedToday();

    if (completedToday) {
      // Show results if already completed today
      final results = await PuzzleGenerator.evaluateAllKeeps(
        puzzle.hand,
        puzzle.isDealer,
      );
      puzzle.results = results;
    }

    state = DailyPuzzleState(
      puzzle: puzzle,
      streak: streak,
      completedToday: completedToday,
      phase: completedToday ? PuzzlePhase.revealed : PuzzlePhase.playing,
    );
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
    if (state.selectedCards.length != 4 || state.puzzle == null) return;

    final puzzle = state.puzzle!;
    final results = await PuzzleGenerator.evaluateAllKeeps(
      puzzle.hand,
      puzzle.isDealer,
    );
    puzzle.results = results;

    // Find player's rank
    final playerKeep = state.selectedCards;
    int? playerRank;
    for (final option in results) {
      if (option.keep.toSet().containsAll(playerKeep) &&
          playerKeep.containsAll(option.keep)) {
        playerRank = option.rank;
        break;
      }
    }

    final today = DateTime(
      puzzle.date.year,
      puzzle.date.month,
      puzzle.date.day,
    );
    await _persistence.savePuzzleResult(today, playerRank ?? 0);
    final streak = await _persistence.getStreak();

    state = state.copyWith(
      phase: PuzzlePhase.revealed,
      playerRank: playerRank,
      streak: streak,
      completedToday: true,
    );
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
