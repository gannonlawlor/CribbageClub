// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_history_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoundStartedImpl _$$RoundStartedImplFromJson(Map<String, dynamic> json) =>
    _$RoundStartedImpl(
      timestamp: json['timestamp'] as String? ?? '',
      roundNumber: (json['roundNumber'] as num).toInt(),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$RoundStartedImplToJson(_$RoundStartedImpl instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'roundNumber': instance.roundNumber,
      'type': instance.$type,
    };

_$CardsDealtImpl _$$CardsDealtImplFromJson(Map<String, dynamic> json) =>
    _$CardsDealtImpl(
      timestamp: json['timestamp'] as String? ?? '',
      dealtHands:
          (json['dealtHands'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>)
                  .map((e) => PlayingCard.fromJson(e as Map<String, dynamic>))
                  .toList(),
            ),
          ) ??
          const {},
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$CardsDealtImplToJson(_$CardsDealtImpl instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'dealtHands': instance.dealtHands,
      'type': instance.$type,
    };

_$DeckCutImpl _$$DeckCutImplFromJson(Map<String, dynamic> json) =>
    _$DeckCutImpl(
      timestamp: json['timestamp'] as String? ?? '',
      cutCard: PlayingCard.fromJson(json['cutCard'] as Map<String, dynamic>),
      cuttingPlayerId: json['cuttingPlayerId'] as String,
      dealerScoredNobs: json['dealerScoredNobs'] as bool? ?? false,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$DeckCutImplToJson(_$DeckCutImpl instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'cutCard': instance.cutCard,
      'cuttingPlayerId': instance.cuttingPlayerId,
      'dealerScoredNobs': instance.dealerScoredNobs,
      'type': instance.$type,
    };

_$CardPlayedImpl _$$CardPlayedImplFromJson(Map<String, dynamic> json) =>
    _$CardPlayedImpl(
      timestamp: json['timestamp'] as String? ?? '',
      playerId: json['playerId'] as String,
      card: PlayingCard.fromJson(json['card'] as Map<String, dynamic>),
      newCount: (json['newCount'] as num).toInt(),
      pointsScored: (json['pointsScored'] as num).toInt(),
      scoringReason: json['scoringReason'] as String?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$CardPlayedImplToJson(_$CardPlayedImpl instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'playerId': instance.playerId,
      'card': instance.card,
      'newCount': instance.newCount,
      'pointsScored': instance.pointsScored,
      'scoringReason': instance.scoringReason,
      'type': instance.$type,
    };

_$GoAnnouncedImpl _$$GoAnnouncedImplFromJson(Map<String, dynamic> json) =>
    _$GoAnnouncedImpl(
      timestamp: json['timestamp'] as String? ?? '',
      playerId: json['playerId'] as String,
      pointsScored: (json['pointsScored'] as num?)?.toInt() ?? 0,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$GoAnnouncedImplToJson(_$GoAnnouncedImpl instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'playerId': instance.playerId,
      'pointsScored': instance.pointsScored,
      'type': instance.$type,
    };

_$PeggingEndedImpl _$$PeggingEndedImplFromJson(Map<String, dynamic> json) =>
    _$PeggingEndedImpl(
      timestamp: json['timestamp'] as String? ?? '',
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$PeggingEndedImplToJson(_$PeggingEndedImpl instance) =>
    <String, dynamic>{'timestamp': instance.timestamp, 'type': instance.$type};

_$HandCountedImpl _$$HandCountedImplFromJson(Map<String, dynamic> json) =>
    _$HandCountedImpl(
      timestamp: json['timestamp'] as String? ?? '',
      playerId: json['playerId'] as String,
      hand:
          (json['hand'] as List<dynamic>?)
              ?.map((e) => PlayingCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalPoints: (json['totalPoints'] as num).toInt(),
      scoreBreakdown: ScoreBreakdown.fromJson(
        json['scoreBreakdown'] as Map<String, dynamic>,
      ),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$HandCountedImplToJson(_$HandCountedImpl instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'playerId': instance.playerId,
      'hand': instance.hand,
      'totalPoints': instance.totalPoints,
      'scoreBreakdown': instance.scoreBreakdown,
      'type': instance.$type,
    };

_$CribCountedImpl _$$CribCountedImplFromJson(Map<String, dynamic> json) =>
    _$CribCountedImpl(
      timestamp: json['timestamp'] as String? ?? '',
      dealerPlayerId: json['dealerPlayerId'] as String,
      totalPoints: (json['totalPoints'] as num).toInt(),
      scoreBreakdown: ScoreBreakdown.fromJson(
        json['scoreBreakdown'] as Map<String, dynamic>,
      ),
      cribCards:
          (json['cribCards'] as List<dynamic>?)
              ?.map((e) => PlayingCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$CribCountedImplToJson(_$CribCountedImpl instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'dealerPlayerId': instance.dealerPlayerId,
      'totalPoints': instance.totalPoints,
      'scoreBreakdown': instance.scoreBreakdown,
      'cribCards': instance.cribCards,
      'type': instance.$type,
    };

_$GameEndedImpl _$$GameEndedImplFromJson(Map<String, dynamic> json) =>
    _$GameEndedImpl(
      timestamp: json['timestamp'] as String? ?? '',
      winnerPlayerId: json['winnerPlayerId'] as String,
      finalScore: (json['finalScore'] as num).toInt(),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$GameEndedImplToJson(_$GameEndedImpl instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'winnerPlayerId': instance.winnerPlayerId,
      'finalScore': instance.finalScore,
      'type': instance.$type,
    };

_$GameForfeitedImpl _$$GameForfeitedImplFromJson(Map<String, dynamic> json) =>
    _$GameForfeitedImpl(
      timestamp: json['timestamp'] as String? ?? '',
      forfeitingPlayerId: json['forfeitingPlayerId'] as String,
      reason: json['reason'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$GameForfeitedImplToJson(_$GameForfeitedImpl instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'forfeitingPlayerId': instance.forfeitingPlayerId,
      'reason': instance.reason,
      'type': instance.$type,
    };
