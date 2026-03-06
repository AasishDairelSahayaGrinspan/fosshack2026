import 'package:freezed_annotation/freezed_annotation.dart';
part 'recovery_score.freezed.dart';
part 'recovery_score.g.dart';

@freezed
class RecoveryScore with _$RecoveryScore {
  const factory RecoveryScore({
    required String id,
    required DateTime date,
    required double score,
    double? hrvZScore,
    double? rhrZScore,
    double? sleepZScore,
    @Default(14) int windowDays,
  }) = _RecoveryScore;

  factory RecoveryScore.fromJson(Map<String, dynamic> json) => _$RecoveryScoreFromJson(json);
}
