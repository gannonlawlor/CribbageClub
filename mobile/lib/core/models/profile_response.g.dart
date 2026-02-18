// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileResponseImpl _$$ProfileResponseImplFromJson(
  Map<String, dynamic> json,
) => _$ProfileResponseImpl(
  userId: json['userId'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String?,
  avatarIndex: (json['avatarIndex'] as num?)?.toInt(),
  createdAt: json['createdAt'] as String,
  relationshipStatus: json['relationshipStatus'] as String?,
  rating: (json['rating'] as num?)?.toDouble() ?? 1500.0,
  ratingDeviation: (json['ratingDeviation'] as num?)?.toDouble() ?? 350.0,
  overallStats: CategoryStats.fromJson(
    json['overallStats'] as Map<String, dynamic>,
  ),
  aiStats: CategoryStats.fromJson(json['aiStats'] as Map<String, dynamic>),
  humanStats: CategoryStats.fromJson(
    json['humanStats'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$$ProfileResponseImplToJson(
  _$ProfileResponseImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'username': instance.username,
  'displayName': instance.displayName,
  'avatarIndex': instance.avatarIndex,
  'createdAt': instance.createdAt,
  'relationshipStatus': instance.relationshipStatus,
  'rating': instance.rating,
  'ratingDeviation': instance.ratingDeviation,
  'overallStats': instance.overallStats,
  'aiStats': instance.aiStats,
  'humanStats': instance.humanStats,
};

_$CategoryStatsImpl _$$CategoryStatsImplFromJson(Map<String, dynamic> json) =>
    _$CategoryStatsImpl(
      gamesPlayed: (json['gamesPlayed'] as num?)?.toInt() ?? 0,
      gamesWon: (json['gamesWon'] as num?)?.toInt() ?? 0,
      gamesLost: (json['gamesLost'] as num?)?.toInt() ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$CategoryStatsImplToJson(_$CategoryStatsImpl instance) =>
    <String, dynamic>{
      'gamesPlayed': instance.gamesPlayed,
      'gamesWon': instance.gamesWon,
      'gamesLost': instance.gamesLost,
      'winRate': instance.winRate,
      'averageScore': instance.averageScore,
    };
