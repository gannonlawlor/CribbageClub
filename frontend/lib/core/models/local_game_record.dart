import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_game_record.freezed.dart';
part 'local_game_record.g.dart';

@freezed
class LocalGameRecord with _$LocalGameRecord {
  const factory LocalGameRecord({
    required String gameId,
    required String playerName,
    required String opponentName,
    required int playerScore,
    required int opponentScore,
    required bool isWin,
    required String difficulty,
    required DateTime completedAt,
  }) = _LocalGameRecord;

  factory LocalGameRecord.fromJson(Map<String, dynamic> json) =>
      _$LocalGameRecordFromJson(json);
}
