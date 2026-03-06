import 'package:freezed_annotation/freezed_annotation.dart';
part 'friend.freezed.dart';
part 'friend.g.dart';

@freezed
class Friend with _$Friend {
  const factory Friend({
    required String id,
    required String displayName,
    String? currentMoodQuadrant,
    @Default(false) bool moodSharingEnabled,
  }) = _Friend;

  factory Friend.fromJson(Map<String, dynamic> json) => _$FriendFromJson(json);
}
