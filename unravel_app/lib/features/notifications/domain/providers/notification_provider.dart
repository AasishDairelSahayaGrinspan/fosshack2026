import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/constants/app_strings.dart';

class NotificationNotifier extends StateNotifier<bool> {
  NotificationNotifier() : super(false);

  Future<void> scheduleDaily(int hour, int minute) async {
    await NotificationService.cancelAll();
    final quote = AppStrings.motivationalQuotes[DateTime.now().day % AppStrings.motivationalQuotes.length];
    await NotificationService.scheduleDailyMotivation(
      id: 0,
      hour: hour,
      minute: minute,
      body: quote,
    );
    state = true;
  }

  Future<void> cancelAll() async {
    await NotificationService.cancelAll();
    state = false;
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, bool>(
  (ref) => NotificationNotifier(),
);
