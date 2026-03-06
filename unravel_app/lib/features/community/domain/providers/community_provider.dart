import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/friend.dart';

class CommunityNotifier extends AsyncNotifier<List<Friend>> {
  @override
  Future<List<Friend>> build() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/community/friends');
      return (response.data as List).map((d) => Friend.fromJson(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String> generateInvite() async {
    final dio = ref.read(dioProvider);
    final response = await dio.post('/community/invite');
    return response.data['encryptedCode'] as String;
  }

  Future<void> acceptInvite(String encryptedCode) async {
    final dio = ref.read(dioProvider);
    await dio.post('/community/accept', data: {'encryptedCode': encryptedCode});
    ref.invalidateSelf();
  }

  Future<void> toggleMoodSharing(String friendshipId, bool enabled) async {
    final dio = ref.read(dioProvider);
    await dio.patch('/community/$friendshipId/sharing', data: {'enabled': enabled});
    ref.invalidateSelf();
  }
}

final communityProvider = AsyncNotifierProvider<CommunityNotifier, List<Friend>>(
  () => CommunityNotifier(),
);
