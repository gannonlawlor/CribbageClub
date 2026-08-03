import 'achievement.dart';

class ImportGameRequest {
  final String localGameId;
  final String stateJson;
  final String? completedAt;

  ImportGameRequest({
    required this.localGameId,
    required this.stateJson,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'localGameId': localGameId,
    'stateJson': stateJson,
    if (completedAt != null) 'completedAt': completedAt,
  };
}

class ImportedGameMapping {
  final String localGameId;
  final String serverGameId;

  ImportedGameMapping({required this.localGameId, required this.serverGameId});

  factory ImportedGameMapping.fromJson(Map<String, dynamic> json) =>
      ImportedGameMapping(
        localGameId: json['localGameId'] as String,
        serverGameId: json['serverGameId'] as String,
      );
}

class ImportGamesResponse {
  final List<ImportedGameMapping> imported;
  final List<String> duplicates;
  final List<String> errors;
  final List<AchievementStatus> unlockedAchievements;

  ImportGamesResponse({
    required this.imported,
    required this.duplicates,
    required this.errors,
    this.unlockedAchievements = const [],
  });

  factory ImportGamesResponse.fromJson(
    Map<String, dynamic> json,
  ) => ImportGamesResponse(
    imported: (json['imported'] as List<dynamic>)
        .map((e) => ImportedGameMapping.fromJson(e as Map<String, dynamic>))
        .toList(),
    duplicates: (json['duplicates'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
    errors: (json['errors'] as List<dynamic>).map((e) => e as String).toList(),
    unlockedAchievements:
        (json['unlockedAchievements'] as List<dynamic>? ?? const [])
            .map((e) => AchievementStatus.fromJson(e as Map<String, dynamic>))
            .toList(),
  );
}
