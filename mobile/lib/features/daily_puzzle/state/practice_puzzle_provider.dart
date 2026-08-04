import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/card.dart';
import '../models/daily_puzzle.dart';
import '../services/puzzle_generator.dart';
import 'puzzle_provider.dart';

class PracticePuzzleState {
  final DailyPuzzle? puzzle;
  final Set<PlayingCard> selectedCards;
  final PuzzlePhase phase;
  final int? playerRank;
  final int puzzleNumber;
  final int totalSolved;
  final int optimalCount;

  const PracticePuzzleState({
    this.puzzle,
    this.selectedCards = const {},
    this.phase = PuzzlePhase.playing,
    this.playerRank,
    this.puzzleNumber = 0,
    this.totalSolved = 0,
    this.optimalCount = 0,
  });

  PracticePuzzleState copyWith({
    DailyPuzzle? puzzle,
    Set<PlayingCard>? selectedCards,
    PuzzlePhase? phase,
    int? playerRank,
    int? puzzleNumber,
    int? totalSolved,
    int? optimalCount,
  }) {
    return PracticePuzzleState(
      puzzle: puzzle ?? this.puzzle,
      selectedCards: selectedCards ?? this.selectedCards,
      phase: phase ?? this.phase,
      playerRank: playerRank ?? this.playerRank,
      puzzleNumber: puzzleNumber ?? this.puzzleNumber,
      totalSolved: totalSolved ?? this.totalSolved,
      optimalCount: optimalCount ?? this.optimalCount,
    );
  }
}

class PracticePuzzleNotifier extends StateNotifier<PracticePuzzleState> {
  PracticePuzzleNotifier() : super(const PracticePuzzleState());

  void loadPuzzle() {
    final seed = Random().nextInt(999999);
    final rng = Random(seed);

    // Build full deck and Fisher-Yates shuffle
    final deck = <PlayingCard>[];
    for (final rank in Rank.values) {
      for (final suit in Suit.values) {
        deck.add(PlayingCard(rank: rank, suit: suit));
      }
    }
    for (var i = deck.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = deck[i];
      deck[i] = deck[j];
      deck[j] = temp;
    }

    final hand = deck.sublist(0, 6);
    final isDealer = seed % 2 == 0;
    final puzzle = DailyPuzzle(
      date: DateTime.now(),
      index: 0,
      hand: hand,
      isDealer: isDealer,
    );

    state = state.copyWith(
      puzzle: puzzle,
      selectedCards: const {},
      phase: PuzzlePhase.playing,
      playerRank: null,
      puzzleNumber: state.puzzleNumber + 1,
    );
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

  /// [pickedDiscards] flips what the taps meant: the keep is then the four
  /// cards the player left alone.
  ///
  /// The reveal is two-step: the screen flips to a solving state immediately,
  /// then fills in when the exhaustive analysis (run off the UI isolate)
  /// completes. The player can move on to the next puzzle mid-solve — their
  /// stats still count, only the reveal is dropped.
  Future<void> submitKeep({bool pickedDiscards = false}) async {
    final needed = pickedDiscards ? 2 : 4;
    if (state.selectedCards.length != needed || state.puzzle == null) return;
    if (state.phase != PuzzlePhase.playing) return;

    final puzzle = state.puzzle!;
    final number = state.puzzleNumber;
    final playerKeep = pickedDiscards
        ? puzzle.hand.where((c) => !state.selectedCards.contains(c)).toSet()
        : Set<PlayingCard>.from(state.selectedCards);

    state = state.copyWith(phase: PuzzlePhase.solving);

    final results = await PuzzleGenerator.evaluateAllKeepsAsync(
      puzzle.hand,
      puzzle.isDealer,
    );

    // Find player's rank
    int? playerRank;
    for (final option in results) {
      if (option.keep.toSet().containsAll(playerKeep) &&
          playerKeep.containsAll(option.keep)) {
        playerRank = option.rank;
        break;
      }
    }

    if (!mounted) return;
    // The reveal only lands if the player is still waiting on this puzzle.
    final stillHere =
        state.puzzleNumber == number && state.phase == PuzzlePhase.solving;
    if (stillHere) puzzle.results = results;
    state = state.copyWith(
      phase: stillHere ? PuzzlePhase.revealed : null,
      playerRank: stillHere ? playerRank : null,
      totalSolved: state.totalSolved + 1,
      optimalCount: state.optimalCount + (playerRank == 1 ? 1 : 0),
    );
  }

  void nextPuzzle() {
    loadPuzzle();
  }
}

final practicePuzzleProvider =
    StateNotifierProvider<PracticePuzzleNotifier, PracticePuzzleState>((ref) {
      return PracticePuzzleNotifier();
    });
