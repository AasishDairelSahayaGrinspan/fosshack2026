import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/local_data_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDataService().init();
  await NotificationService().init();
  await ThemeProvider().loadSavedTheme();
  // Schedule gentle engagement notifications for today.
  NotificationService().scheduleEngagementNotifications();
  // Reset inactivity reminder on each launch (48h from now).
  NotificationService().scheduleInactivityReminder();
  // Schedule default sleep & breathing reminders.
  NotificationService().scheduleSleepReminder();
  NotificationService().scheduleBreathingReminder();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const UnravelApp());
}

class UnravelApp extends StatefulWidget {
  const UnravelApp({super.key});

  @override
  State<UnravelApp> createState() => _UnravelAppState();
}

class _UnravelAppState extends State<UnravelApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});

    // Update system UI for dark/light mode
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            _themeProvider.isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            _themeProvider.isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unravel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
