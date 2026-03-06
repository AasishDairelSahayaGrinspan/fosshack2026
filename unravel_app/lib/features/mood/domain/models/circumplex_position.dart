import 'package:freezed_annotation/freezed_annotation.dart';
part 'circumplex_position.freezed.dart';
part 'circumplex_position.g.dart';

@freezed
class CircumplexPosition with _$CircumplexPosition {
  const factory CircumplexPosition({
    @Default(0.0) double valence,
    @Default(0.0) double arousal,
    String? selectedWord,
    String? selectedQuadrant,
  }) = _CircumplexPosition;

  factory CircumplexPosition.fromJson(Map<String, dynamic> json) => _$CircumplexPositionFromJson(json);
}
