// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'puzzle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PuzzleResponseImpl _$$PuzzleResponseImplFromJson(Map<String, dynamic> json) =>
    _$PuzzleResponseImpl(
      id: json['id'] as String,
      hand: (json['hand'] as List<dynamic>)
          .map((e) => PlayingCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      isDealer: json['isDealer'] as bool,
      puzzleDate: json['puzzleDate'] as String,
      alreadySolved: json['alreadySolved'] as bool? ?? false,
    );

Map<String, dynamic> _$$PuzzleResponseImplToJson(
  _$PuzzleResponseImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'hand': instance.hand,
  'isDealer': instance.isDealer,
  'puzzleDate': instance.puzzleDate,
  'alreadySolved': instance.alreadySolved,
};

_$PuzzleSolveResponseImpl _$$PuzzleSolveResponseImplFromJson(
  Map<String, dynamic> json,
) => _$PuzzleSolveResponseImpl(
  isOptimal: json['isOptimal'] as bool,
  evDifference: (json['evDifference'] as num).toDouble(),
  yourOption: DiscardOption.fromJson(
    json['yourOption'] as Map<String, dynamic>,
  ),
  optimalOption: DiscardOption.fromJson(
    json['optimalOption'] as Map<String, dynamic>,
  ),
  allOptions: (json['allOptions'] as List<dynamic>)
      .map((e) => DiscardOption.fromJson(e as Map<String, dynamic>))
      .toList(),
  unlockedAchievements:
      (json['unlockedAchievements'] as List<dynamic>?)
          ?.map((e) => AchievementStatus.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$PuzzleSolveResponseImplToJson(
  _$PuzzleSolveResponseImpl instance,
) => <String, dynamic>{
  'isOptimal': instance.isOptimal,
  'evDifference': instance.evDifference,
  'yourOption': instance.yourOption,
  'optimalOption': instance.optimalOption,
  'allOptions': instance.allOptions,
  'unlockedAchievements': instance.unlockedAchievements,
};
