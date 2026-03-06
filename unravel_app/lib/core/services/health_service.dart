import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';

class HealthService {
  final Health _health = Health();

  static const _types = [
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
  ];

  Future<bool> requestPermissions() async {
    return await _health.requestAuthorization(_types);
  }

  Future<List<HealthDataPoint>> fetchLast14Days() async {
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    return await _health.getHealthDataFromTypes(
      startTime: twoWeeksAgo,
      endTime: now,
      types: _types,
    );
  }

  Future<bool> hasPermissions() async {
    return await _health.hasPermissions(_types) ?? false;
  }
}

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService();
});
