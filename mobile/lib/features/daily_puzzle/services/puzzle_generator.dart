import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:math';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show ExternalLibrary;

import '../../../core/models/card.dart';
import '../../../core/models/game_analysis.dart';
import '../../../src/rust/api/simple.dart' as rust;
import '../../../src/rust/frb_generated.dart';
import '../models/daily_puzzle.dart';

class PuzzleGenerator {
  static const puzzlesPerDay = 5;

  PuzzleGenerator._();

  /// Generate a deterministic set of [puzzlesPerDay] puzzles for the given date.
  static DailyPuzzleSet generateSet(DateTime date) {
    final baseSeed = date.year * 10000 + date.month * 100 + date.day;
    final puzzles = <DailyPuzzle>[];
    for (var i = 0; i < puzzlesPerDay; i++) {
      puzzles.add(_generateOne(date, baseSeed * puzzlesPerDay + i, i));
    }
    return DailyPuzzleSet(date: date, puzzles: puzzles);
  }

  static DailyPuzzle _generateOne(DateTime date, int seed, int index) {
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
    final isDealer = rng.nextBool();

    return DailyPuzzle(
      date: date,
      index: index,
      hand: hand,
      isDealer: isDealer,
    );
  }

  /// Evaluate all 15 possible keeps and return them ranked best-to-worst.
  /// [evaluateAllKeeps] off the UI isolate. The exhaustive analysis blocks
  /// for long enough to freeze animation frames (the Rust FFI is synchronous),
  /// so it runs in a short-lived isolate with its own RustLib handle.
  static Future<List<KeepOption>> evaluateAllKeepsAsync(
    List<PlayingCard> hand,
    bool isDealer,
  ) {
    return Isolate.run(() async {
      await RustLib.init(
        externalLibrary: Platform.isIOS
            ? ExternalLibrary.process(iKnowHowToUseIt: true)
            : null,
      );
      return evaluateAllKeeps(hand, isDealer);
    });
  }

  static List<KeepOption> evaluateAllKeeps(
    List<PlayingCard> hand,
    bool isDealer,
  ) {
    final handJson = jsonEncode(hand.map((c) => c.toJson()).toList());
    final resultJson = rust.analyzeDiscardsJson(
      handJson: handJson,
      isDealer: isDealer,
    );
    final allOptions = (jsonDecode(resultJson) as List)
        .map((o) => DiscardOption.fromJson(o as Map<String, dynamic>))
        .toList();

    return [
      for (var i = 0; i < allOptions.length; i++)
        KeepOption(
          keep: allOptions[i].keep,
          discard: allOptions[i].discard,
          averageHandScore: allOptions[i].expectedHandValue,
          averageCribScore: allOptions[i].expectedCribValue,
          netScore: allOptions[i].expectedCombinedValue,
          rank: i + 1,
        ),
    ];
  }
}
