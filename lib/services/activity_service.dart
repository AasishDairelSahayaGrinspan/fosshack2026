import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer_2/pedometer_2.dart';

import 'local_data_service.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class ActivityData {
  final int steps;
  final double distanceKm;
  final double calories;

  const ActivityData({this.steps = 0, this.distanceKm = 0, this.calories = 0});

  ActivityData copyWith({int? steps, double? distanceKm, double? calories}) {
    return ActivityData(
      steps: steps ?? this.steps,
      distanceKm: distanceKm ?? this.distanceKm,
      calories: calories ?? this.calories,
    );
  }

  Map<String, dynamic> toMap() => {
        'steps': steps,
        'distanceKm': distanceKm,
        'calories': calories,
        'date': DateTime.now().toIso8601String().substring(0, 10),
      };
}

class ActivityService {
  ActivityService._();
  static final ActivityService _instance = ActivityService._();
  factory ActivityService() => _instance;

  static const String _tag = 'ActivityService';

  final ValueNotifier<bool> isWalking = ValueNotifier<bool>(false);
  final ValueNotifier<ActivityData> todayData =
      ValueNotifier<ActivityData>(const ActivityData());
  final ValueNotifier<bool> permissionGranted = ValueNotifier<bool>(false);

  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<Position>? _positionSub;
  int _baseSteps = 0;
  bool _baseSet = false;
  DateTime? _lastWalkingNotification;
  Timer? _walkingDebounce;
  int _walkingSeconds = 0;

  Future<bool> requestPermissions() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        permissionGranted.value = false;
        return false;
      }
      permissionGranted.value = true;
      return true;
    } catch (e, st) {
      developer.log('Permission request failed', name: _tag, error: e, stackTrace: st);
      return false;
    }
  }

  Future<void> init() async {
    await _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    await LocalDataService().init();
    final logs = _getActivityLogs(user.$id);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    for (final log in logs) {
      if (log['date'] == today) {
        todayData.value = ActivityData(
          steps: (log['steps'] as num?)?.toInt() ?? 0,
          distanceKm: (log['distanceKm'] as num?)?.toDouble() ?? 0,
          calories: (log['calories'] as num?)?.toDouble() ?? 0,
        );
        return;
      }
    }
  }

  Future<void> startTracking() async {
    if (_stepSub != null) return; // already tracking

    try {
      _stepSub = Pedometer.stepCountStream.listen((event) {
        if (!_baseSet) {
          _baseSteps = event.steps;
          _baseSet = true;
        }
        final sessionSteps = event.steps - _baseSteps;
        final totalSteps = todayData.value.steps + sessionSteps.clamp(0, 999999);
        _baseSteps = event.steps;
        final dist = totalSteps * 0.0007;
        final cal = totalSteps * 0.04;
        todayData.value = ActivityData(steps: totalSteps, distanceKm: dist, calories: cal);
        _saveTodayData();
        _detectWalking();
      }, onError: (e) {
        developer.log('Pedometer error', name: _tag, error: e);
      });
    } catch (e, st) {
      developer.log('Failed to start pedometer', name: _tag, error: e, stackTrace: st);
    }
  }

  void _detectWalking() {
    _walkingSeconds += 1;
    isWalking.value = true;
    _walkingDebounce?.cancel();
    _walkingDebounce = Timer(const Duration(seconds: 10), () {
      isWalking.value = false;
      _walkingSeconds = 0;
    });

    // Walking notification logic: trigger after 2+ min, max once per 30min
    if (_walkingSeconds >= 120) {
      final now = DateTime.now();
      if (_lastWalkingNotification == null ||
          now.difference(_lastWalkingNotification!).inMinutes >= 30) {
        _lastWalkingNotification = now;
        NotificationService().showWalkingCheckIn();
      }
    }
  }

  Future<void> _saveTodayData() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final logs = _getActivityLogs(user.$id);
    final idx = logs.indexWhere((l) => l['date'] == today);
    final data = todayData.value.toMap();
    if (idx >= 0) {
      logs[idx] = data;
    } else {
      logs.insert(0, data);
    }
    _saveActivityLogs(user.$id, logs);
  }

  List<Map<String, dynamic>> _getActivityLogs(String userId) {
    final bucket = LocalDataService().getActivityLogs(userId);
    return bucket;
  }

  Future<void> _saveActivityLogs(String userId, List<Map<String, dynamic>> logs) async {
    await LocalDataService().saveActivityLogs(userId, logs);
  }

  void dispose() {
    _stepSub?.cancel();
    _positionSub?.cancel();
    _walkingDebounce?.cancel();
    _stepSub = null;
    _positionSub = null;
  }
}
