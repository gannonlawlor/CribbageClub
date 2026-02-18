import 'package:freezed_annotation/freezed_annotation.dart';
import 'card.dart';
import 'score_breakdown.dart';

part 'game_history_event.freezed.dart';
part 'game_history_event.g.dart';

@Freezed(unionKey: 'type')
sealed class GameHistoryEvent with _$GameHistoryEvent {
  @FreezedUnionValue('RoundStarted')
  const factory GameHistoryEvent.roundStarted({
    @Default('') String timestamp,
    required int roundNumber,
  }) = RoundStarted;

  @FreezedUnionValue('CardsDealt')
  const factory GameHistoryEvent.cardsDealt({
    @Default('') String timestamp,
    @Default({}) Map<String, List<PlayingCard>> dealtHands,
  }) = CardsDealt;

  @FreezedUnionValue('DeckCut')
  const factory GameHistoryEvent.deckCut({
    @Default('') String timestamp,
    required PlayingCard cutCard,
    required String cuttingPlayerId,
    @Default(false) bool dealerScoredNobs,
  }) = DeckCut;

  @FreezedUnionValue('CardPlayed')
  const factory GameHistoryEvent.cardPlayed({
    @Default('') String timestamp,
    required String playerId,
    required PlayingCard card,
    required int newCount,
    required int pointsScored,
    String? scoringReason,
  }) = CardPlayed;

  @FreezedUnionValue('GoAnnounced')
  const factory GameHistoryEvent.goAnnounced({
    @Default('') String timestamp,
    required String playerId,
    @Default(0) int pointsScored,
  }) = GoAnnounced;

  @FreezedUnionValue('PeggingEnded')
  const factory GameHistoryEvent.peggingEnded({
    @Default('') String timestamp,
  }) = PeggingEnded;

  @FreezedUnionValue('HandCounted')
  const factory GameHistoryEvent.handCounted({
    @Default('') String timestamp,
    required String playerId,
    @Default([]) List<PlayingCard> hand,
    required int totalPoints,
    required ScoreBreakdown scoreBreakdown,
  }) = HandCounted;

  @FreezedUnionValue('CribCounted')
  const factory GameHistoryEvent.cribCounted({
    @Default('') String timestamp,
    required String dealerPlayerId,
    required int totalPoints,
    required ScoreBreakdown scoreBreakdown,
    @Default([]) List<PlayingCard> cribCards,
  }) = CribCounted;

  @FreezedUnionValue('GameEnded')
  const factory GameHistoryEvent.gameEnded({
    @Default('') String timestamp,
    required String winnerPlayerId,
    required int finalScore,
  }) = GameEnded;

  @FreezedUnionValue('GameForfeited')
  const factory GameHistoryEvent.gameForfeited({
    @Default('') String timestamp,
    required String forfeitingPlayerId,
    required String reason,
  }) = GameForfeited;

  factory GameHistoryEvent.fromJson(Map<String, dynamic> json) =>
      _$GameHistoryEventFromJson(json);
}
