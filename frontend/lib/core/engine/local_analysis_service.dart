import 'dart:convert';

import '../models/card.dart';
import '../models/game_analysis.dart';
import '../models/game_history_event.dart';
import '../../src/rust/api/simple.dart' as rust;

/// Client-side analysis service for local AI games.
/// Mirrors backend AnalysisService.analyzeGame() logic.
class LocalAnalysisService {
  LocalAnalysisService._();

  static GameAnalysis analyzeGame(
    String gameId,
    List<GameHistoryEvent> history,
  ) {
    final roundChunks = _splitIntoRounds(history);
    final rounds = <RoundAnalysis>[];

    for (final events in roundChunks) {
      final round = _analyzeRound(events);
      if (round != null) rounds.add(round);
    }

    return GameAnalysis(gameId: gameId, rounds: rounds);
  }

  static List<List<GameHistoryEvent>> _splitIntoRounds(
    List<GameHistoryEvent> history,
  ) {
    final rounds = <List<GameHistoryEvent>>[];
    List<GameHistoryEvent>? current;

    for (final event in history) {
      if (event is RoundStarted) {
        current = [event];
        rounds.add(current);
      } else {
        current?.add(event);
      }
    }
    return rounds;
  }

  static RoundAnalysis? _analyzeRound(
    List<GameHistoryEvent> events,
  ) {
    final roundStarted = events.whereType<RoundStarted>().firstOrNull;
    final cardsDealt = events.whereType<CardsDealt>().firstOrNull;
    final deckCut = events.whereType<DeckCut>().firstOrNull;
    final handsCounted = events.whereType<HandCounted>().toList();
    final cribCounted = events.whereType<CribCounted>().firstOrNull;

    if (roundStarted == null || cardsDealt == null) return null;
    if (cardsDealt.dealtHands.isEmpty) return null;

    final playerIds = cardsDealt.dealtHands.keys.toList();
    final dealerPlayerId = deckCut != null
        ? playerIds.firstWhere(
            (id) => id != deckCut.cuttingPlayerId,
            orElse: () => playerIds.first,
          )
        : playerIds.first;

    final analyses = <PlayerRoundAnalysis>[];
    for (final playerId in playerIds) {
      final analysis = _analyzePlayerRound(
        playerId: playerId,
        isDealer: playerId == dealerPlayerId,
        dealtHands: cardsDealt.dealtHands,
        handsCounted: handsCounted,
        cribCounted: cribCounted,
      );
      if (analysis != null) analyses.add(analysis);
    }

    return RoundAnalysis(
      roundNumber: roundStarted.roundNumber,
      cutCard: deckCut?.cutCard,
      dealerPlayerId: dealerPlayerId,
      playerAnalyses: analyses,
    );
  }

  static PlayerRoundAnalysis? _analyzePlayerRound({
    required String playerId,
    required bool isDealer,
    required Map<String, List<PlayingCard>> dealtHands,
    required List<HandCounted> handsCounted,
    required CribCounted? cribCounted,
  }) {
    final dealtHand = dealtHands[playerId];
    if (dealtHand == null || dealtHand.length != 6) return null;

    final handCounted = handsCounted
        .where((e) => e.playerId == playerId)
        .firstOrNull;
    final keptHand = handCounted?.hand;
    if (keptHand == null || keptHand.length != 4) return null;

    final discarded = dealtHand.where((c) => !keptHand.contains(c)).toList();
    if (discarded.length != 2) return null;

    // Use Rust engine for discard analysis
    final handJson = jsonEncode(dealtHand.map((c) => c.toJson()).toList());
    final resultJson = rust.analyzeDiscardsJson(
      handJson: handJson,
      isDealer: isDealer,
    );
    final allOptions = (jsonDecode(resultJson) as List)
        .map((o) => DiscardOption.fromJson(o as Map<String, dynamic>))
        .toList();

    final optimalOption = allOptions.first;
    final discardedSet = discarded.toSet();
    final playerOption = allOptions
        .where(
          (o) =>
              o.discard.toSet().difference(discardedSet).isEmpty &&
              discardedSet.difference(o.discard.toSet()).isEmpty,
        )
        .firstOrNull;
    if (playerOption == null) return null;

    return PlayerRoundAnalysis(
      playerId: playerId,
      isDealer: isDealer,
      dealtHand: dealtHand,
      keptHand: keptHand,
      discarded: discarded,
      actualHandScore: handCounted!.totalPoints,
      actualCribScore: isDealer ? cribCounted?.totalPoints : null,
      optimalDiscard: optimalOption,
      playerDiscard: playerOption,
      evDifference:
          optimalOption.expectedCombinedValue -
          playerOption.expectedCombinedValue,
    );
  }
}
