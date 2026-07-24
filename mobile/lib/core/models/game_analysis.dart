import 'package:freezed_annotation/freezed_annotation.dart';
import 'card.dart';

part 'game_analysis.freezed.dart';
part 'game_analysis.g.dart';

@freezed
class DiscardOption with _$DiscardOption {
  const factory DiscardOption({
    required List<PlayingCard> keep,
    required List<PlayingCard> discard,
    required double expectedHandValue,
    required double expectedCribValue,
    required double expectedCombinedValue,
  }) = _DiscardOption;

  factory DiscardOption.fromJson(Map<String, dynamic> json) =>
      _$DiscardOptionFromJson(json);
}

@freezed
class PlayerRoundAnalysis with _$PlayerRoundAnalysis {
  const factory PlayerRoundAnalysis({
    required String playerId,
    required bool isDealer,
    required List<PlayingCard> dealtHand,
    required List<PlayingCard> keptHand,
    required List<PlayingCard> discarded,
    required int actualHandScore,
    int? actualCribScore,
    @Default(0) int actualPeggingScore,
    required DiscardOption optimalDiscard,
    required DiscardOption playerDiscard,
    required double evDifference,
    List<DiscardOption>? allOptions,
  }) = _PlayerRoundAnalysis;

  factory PlayerRoundAnalysis.fromJson(Map<String, dynamic> json) =>
      _$PlayerRoundAnalysisFromJson(json);
}

@freezed
class RoundAnalysis with _$RoundAnalysis {
  const factory RoundAnalysis({
    required int roundNumber,
    PlayingCard? cutCard,
    required String dealerPlayerId,
    required List<PlayerRoundAnalysis> playerAnalyses,
  }) = _RoundAnalysis;

  factory RoundAnalysis.fromJson(Map<String, dynamic> json) =>
      _$RoundAnalysisFromJson(json);
}

@freezed
class GameAnalysis with _$GameAnalysis {
  const factory GameAnalysis({
    required String gameId,
    required List<RoundAnalysis> rounds,
  }) = _GameAnalysis;

  factory GameAnalysis.fromJson(Map<String, dynamic> json) =>
      _$GameAnalysisFromJson(json);
}
