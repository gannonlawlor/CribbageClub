// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StatsResponseImpl _$$StatsResponseImplFromJson(Map<String, dynamic> json) =>
    _$StatsResponseImpl(
      playerId: json['playerId'] as String,
      gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
      gamesWon: (json['gamesWon'] as num?)?.toInt() ?? 0,
      gamesLost: (json['gamesLost'] as num?)?.toInt() ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      highestGameScore: (json['highestGameScore'] as num?)?.toInt() ?? 0,
      currentWinStreak: (json['currentWinStreak'] as num?)?.toInt() ?? 0,
      longestWinStreak: (json['longestWinStreak'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 1500.0,
      ratingDeviation: (json['ratingDeviation'] as num?)?.toDouble() ?? 350.0,
    );

Map<String, dynamic> _$$StatsResponseImplToJson(_$StatsResponseImpl instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'gamesPlayed': instance.gamesPlayed,
      'gamesWon': instance.gamesWon,
      'gamesLost': instance.gamesLost,
      'winRate': instance.winRate,
      'averageScore': instance.averageScore,
      'highestGameScore': instance.highestGameScore,
      'currentWinStreak': instance.currentWinStreak,
      'longestWinStreak': instance.longestWinStreak,
      'rating': instance.rating,
      'ratingDeviation': instance.ratingDeviation,
    };
