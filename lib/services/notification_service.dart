import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int _greetingId = 1001;
  static const int _morningMoodId = 2001;
  static const int _eveningJournalId = 2002;
  static const int _streakReminderId = 2003;

  // Channel IDs
  static const String _greetingsChannel = 'unravel_greetings';
  static const String _remindersChannel = 'unravel_reminders';

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _plugin.initialize(initSettings);
  }

  Future<bool> requestPermissionIfNeeded() async {
    // Android
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    // iOS
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? true;
    }
    return true;
  }

  Future<void> openAppNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  Future<void> showTrackerEnabledGreeting() async {
    const androidDetails = AndroidNotificationDetails(
      _greetingsChannel,
      'Unravel Greetings',
      channelDescription: 'Greeting notifications from Unravel',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      _greetingId,
      'Unravel is on',
      'Thanks for turning on notifications. We will gently track with you.',
      const NotificationDetails(android: androidDetails),
    );
  }

  // ─── Scheduled Reminders ───

  /// Schedule a daily morning mood check-in reminder.
  /// [hour] and [minute] in 24-hour format (default 9:00 AM).
  Future<void> scheduleMorningMoodReminder({int hour = 9, int minute = 0}) async {
    await _scheduleDailyNotification(
      id: _morningMoodId,
      title: 'Good morning',
      body: 'Take a moment to check in with yourself. How are you feeling today?',
      hour: hour,
      minute: minute,
    );
  }

  /// Schedule a daily evening journal prompt.
  /// [hour] and [minute] in 24-hour format (default 8:30 PM).
  Future<void> scheduleEveningJournalReminder({int hour = 20, int minute = 30}) async {
    await _scheduleDailyNotification(
      id: _eveningJournalId,
      title: 'Evening reflection',
      body: 'Write a few thoughts before bed. Your journal is waiting.',
      hour: hour,
      minute: minute,
    );
  }

  /// Schedule a daily streak maintenance reminder.
  /// [hour] and [minute] in 24-hour format (default 6:00 PM).
  Future<void> scheduleStreakReminder({int hour = 18, int minute = 0}) async {
    await _scheduleDailyNotification(
      id: _streakReminderId,
      title: 'Keep your streak alive',
      body: "Don't forget to check in today and maintain your streak!",
      hour: hour,
      minute: minute,
    );
  }

  /// Cancel a specific reminder.
  Future<void> cancelMorningMoodReminder() async {
    await _plugin.cancel(_morningMoodId);
  }

  Future<void> cancelEveningJournalReminder() async {
    await _plugin.cancel(_eveningJournalId);
  }

  Future<void> cancelStreakReminder() async {
    await _plugin.cancel(_streakReminderId);
  }

  /// Cancel all scheduled reminders.
  Future<void> cancelAllReminders() async {
    await _plugin.cancel(_morningMoodId);
    await _plugin.cancel(_eveningJournalId);
    await _plugin.cancel(_streakReminderId);
  }

  /// Schedule all default reminders at once.
  Future<void> scheduleAllDefaultReminders() async {
    await scheduleMorningMoodReminder();
    await scheduleEveningJournalReminder();
    await scheduleStreakReminder();
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _remindersChannel,
      'Unravel Reminders',
      channelDescription: 'Daily wellness reminders from Unravel',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
