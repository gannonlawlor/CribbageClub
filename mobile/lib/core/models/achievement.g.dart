// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AchievementStatusImpl _$$AchievementStatusImplFromJson(
  Map<String, dynamic> json,
) => _$AchievementStatusImpl(
  key: json['key'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  tier: $enumDecode(_$AchievementTierEnumMap, json['tier']),
  target: (json['target'] as num?)?.toInt(),
  progress: (json['progress'] as num?)?.toInt(),
  unlocked: json['unlocked'] as bool? ?? false,
  unlockedAt: json['unlockedAt'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$AchievementStatusImplToJson(
  _$AchievementStatusImpl instance,
) => <String, dynamic>{
  'key': instance.key,
  'name': instance.name,
  'description': instance.description,
  'tier': _$AchievementTierEnumMap[instance.tier]!,
  'target': instance.target,
  'progress': instance.progress,
  'unlocked': instance.unlocked,
  'unlockedAt': instance.unlockedAt,
  'sortOrder': instance.sortOrder,
};

const _$AchievementTierEnumMap = {
  AchievementTier.bronze: 'BRONZE',
  AchievementTier.silver: 'SILVER',
  AchievementTier.gold: 'GOLD',
};

_$AchievementsResponseImpl _$$AchievementsResponseImplFromJson(
  Map<String, dynamic> json,
) => _$AchievementsResponseImpl(
  achievements: (json['achievements'] as List<dynamic>)
      .map((e) => AchievementStatus.fromJson(e as Map<String, dynamic>))
      .toList(),
  unlockedCount: (json['unlockedCount'] as num).toInt(),
  totalCount: (json['totalCount'] as num).toInt(),
);

Map<String, dynamic> _$$AchievementsResponseImplToJson(
  _$AchievementsResponseImpl instance,
) => <String, dynamic>{
  'achievements': instance.achievements,
  'unlockedCount': instance.unlockedCount,
  'totalCount': instance.totalCount,
};
