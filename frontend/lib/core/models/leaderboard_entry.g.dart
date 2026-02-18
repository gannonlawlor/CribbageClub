// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LeaderboardEntryImpl _$$LeaderboardEntryImplFromJson(
  Map<String, dynamic> json,
) => _$LeaderboardEntryImpl(
  playerId: json['playerId'] as String,
  displayName: json['displayName'] as String,
  gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
  gamesWon: (json['gamesWon'] as num?)?.toInt() ?? 0,
  gamesLost: (json['gamesLost'] as num?)?.toInt() ?? 0,
  winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
  averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
  highestGameScore: (json['highestGameScore'] as num?)?.toInt() ?? 0,
  currentWinStreak: (json['currentWinStreak'] as num?)?.toInt() ?? 0,
  longestWinStreak: (json['longestWinStreak'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$LeaderboardEntryImplToJson(
  _$LeaderboardEntryImpl instance,
) => <String, dynamic>{
  'playerId': instance.playerId,
  'displayName': instance.displayName,
  'gamesPlayed': instance.gamesPlayed,
  'gamesWon': instance.gamesWon,
  'gamesLost': instance.gamesLost,
  'winRate': instance.winRate,
  'averageScore': instance.averageScore,
  'highestGameScore': instance.highestGameScore,
  'currentWinStreak': instance.currentWinStreak,
  'longestWinStreak': instance.longestWinStreak,
};
