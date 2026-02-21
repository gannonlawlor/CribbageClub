// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'head_to_head_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HeadToHeadResponseImpl _$$HeadToHeadResponseImplFromJson(
  Map<String, dynamic> json,
) => _$HeadToHeadResponseImpl(
  gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
  viewerWins: (json['viewerWins'] as num?)?.toInt() ?? 0,
  opponentWins: (json['opponentWins'] as num?)?.toInt() ?? 0,
  recentGames:
      (json['recentGames'] as List<dynamic>?)
          ?.map((e) => HeadToHeadGame.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$HeadToHeadResponseImplToJson(
  _$HeadToHeadResponseImpl instance,
) => <String, dynamic>{
  'gamesPlayed': instance.gamesPlayed,
  'viewerWins': instance.viewerWins,
  'opponentWins': instance.opponentWins,
  'recentGames': instance.recentGames,
};

_$HeadToHeadGameImpl _$$HeadToHeadGameImplFromJson(Map<String, dynamic> json) =>
    _$HeadToHeadGameImpl(
      gameId: json['gameId'] as String,
      viewerScore: (json['viewerScore'] as num?)?.toInt() ?? 0,
      opponentScore: (json['opponentScore'] as num?)?.toInt() ?? 0,
      viewerWon: json['viewerWon'] as bool? ?? false,
      completedAt: json['completedAt'] as String,
    );

Map<String, dynamic> _$$HeadToHeadGameImplToJson(
  _$HeadToHeadGameImpl instance,
) => <String, dynamic>{
  'gameId': instance.gameId,
  'viewerScore': instance.viewerScore,
  'opponentScore': instance.opponentScore,
  'viewerWon': instance.viewerWon,
  'completedAt': instance.completedAt,
};
