// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameStateImpl _$$GameStateImplFromJson(Map<String, dynamic> json) =>
    _$GameStateImpl(
      gameId: json['gameId'] as String,
      players: (json['players'] as List<dynamic>)
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList(),
      crib:
          (json['crib'] as List<dynamic>?)
              ?.map((e) => PlayingCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      cutCard: json['cutCard'] == null
          ? null
          : PlayingCard.fromJson(json['cutCard'] as Map<String, dynamic>),
      currentPlayerId: json['currentPlayerId'] as String?,
      stage:
          $enumDecodeNullable(_$GameStageEnumMap, json['stage']) ??
          GameStage.dealing,
      playedCards:
          (json['playedCards'] as List<dynamic>?)
              ?.map((e) => PlayingCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      peggingCount: (json['peggingCount'] as num?)?.toInt() ?? 0,
      lastPlayWasGo: json['lastPlayWasGo'] as bool? ?? false,
      handsForCounting:
          (json['handsForCounting'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>)
                  .map((e) => PlayingCard.fromJson(e as Map<String, dynamic>))
                  .toList(),
            ),
          ) ??
          const {},
      history:
          (json['history'] as List<dynamic>?)
              ?.map((e) => GameHistoryEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      dealerIndex: (json['dealerIndex'] as num?)?.toInt() ?? 0,
      remainingDeck:
          (json['remainingDeck'] as List<dynamic>?)
              ?.map((e) => PlayingCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$GameStateImplToJson(_$GameStateImpl instance) =>
    <String, dynamic>{
      'gameId': instance.gameId,
      'players': instance.players,
      'crib': instance.crib,
      'cutCard': instance.cutCard,
      'currentPlayerId': instance.currentPlayerId,
      'stage': _$GameStageEnumMap[instance.stage]!,
      'playedCards': instance.playedCards,
      'peggingCount': instance.peggingCount,
      'lastPlayWasGo': instance.lastPlayWasGo,
      'handsForCounting': instance.handsForCounting,
      'history': instance.history,
      'dealerIndex': instance.dealerIndex,
      'remainingDeck': instance.remainingDeck,
    };

const _$GameStageEnumMap = {
  GameStage.dealing: 'DEALING',
  GameStage.discardingToCrib: 'DISCARDING_TO_CRIB',
  GameStage.cutting: 'CUTTING',
  GameStage.pegging: 'PEGGING',
  GameStage.counting: 'COUNTING',
  GameStage.gameOver: 'GAME_OVER',
};
