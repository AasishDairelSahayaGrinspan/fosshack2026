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
  static const int _middayNudgeId = 2004;

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
    await _plugin.cancel(_middayNudgeId);
  }

  /// Schedule all default reminders at once.
  Future<void> scheduleAllDefaultReminders() async {
    await scheduleMorningMoodReminder();
    await scheduleEveningJournalReminder();
    await scheduleStreakReminder();
  }

  /// Personalized reminder setup driven by user preferences and baseline mood.
  Future<void> schedulePersonalizedReminders({
    String? sleepSchedule,
    List<String> concerns = const <String>[],
    double moodBaseline = 0.5,
    String communityPreference = 'yes',
  }) async {
    final isNightPerson = (sleepSchedule ?? '').toLowerCase() == 'night';
    final morningHour = isNightPerson ? 10 : 8;
    final eveningHour = isNightPerson ? 22 : 20;

    await _scheduleDailyNotification(
      id: _morningMoodId,
      title: 'Morning check-in',
      body: _pickMessage(
        _morningMessages(concerns),
        seed: DateTime.now().dayOfYear,
      ),
      hour: morningHour,
      minute: 15,
    );

    await _scheduleDailyNotification(
      id: _eveningJournalId,
      title: 'Evening reflection',
      body: _pickMessage(
        _eveningMessages(concerns),
        seed: DateTime.now().dayOfYear + 7,
      ),
      hour: eveningHour,
      minute: 30,
    );

    if (communityPreference == 'yes') {
      await _scheduleDailyNotification(
        id: _streakReminderId,
        title: 'Community and streak',
        body: 'Check in today and share one small win with the community.',
        hour: 18,
        minute: 0,
      );
    } else {
      await _scheduleDailyNotification(
        id: _streakReminderId,
        title: 'Keep your streak alive',
        body: 'A gentle reminder: one small check-in keeps your streak moving.',
        hour: 18,
        minute: 0,
      );
    }

    if (moodBaseline < 0.45) {
      await _scheduleDailyNotification(
        id: _middayNudgeId,
        title: 'Midday reset',
        body: _pickMessage(
          _supportMessages(concerns),
          seed: DateTime.now().dayOfYear + 11,
        ),
        hour: 13,
        minute: 0,
      );
    } else {
      await _plugin.cancel(_middayNudgeId);
    }
  }

  List<String> _morningMessages(List<String> concerns) {
    final hasSleep = concerns.any((c) => c.toLowerCase().contains('sleep'));
    final hasAnxiety = concerns.any((c) => c.toLowerCase().contains('anxiety'));

    return <String>[
      'Start gently. Name your current mood in one word.',
      if (hasSleep) 'A soft start: rate your rest and pick one calming task.',
      if (hasAnxiety) 'Grounding minute: inhale, exhale, then check in with yourself.',
    ];
  }

  List<String> _eveningMessages(List<String> concerns) {
    final hasHealing = concerns.any((c) => c.toLowerCase().contains('healing'));
    final hasFocus = concerns.any((c) => c.toLowerCase().contains('focus'));

    return <String>[
      'Before sleep, write one thought you want to release.',
      if (hasHealing) 'Healing grows in small steps. Capture one kind moment from today.',
      if (hasFocus) 'Reflect on your most focused moment today and what helped.',
    ];
  }

  List<String> _supportMessages(List<String> concerns) {
    final hasStress = concerns.any((c) => c.toLowerCase().contains('stress'));
    return <String>[
      'Take 60 seconds: unclench your jaw, drop your shoulders, breathe slowly.',
      if (hasStress) 'Stress reset: pause and do three slow breaths with a longer exhale.',
      'You are not behind. A small reset right now is enough.',
    ];
  }

  String _pickMessage(List<String> options, {required int seed}) {
    if (options.isEmpty) {
      return 'Take a gentle moment for yourself.';
    }
    return options[seed % options.length];
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

extension on DateTime {
  int get dayOfYear {
    final first = DateTime(year, 1, 1);
    return difference(first).inDays + 1;
  }
}
