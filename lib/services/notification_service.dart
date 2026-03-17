import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
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

  /// Shows the OTP code as a local notification so the user can see it
  /// without leaving the app.
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
}

