import 'package:freezed_annotation/freezed_annotation.dart';
part 'playlist.freezed.dart';
part 'playlist.g.dart';

@freezed
class MoodPlaylist with _$MoodPlaylist {
  const factory MoodPlaylist({
    required String id,
    required String name,
    required String spotifyUrl,
    required String quadrant,
    @Default(0) int trackCount,
    required DateTime createdAt,
  }) = _MoodPlaylist;

  factory MoodPlaylist.fromJson(Map<String, dynamic> json) => _$MoodPlaylistFromJson(json);
}
