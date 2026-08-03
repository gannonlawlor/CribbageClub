import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement.freezed.dart';
part 'achievement.g.dart';

enum AchievementTier {
  @JsonValue('BRONZE')
  bronze,
  @JsonValue('SILVER')
  silver,
  @JsonValue('GOLD')
  gold,
}

/// One achievement's merged catalog + earned + progress view, as served by
/// GET /api/profiles/{userId}/achievements.
@freezed
class AchievementStatus with _$AchievementStatus {
  const factory AchievementStatus({
    required String key,
    required String name,
    required String description,
    required AchievementTier tier,
    int? target,
    int? progress,
    @Default(false) bool unlocked,
    String? unlockedAt,
    @Default(0) int sortOrder,
  }) = _AchievementStatus;

  factory AchievementStatus.fromJson(Map<String, dynamic> json) =>
      _$AchievementStatusFromJson(json);
}

@freezed
class AchievementsResponse with _$AchievementsResponse {
  const factory AchievementsResponse({
    required List<AchievementStatus> achievements,
    required int unlockedCount,
    required int totalCount,
  }) = _AchievementsResponse;

  factory AchievementsResponse.fromJson(Map<String, dynamic> json) =>
      _$AchievementsResponseFromJson(json);
}
