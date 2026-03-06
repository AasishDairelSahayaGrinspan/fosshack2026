import 'package:freezed_annotation/freezed_annotation.dart';
part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String displayName,
    String? avatarUrl,
    required DateTime createdAt,
    @Default(0) int currentStreak,
    @Default(false) bool noAdviceMode,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
