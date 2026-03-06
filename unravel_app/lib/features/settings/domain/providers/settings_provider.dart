import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/constants/app_strings.dart';

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const SettingsState());

  Future<void> loadSettings() async {
    final storage = _ref.read(localStorageServiceProvider);
    state = SettingsState(
      noAdviceMode: storage.getNoAdviceMode(),
      notificationHour: storage.getNotificationHour(),
      notificationMinute: storage.getNotificationMinute(),
    );
    _ref.read(noAdviceModeProvider.notifier).state = state.noAdviceMode;
  }

  Future<void> toggleNoAdviceMode(bool value) async {
    final storage = _ref.read(localStorageServiceProvider);
    await storage.setNoAdviceMode(value);
    _ref.read(noAdviceModeProvider.notifier).state = value;
    state = state.copyWith(noAdviceMode: value);
  }

  Future<void> setNotificationTime(int hour, int minute) async {
    final storage = _ref.read(localStorageServiceProvider);
    await storage.setNotificationTime(hour, minute);
    await NotificationService.cancelAll();
    await NotificationService.scheduleDailyMotivation(
      id: 0,
      hour: hour,
      minute: minute,
      body: AppStrings.motivationalQuotes[DateTime.now().day % AppStrings.motivationalQuotes.length],
    );
    state = state.copyWith(notificationHour: hour, notificationMinute: minute);
  }
}

class SettingsState {
  final bool noAdviceMode;
  final int notificationHour;
  final int notificationMinute;
  final bool healthPermissionsGranted;

  const SettingsState({
    this.noAdviceMode = false,
    this.notificationHour = 9,
    this.notificationMinute = 0,
    this.healthPermissionsGranted = false,
  });

  SettingsState copyWith({
    bool? noAdviceMode,
    int? notificationHour,
    int? notificationMinute,
    bool? healthPermissionsGranted,
  }) {
    return SettingsState(
      noAdviceMode: noAdviceMode ?? this.noAdviceMode,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
      healthPermissionsGranted: healthPermissionsGranted ?? this.healthPermissionsGranted,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref),
);
