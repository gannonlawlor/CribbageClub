// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_game_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LocalGameRecordImpl _$$LocalGameRecordImplFromJson(
  Map<String, dynamic> json,
) => _$LocalGameRecordImpl(
  gameId: json['gameId'] as String,
  playerName: json['playerName'] as String,
  opponentName: json['opponentName'] as String,
  playerScore: (json['playerScore'] as num).toInt(),
  opponentScore: (json['opponentScore'] as num).toInt(),
  isWin: json['isWin'] as bool,
  difficulty: json['difficulty'] as String,
  completedAt: DateTime.parse(json['completedAt'] as String),
);

Map<String, dynamic> _$$LocalGameRecordImplToJson(
  _$LocalGameRecordImpl instance,
) => <String, dynamic>{
  'gameId': instance.gameId,
  'playerName': instance.playerName,
  'opponentName': instance.opponentName,
  'playerScore': instance.playerScore,
  'opponentScore': instance.opponentScore,
  'isWin': instance.isWin,
  'difficulty': instance.difficulty,
  'completedAt': instance.completedAt.toIso8601String(),
};
