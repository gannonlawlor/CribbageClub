import 'package:freezed_annotation/freezed_annotation.dart';

part 'score_breakdown.freezed.dart';
part 'score_breakdown.g.dart';

@freezed
class ScoreBreakdown with _$ScoreBreakdown {
  const factory ScoreBreakdown({
    @Default(0) int fifteens,
    @Default(0) int pairs,
    @Default(0) int runs,
    @Default(0) int flushes,
    @Default(0) int nobs,
    @Default(0) int totalScore,
  }) = _ScoreBreakdown;

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) =>
      _$ScoreBreakdownFromJson(json);
}
