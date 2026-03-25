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

  // Notification IDs
  static const int _greetingId = 1001;
  static const int _morningMoodId = 2001;
  static const int _eveningJournalId = 2002;
  static const int _streakReminderId = 2003;
  static const int _middayNudgeId = 2004;
  static const int _communityNotificationBaseId = 5000;

  // Channel IDs
  static const String _greetingsChannel = 'unravel_greetings';
  static const String _remindersChannel = 'unravel_reminders';
  static const String _communityChannel = 'unravel_community';

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    // Initialize timezone data for scheduled notifications.
    if (!_tzInitialized) {
      tz.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  Future<bool> requestPermissionIfNeeded() async {
    // Android
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    // iOS
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
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
      id: _greetingId,
      title: 'Unravel is on',
      body: 'Thanks for turning on notifications. We will gently track with you.',
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  // ─── Scheduled Reminders ───

  /// Schedule a daily morning mood check-in reminder.
  /// [hour] and [minute] in 24-hour format (default 9:00 AM).
  Future<void> scheduleMorningMoodReminder({
    int hour = 9,
    int minute = 0,
  }) async {
    await _scheduleDailyNotification(
      id: _morningMoodId,
      title: 'Good morning',
      body:
          'Take a moment to check in with yourself. How are you feeling today?',
      hour: hour,
      minute: minute,
    );
  }

  /// Schedule a daily evening journal prompt.
  /// [hour] and [minute] in 24-hour format (default 8:30 PM).
  Future<void> scheduleEveningJournalReminder({
    int hour = 20,
    int minute = 30,
  }) async {
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
    await _plugin.cancel(id: _morningMoodId);
  }

  Future<void> cancelEveningJournalReminder() async {
    await _plugin.cancel(id: _eveningJournalId);
  }

  Future<void> cancelStreakReminder() async {
    await _plugin.cancel(id: _streakReminderId);
  }

  /// Cancel all scheduled reminders.
  Future<void> cancelAllReminders() async {
    await _plugin.cancel(id: _morningMoodId);
    await _plugin.cancel(id: _eveningJournalId);
    await _plugin.cancel(id: _streakReminderId);
    await _plugin.cancel(id: _middayNudgeId);
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
      await _plugin.cancel(id: _middayNudgeId);
    }
  }

  List<String> _morningMessages(List<String> concerns) {
    final hasSleep = concerns.any((c) => c.toLowerCase().contains('sleep'));
    final hasAnxiety = concerns.any((c) => c.toLowerCase().contains('anxiety'));

    return <String>[
      'Start gently. Name your current mood in one word.',
      if (hasSleep) 'A soft start: rate your rest and pick one calming task.',
      if (hasAnxiety)
        'Grounding minute: inhale, exhale, then check in with yourself.',
    ];
  }

  List<String> _eveningMessages(List<String> concerns) {
    final hasHealing = concerns.any((c) => c.toLowerCase().contains('healing'));
    final hasFocus = concerns.any((c) => c.toLowerCase().contains('focus'));

    return <String>[
      'Before sleep, write one thought you want to release.',
      if (hasHealing)
        'Healing grows in small steps. Capture one kind moment from today.',
      if (hasFocus)
        'Reflect on your most focused moment today and what helped.',
    ];
  }

  List<String> _supportMessages(List<String> concerns) {
    final hasStress = concerns.any((c) => c.toLowerCase().contains('stress'));
    return <String>[
      'Take 60 seconds: unclench your jaw, drop your shoulders, breathe slowly.',
      if (hasStress)
        'Stress reset: pause and do three slow breaths with a longer exhale.',
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
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  ENGAGEMENT NOTIFICATIONS — gentle check-ins throughout the day
  // ─────────────────────────────────────────────────────────────

  /// Gentle check-in messages — warm, non-intrusive, varied.
  static const List<Map<String, String>> _engagementMessages = [
    {
      'title': 'Good morning',
      'body': 'Take a breath. How are you feeling today?',
    },
    {
      'title': 'Just checking in',
      'body': 'Your quiet place is always here for you.',
    },
    {
      'title': 'Mid-morning nudge',
      'body': 'Have you taken a moment for yourself today?',
    },
    {'title': 'Hey there', 'body': 'How\'s your day going so far?'},
    {
      'title': 'Gentle reminder',
      'body': 'A small check-in can make a big difference.',
    },
    {
      'title': 'Afternoon pause',
      'body': 'Slow down for a moment. You deserve it.',
    },
    {
      'title': 'Thinking of you',
      'body': 'Open your journal — even one line counts.',
    },
    {
      'title': 'Breathe',
      'body': 'Try a 2-minute breathing session. You\'ll feel lighter.',
    },
    {
      'title': 'Music break?',
      'body': 'Sometimes a song can shift everything. Give it a try.',
    },
    {
      'title': 'You\'re doing great',
      'body': 'Checking in is a form of self-care.',
    },
    {
      'title': 'Evening wind-down',
      'body': 'Reflect on something good from today.',
    },
    {
      'title': 'Sleep well',
      'body': 'Log your sleep tonight. Your body will thank you.',
    },
    {
      'title': 'Small wins matter',
      'body': 'What went well today? Write it down.',
    },
    {
      'title': 'Community love',
      'body': 'Someone in the community might need your kind words.',
    },
    {
      'title': 'Mood check',
      'body': 'How has your mood shifted today? Let\'s track it.',
    },
  ];

  /// Hours at which engagement notifications fire (7am → 10pm, spread out).
  static const List<int> _scheduleHours = [
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
  ];

  /// Schedules ~15 gentle engagement notifications spread throughout the day.
  /// Called once at app launch. Cancels old ones first to avoid duplicates.
  Future<void> scheduleEngagementNotifications() async {
    try {
      // Cancel any previously scheduled engagement notifications (IDs 2000–2099).
      for (int i = 2000; i < 2000 + _scheduleHours.length; i++) {
        await _plugin.cancel(id: i);
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
          id: 2000 + i,
          title: msg['title']!,
          body: msg['body']!,
          scheduledDate: scheduledTime,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      developer.log('Scheduled engagement notifications for today', name: _tag);
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
      await _plugin.cancel(id: i);
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
      await _plugin.cancel(id: 4000);
      final scheduledTime = tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(hours: 48));
      const androidDetails = AndroidNotificationDetails(
        'unravel_inactivity',
        'Inactivity Reminders',
        channelDescription:
            'Gentle reminder when you haven\'t visited in a while',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        autoCancel: true,
      );
      await _plugin.zonedSchedule(
        id: 4000,
        title: 'We haven\'t seen you in a while',
        body: 'Your quiet place is still here. Come back when you\'re ready.',
        scheduledDate: scheduledTime,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      developer.log(
        'Scheduled inactivity reminder at $scheduledTime',
        name: _tag,
      );
    } catch (e, st) {
      developer.log(
        'Failed to schedule inactivity reminder',
        name: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> cancelInactivityReminder() async {
    await _plugin.cancel(id: 4000);
  }

  /// Sleep reminder — daily repeating at given hour (default 22:00).
  Future<void> scheduleSleepReminder({int hour = 22, int minute = 0}) async {
    try {
      await _plugin.cancel(id: 4001);
      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
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
        id: 4001,
        title: 'Time to wind down',
        body: 'Your mind deserves rest tonight. Log your sleep in Unravel.',
        scheduledDate: scheduledTime,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      developer.log(
        'Scheduled sleep reminder at $hour:$minute daily',
        name: _tag,
      );
    } catch (e, st) {
      developer.log(
        'Failed to schedule sleep reminder',
        name: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> cancelSleepReminder() async {
    await _plugin.cancel(id: 4001);
  }

  /// Breathing reminder — daily repeating at given hour (default 14:00).
  Future<void> scheduleBreathingReminder({
    int hour = 14,
    int minute = 0,
  }) async {
    try {
      await _plugin.cancel(id: 4002);
      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
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
        id: 4002,
        title: 'Take a slow breath',
        body: 'Take a slow breath with Unravel. Just 2 minutes can shift your whole day.',
        scheduledDate: scheduledTime,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      developer.log(
        'Scheduled breathing reminder at $hour:$minute daily',
        name: _tag,
      );
    } catch (e, st) {
      developer.log(
        'Failed to schedule breathing reminder',
        name: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> cancelBreathingReminder() async {
    await _plugin.cancel(id: 4002);
  }

  /// Streak encouragement — fires next day at 8am if streak >= 3.
  Future<void> scheduleStreakEncouragement(int streakDays) async {
    try {
      await _plugin.cancel(id: 4003);
      if (streakDays < 3) return;

      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        8,
        0,
      );

      final messages = [
        {
          'title': '$streakDays days strong!',
          'body': 'Your streak is growing. Keep showing up for yourself.',
        },
        {
          'title': 'You\'re on a roll!',
          'body': '$streakDays days in a row. That\'s real commitment.',
        },
        {
          'title': 'Streak: $streakDays days',
          'body': 'Consistency is self-care. You\'re doing amazing.',
        },
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
        id: 4003,
        title: msg['title']!,
        body: msg['body']!,
        scheduledDate: scheduledTime,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      developer.log(
        'Scheduled streak encouragement ($streakDays days) at $scheduledTime',
        name: _tag,
      );
    } catch (e, st) {
      developer.log(
        'Failed to schedule streak encouragement',
        name: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> cancelStreakEncouragement() async {
    await _plugin.cancel(id: 4003);
  }

  /// Walking check-in notification.
  Future<void> showWalkingCheckIn() async {
    const androidDetails = AndroidNotificationDetails(
      'unravel_activity',
      'Activity Check-ins',
      channelDescription: 'Walking and activity notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
    );
    await _plugin.show(
      id: 5000,
      title: 'You\'re on the move!',
      body: 'Great walk! Keep going — your body and mind will thank you.',
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  /// Hydration reminder notification.
  Future<void> showHydrationReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'unravel_hydration',
      'Hydration Reminders',
      channelDescription: 'Reminders to stay hydrated',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
    );
    await _plugin.show(
      id: 5001,
      title: 'Stay hydrated',
      body: 'Take a moment to drink some water. Your body needs it.',
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  /// Schedules a follow-up notification 2 hours after the user logs a mood.
  /// - Low/Anxious/Overwhelmed moods get a caring check-in.
  /// - Happy/Calm moods get a music/celebration nudge.
  Future<void> scheduleMoodFollowUp(double moodScore) async {
    try {
      // Cancel any previous mood follow-up.
      await _plugin.cancel(id: 3000);

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
            'body':
                'I heard you\'re feeling low. Try a breathing exercise or get some rest.',
          },
          {
            'title': 'Sending you a warm hug',
            'body':
                'It\'s okay to not be okay. Try journaling your thoughts — it helps.',
          },
          {
            'title': 'Be gentle with yourself',
            'body':
                'A short breathing session can calm the storm. You\'ve got this.',
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
            'body':
                'Write about what made you feel good today. Future you will love reading it.',
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
        id: 3000,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        notificationDetails: const NotificationDetails(android: androidDetails),
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

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // ─────────────────────────────────────────────────────────────
  //  COMMUNITY PUSH NOTIFICATIONS
  // ─────────────────────────────────────────────────────────────

  /// Show a community update notification when someone posts.
  /// Used for local/demo notifications on the device.
  Future<void> showCommunityPostNotification({
    required String postId,
    required String authorName,
    required String postTitle,
  }) async {
    try {
      final notificationId = _communityNotificationBaseId + postId.hashCode % 1000;
      final excerpt = postTitle.length > 60
          ? '${postTitle.substring(0, 60)}...'
          : postTitle;

      const androidDetails = AndroidNotificationDetails(
        _communityChannel,
        'Community Updates',
        channelDescription: 'Notifications about new posts in the community',
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
        tag: 'community_post',
      );

      await _plugin.show(
        id: notificationId,
        title: '$authorName posted in Community',
        body: excerpt,
        notificationDetails: const NotificationDetails(android: androidDetails),
        payload: 'community_post_$postId',
      );

      developer.log(
        'Showed community post notification: $postId from $authorName',
        name: _tag,
      );
    } catch (e, st) {
      developer.log(
        'Failed to show community post notification',
        name: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Handle notification tap action (route to community post).
  /// Can be extended to route to the specific post when tapped.
  void onNotificationTapped(String? payload) {
    if (payload != null && payload.startsWith('community_post_')) {
      final postId = payload.replaceFirst('community_post_', '');
      developer.log('Community post notification tapped: $postId', name: _tag);
      // Route to community post detail screen
      // This can be handled by the app navigation service
    }
  }

  /// Send a streak reminder after 1 day of inactivity
  Future<void> sendStreakReminderNotification() async {
    const androidDetails = AndroidNotificationDetails(
      _remindersChannel,
      'Unravel Reminders',
      channelDescription: 'Daily check-in reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: _streakReminderId + 1,
      title: 'Don\'t lose your streak! 🔥',
      body: 'We haven\'t seen you today. Check in to keep your wellness journey going.',
      notificationDetails: notificationDetails,
    );
  }

  /// Send a streak break notification after 2 days of inactivity
  Future<void> sendStreakBrokenNotification() async {
    const androidDetails = AndroidNotificationDetails(
      _remindersChannel,
      'Unravel Reminders',
      channelDescription: 'Daily check-in reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: _streakReminderId + 2,
      title: 'We miss you! 💙',
      body: 'Your streak was reset, but it\'s never too late to start fresh. Come back and check in!',
      notificationDetails: notificationDetails,
    );
  }
}

extension on DateTime {
  int get dayOfYear {
    final first = DateTime(year, 1, 1);
    return difference(first).inDays + 1;
  }
}
