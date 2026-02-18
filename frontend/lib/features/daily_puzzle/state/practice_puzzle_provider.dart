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

  void submitKeep() {
    if (state.selectedCards.length != 4 || state.puzzle == null) return;

    final puzzle = state.puzzle!;
    final results = PuzzleGenerator.evaluateAllKeeps(
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

    state = state.copyWith(
      phase: PuzzlePhase.revealed,
      playerRank: playerRank,
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
