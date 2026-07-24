// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_analysis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DiscardOptionImpl _$$DiscardOptionImplFromJson(Map<String, dynamic> json) =>
    _$DiscardOptionImpl(
      keep: (json['keep'] as List<dynamic>)
          .map((e) => PlayingCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      discard: (json['discard'] as List<dynamic>)
          .map((e) => PlayingCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      expectedHandValue: (json['expectedHandValue'] as num).toDouble(),
      expectedCribValue: (json['expectedCribValue'] as num).toDouble(),
      expectedCombinedValue: (json['expectedCombinedValue'] as num).toDouble(),
    );

Map<String, dynamic> _$$DiscardOptionImplToJson(_$DiscardOptionImpl instance) =>
    <String, dynamic>{
      'keep': instance.keep,
      'discard': instance.discard,
      'expectedHandValue': instance.expectedHandValue,
      'expectedCribValue': instance.expectedCribValue,
      'expectedCombinedValue': instance.expectedCombinedValue,
    };

_$PlayerRoundAnalysisImpl _$$PlayerRoundAnalysisImplFromJson(
  Map<String, dynamic> json,
) => _$PlayerRoundAnalysisImpl(
  playerId: json['playerId'] as String,
  isDealer: json['isDealer'] as bool,
  dealtHand: (json['dealtHand'] as List<dynamic>)
      .map((e) => PlayingCard.fromJson(e as Map<String, dynamic>))
      .toList(),
  keptHand: (json['keptHand'] as List<dynamic>)
      .map((e) => PlayingCard.fromJson(e as Map<String, dynamic>))
      .toList(),
  discarded: (json['discarded'] as List<dynamic>)
      .map((e) => PlayingCard.fromJson(e as Map<String, dynamic>))
      .toList(),
  actualHandScore: (json['actualHandScore'] as num).toInt(),
  actualCribScore: (json['actualCribScore'] as num?)?.toInt(),
  actualPeggingScore: (json['actualPeggingScore'] as num?)?.toInt() ?? 0,
  optimalDiscard: DiscardOption.fromJson(
    json['optimalDiscard'] as Map<String, dynamic>,
  ),
  playerDiscard: DiscardOption.fromJson(
    json['playerDiscard'] as Map<String, dynamic>,
  ),
  evDifference: (json['evDifference'] as num).toDouble(),
  allOptions: (json['allOptions'] as List<dynamic>?)
      ?.map((e) => DiscardOption.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$PlayerRoundAnalysisImplToJson(
  _$PlayerRoundAnalysisImpl instance,
) => <String, dynamic>{
  'playerId': instance.playerId,
  'isDealer': instance.isDealer,
  'dealtHand': instance.dealtHand,
  'keptHand': instance.keptHand,
  'discarded': instance.discarded,
  'actualHandScore': instance.actualHandScore,
  'actualCribScore': instance.actualCribScore,
  'actualPeggingScore': instance.actualPeggingScore,
  'optimalDiscard': instance.optimalDiscard,
  'playerDiscard': instance.playerDiscard,
  'evDifference': instance.evDifference,
  'allOptions': instance.allOptions,
};

_$RoundAnalysisImpl _$$RoundAnalysisImplFromJson(Map<String, dynamic> json) =>
    _$RoundAnalysisImpl(
      roundNumber: (json['roundNumber'] as num).toInt(),
      cutCard: json['cutCard'] == null
          ? null
          : PlayingCard.fromJson(json['cutCard'] as Map<String, dynamic>),
      dealerPlayerId: json['dealerPlayerId'] as String,
      playerAnalyses: (json['playerAnalyses'] as List<dynamic>)
          .map((e) => PlayerRoundAnalysis.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$RoundAnalysisImplToJson(_$RoundAnalysisImpl instance) =>
    <String, dynamic>{
      'roundNumber': instance.roundNumber,
      'cutCard': instance.cutCard,
      'dealerPlayerId': instance.dealerPlayerId,
      'playerAnalyses': instance.playerAnalyses,
    };

_$GameAnalysisImpl _$$GameAnalysisImplFromJson(Map<String, dynamic> json) =>
    _$GameAnalysisImpl(
      gameId: json['gameId'] as String,
      rounds: (json['rounds'] as List<dynamic>)
          .map((e) => RoundAnalysis.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$GameAnalysisImplToJson(_$GameAnalysisImpl instance) =>
    <String, dynamic>{'gameId': instance.gameId, 'rounds': instance.rounds};
