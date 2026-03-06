import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/recovery_score.dart';

class RecoveryNotifier extends AsyncNotifier<RecoveryScore?> {
  @override
  Future<RecoveryScore?> build() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/recovery/score');
      if (response.data != null) {
        return RecoveryScore.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<void> submitHealthData(Map<String, dynamic> data) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/recovery/health-data', data: data);
      ref.invalidateSelf();
    } catch (_) {}
  }
}

final recoveryProvider = AsyncNotifierProvider<RecoveryNotifier, RecoveryScore?>(
  () => RecoveryNotifier(),
);

// Recovery history for charts
class RecoveryHistoryNotifier extends AsyncNotifier<List<RecoveryScore>> {
  @override
  Future<List<RecoveryScore>> build() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/recovery/history', queryParameters: {'days': 7});
      return (response.data as List).map((d) => RecoveryScore.fromJson(d)).toList();
    } catch (_) {
      return [];
    }
  }
}

final recoveryHistoryProvider = AsyncNotifierProvider<RecoveryHistoryNotifier, List<RecoveryScore>>(
  () => RecoveryHistoryNotifier(),
);
