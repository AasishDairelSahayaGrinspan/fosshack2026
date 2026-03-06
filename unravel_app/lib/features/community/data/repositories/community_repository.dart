import 'package:dio/dio.dart';
import '../../domain/models/friend.dart';
import '../../domain/models/invite_code.dart';

class CommunityRepository {
  final Dio _dio;
  CommunityRepository(this._dio);

  Future<List<Friend>> getFriends() async {
    final response = await _dio.get('/community/friends');
    final list = response.data as List;
    return list.map((e) => Friend.fromJson(e)).toList();
  }

  Future<InviteCode> createInvite() async {
    final response = await _dio.post('/community/invite');
    return InviteCode.fromJson(response.data);
  }

  Future<void> acceptInvite(String code) async {
    await _dio.post('/community/invite/accept', data: {'code': code});
  }

  Future<void> toggleSharing(String id, bool enabled) async {
    await _dio.patch('/community/friends/$id/sharing', data: {
      'moodSharingEnabled': enabled,
    });
  }
}
