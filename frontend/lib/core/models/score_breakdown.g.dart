// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_breakdown.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScoreBreakdownImpl _$$ScoreBreakdownImplFromJson(Map<String, dynamic> json) =>
    _$ScoreBreakdownImpl(
      fifteens: (json['fifteens'] as num?)?.toInt() ?? 0,
      pairs: (json['pairs'] as num?)?.toInt() ?? 0,
      runs: (json['runs'] as num?)?.toInt() ?? 0,
      flushes: (json['flushes'] as num?)?.toInt() ?? 0,
      nobs: (json['nobs'] as num?)?.toInt() ?? 0,
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ScoreBreakdownImplToJson(
  _$ScoreBreakdownImpl instance,
) => <String, dynamic>{
  'fifteens': instance.fifteens,
  'pairs': instance.pairs,
  'runs': instance.runs,
  'flushes': instance.flushes,
  'nobs': instance.nobs,
  'totalScore': instance.totalScore,
};
