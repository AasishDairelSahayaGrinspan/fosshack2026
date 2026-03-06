import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  late Box moodBox;
  late Box journalBox;
  late Box streakBox;
  late Box settingsBox;

  Future<void> init() async {
    moodBox = await Hive.openBox('mood_entries');
    journalBox = await Hive.openBox('journal_entries');
    streakBox = await Hive.openBox('streak');
    settingsBox = await Hive.openBox('settings');
  }

  // Settings helpers
  bool getNoAdviceMode() => settingsBox.get('noAdviceMode', defaultValue: false);
  Future<void> setNoAdviceMode(bool value) => settingsBox.put('noAdviceMode', value);

  int getNotificationHour() => settingsBox.get('notificationHour', defaultValue: 9);
  int getNotificationMinute() => settingsBox.get('notificationMinute', defaultValue: 0);
  Future<void> setNotificationTime(int hour, int minute) async {
    await settingsBox.put('notificationHour', hour);
    await settingsBox.put('notificationMinute', minute);
  }
}

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});
