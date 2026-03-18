import 'dart:developer' as developer;
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  static const String _tag = 'NotificationService';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _tzInitialized = false;

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    // Initialize timezone data for scheduled notifications.
    if (!_tzInitialized) {
      tz.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  Future<bool> requestPermissionIfNeeded() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> openAppNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  Future<void> showTrackerEnabledGreeting() async {
    const androidDetails = AndroidNotificationDetails(
      'unravel_greetings',
      'Unravel Greetings',
      channelDescription: 'Greeting notifications from Unravel',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      1001,
      'Unravel is on',
      'Thanks for turning on notifications. We will gently track with you.',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Shows the OTP code as a local notification.
  Future<void> showOtpNotification(String otp) async {
    const androidDetails = AndroidNotificationDetails(
      'unravel_otp',
      'Unravel OTP',
      channelDescription: 'One-time password notifications',
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'OTP Code',
      autoCancel: true,
    );
    await _plugin.show(
      1002,
      'Your Unravel code',
      'Your verification code is $otp. It expires in 5 minutes.',
      const NotificationDetails(android: androidDetails),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  ENGAGEMENT NOTIFICATIONS — gentle check-ins throughout the day
  // ─────────────────────────────────────────────────────────────

  /// Gentle check-in messages — warm, non-intrusive, varied.
  static const List<Map<String, String>> _engagementMessages = [
    {'title': 'Good morning', 'body': 'Take a breath. How are you feeling today?'},
    {'title': 'Just checking in', 'body': 'Your quiet place is always here for you.'},
    {'title': 'Mid-morning nudge', 'body': 'Have you taken a moment for yourself today?'},
    {'title': 'Hey there', 'body': 'How\'s your day going so far?'},
    {'title': 'Gentle reminder', 'body': 'A small check-in can make a big difference.'},
    {'title': 'Afternoon pause', 'body': 'Slow down for a moment. You deserve it.'},
    {'title': 'Thinking of you', 'body': 'Open your journal — even one line counts.'},
    {'title': 'Breathe', 'body': 'Try a 2-minute breathing session. You\'ll feel lighter.'},
    {'title': 'Music break?', 'body': 'Sometimes a song can shift everything. Give it a try.'},
    {'title': 'You\'re doing great', 'body': 'Checking in is a form of self-care.'},
    {'title': 'Evening wind-down', 'body': 'Reflect on something good from today.'},
    {'title': 'Sleep well', 'body': 'Log your sleep tonight. Your body will thank you.'},
    {'title': 'Small wins matter', 'body': 'What went well today? Write it down.'},
    {'title': 'Community love', 'body': 'Someone in the community might need your kind words.'},
    {'title': 'Mood check', 'body': 'How has your mood shifted today? Let\'s track it.'},
  ];

  /// Hours at which engagement notifications fire (7am → 10pm, spread out).
  static const List<int> _scheduleHours = [
    7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
  ];

  /// Schedules ~15 gentle engagement notifications spread throughout the day.
  /// Called once at app launch. Cancels old ones first to avoid duplicates.
  Future<void> scheduleEngagementNotifications() async {
    try {
      // Cancel any previously scheduled engagement notifications (IDs 2000–2099).
      for (int i = 2000; i < 2000 + _scheduleHours.length; i++) {
        await _plugin.cancel(i);
      }

      final now = tz.TZDateTime.now(tz.local);
      final rng = Random(now.day); // Seed on day so messages vary daily.

      // Shuffle messages for today.
      final shuffled = List<Map<String, String>>.from(_engagementMessages)
        ..shuffle(rng);

      const androidDetails = AndroidNotificationDetails(
        'unravel_engagement',
        'Unravel Check-ins',
        channelDescription: 'Gentle check-in reminders throughout the day',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        autoCancel: true,
        groupKey: 'unravel_engagement',
      );
      const details = NotificationDetails(android: androidDetails);

      for (int i = 0; i < _scheduleHours.length; i++) {
        final hour = _scheduleHours[i];
        final minute = rng.nextInt(45) + 5; // Random minute between :05 and :50

        var scheduledTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );

        // If this time already passed today, skip it.
        if (scheduledTime.isBefore(now)) continue;

        final msg = shuffled[i % shuffled.length];

        await _plugin.zonedSchedule(
          2000 + i,
          msg['title']!,
          msg['body']!,
          scheduledTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: null, // One-shot, not repeating.
        );
      }

      developer.log(
        'Scheduled engagement notifications for today',
        name: _tag,
      );
    } catch (e, st) {
      developer.log(
        'Failed to schedule engagement notifications',
        name: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Cancels all engagement notifications.
  Future<void> cancelEngagementNotifications() async {
    for (int i = 2000; i < 2000 + _scheduleHours.length; i++) {
      await _plugin.cancel(i);
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  MOOD-BASED FOLLOW-UP NOTIFICATIONS
  // ─────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────
  //  PHASE 9 — Inactivity, Sleep, Breathing, Streak reminders
  // ─────────────────────────────────────────────────────────────

  /// Inactivity reminder — fires 48h from now. Reset each app launch.
  Future<void> scheduleInactivityReminder() async {
    try {
      await _plugin.cancel(4000);
      final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(hours: 48));
      const androidDetails = AndroidNotificationDetails(
        'unravel_inactivity',
        'Inactivity Reminders',
        channelDescription: 'Gentle reminder when you haven\'t visited in a while',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        autoCancel: true,
      );
      await _plugin.zonedSchedule(
        4000,
        'We haven\'t seen you in a while',
        'Your quiet place is still here. Come back when you\'re ready.',
        scheduledTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      developer.log('Scheduled inactivity reminder at $scheduledTime', name: _tag);
    } catch (e, st) {
      developer.log('Failed to schedule inactivity reminder', name: _tag, error: e, stackTrace: st);
    }
  }

  Future<void> cancelInactivityReminder() async {
    await _plugin.cancel(4000);
  }

  /// Sleep reminder — daily repeating at given hour (default 22:00).
  Future<void> scheduleSleepReminder({int hour = 22, int minute = 0}) async {
    try {
      await _plugin.cancel(4001);
      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      const androidDetails = AndroidNotificationDetails(
        'unravel_sleep',
        'Sleep Reminders',
        channelDescription: 'Daily sleep tracking reminder',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        autoCancel: true,
      );
      await _plugin.zonedSchedule(
        4001,
        'Time to wind down',
        'Your mind deserves rest tonight. Log your sleep in Unravel.',
        scheduledTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      developer.log('Scheduled sleep reminder at $hour:$minute daily', name: _tag);
    } catch (e, st) {
      developer.log('Failed to schedule sleep reminder', name: _tag, error: e, stackTrace: st);
    }
  }

  Future<void> cancelSleepReminder() async {
    await _plugin.cancel(4001);
  }

  /// Breathing reminder — daily repeating at given hour (default 14:00).
  Future<void> scheduleBreathingReminder({int hour = 14, int minute = 0}) async {
    try {
      await _plugin.cancel(4002);
      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      const androidDetails = AndroidNotificationDetails(
        'unravel_breathing',
        'Breathing Reminders',
        channelDescription: 'Daily breathing exercise reminder',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        autoCancel: true,
      );
      await _plugin.zonedSchedule(
        4002,
        'Take a slow breath',
        'Take a slow breath with Unravel. Just 2 minutes can shift your whole day.',
        scheduledTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      developer.log('Scheduled breathing reminder at $hour:$minute daily', name: _tag);
    } catch (e, st) {
      developer.log('Failed to schedule breathing reminder', name: _tag, error: e, stackTrace: st);
    }
  }

  Future<void> cancelBreathingReminder() async {
    await _plugin.cancel(4002);
  }

  /// Streak encouragement — fires next day at 8am if streak >= 3.
  Future<void> scheduleStreakEncouragement(int streakDays) async {
    try {
      await _plugin.cancel(4003);
      if (streakDays < 3) return;

      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, 8, 0);

      final messages = [
        {'title': '$streakDays days strong!', 'body': 'Your streak is growing. Keep showing up for yourself.'},
        {'title': 'You\'re on a roll!', 'body': '$streakDays days in a row. That\'s real commitment.'},
        {'title': 'Streak: $streakDays days', 'body': 'Consistency is self-care. You\'re doing amazing.'},
      ];
      final msg = messages[streakDays % messages.length];

      const androidDetails = AndroidNotificationDetails(
        'unravel_streak',
        'Streak Encouragement',
        channelDescription: 'Celebrating your consistency',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        autoCancel: true,
      );
      await _plugin.zonedSchedule(
        4003,
        msg['title']!,
        msg['body']!,
        scheduledTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      developer.log('Scheduled streak encouragement ($streakDays days) at $scheduledTime', name: _tag);
    } catch (e, st) {
      developer.log('Failed to schedule streak encouragement', name: _tag, error: e, stackTrace: st);
    }
  }

  Future<void> cancelStreakEncouragement() async {
    await _plugin.cancel(4003);
  }

  /// Schedules a follow-up notification 2 hours after the user logs a mood.
  /// - Low/Anxious/Overwhelmed moods get a caring check-in.
  /// - Happy/Calm moods get a music/celebration nudge.
  Future<void> scheduleMoodFollowUp(double moodScore) async {
    try {
      // Cancel any previous mood follow-up.
      await _plugin.cancel(3000);

      final delay = const Duration(hours: 2);
      final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);

      // Don't schedule if it would fire after 10pm.
      if (scheduledTime.hour >= 22) return;

      String title;
      String body;

      if (moodScore <= 0.4) {
        // Low / Anxious / Overwhelmed
        final rng = Random();
        final lowMessages = [
          {
            'title': 'Hey buddy, are you okay?',
            'body': 'I heard you\'re feeling low. Try a breathing exercise or get some rest.',
          },
          {
            'title': 'Sending you a warm hug',
            'body': 'It\'s okay to not be okay. Try journaling your thoughts — it helps.',
          },
          {
            'title': 'Be gentle with yourself',
            'body': 'A short breathing session can calm the storm. You\'ve got this.',
          },
          {
            'title': 'You\'re not alone',
            'body': 'Take a moment to breathe. Your quiet place is waiting.',
          },
        ];
        final msg = lowMessages[rng.nextInt(lowMessages.length)];
        title = msg['title']!;
        body = msg['body']!;
      } else {
        // Happy / Calm
        final rng = Random();
        final highMessages = [
          {
            'title': 'Great vibes!',
            'body': 'You\'re in a good mood — how about some feel-good music?',
          },
          {
            'title': 'Keep that energy going',
            'body': 'Open Music and vibe to your favorite playlist.',
          },
          {
            'title': 'Celebrate this moment',
            'body': 'Write about what made you feel good today. Future you will love reading it.',
          },
        ];
        final msg = highMessages[rng.nextInt(highMessages.length)];
        title = msg['title']!;
        body = msg['body']!;
      }

      const androidDetails = AndroidNotificationDetails(
        'unravel_mood_followup',
        'Mood Follow-ups',
        channelDescription: 'Caring follow-up based on your mood',
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
      );

      await _plugin.zonedSchedule(
        3000,
        title,
        body,
        scheduledTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      developer.log(
        'Scheduled mood follow-up (score=$moodScore) at $scheduledTime',
        name: _tag,
      );
    } catch (e, st) {
      developer.log(
        'Failed to schedule mood follow-up',
        name: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }
}
