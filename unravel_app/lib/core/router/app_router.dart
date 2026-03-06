import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_shell.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/mood/presentation/screens/home_screen.dart';
import '../../features/mood/presentation/screens/mood_checkin_screen.dart';
import '../../features/mood/presentation/screens/mood_history_screen.dart';
import '../../features/journal/presentation/screens/journal_screen.dart';
import '../../features/journal/presentation/screens/journal_entry_screen.dart';
import '../../features/breathing/presentation/screens/breathing_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/recovery/presentation/screens/recovery_detail_screen.dart';
import '../../features/community/presentation/screens/friends_screen.dart';
import '../../features/community/presentation/screens/invite_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/music/presentation/screens/music_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';

final noAdviceModeProvider = StateProvider<bool>((ref) => false);

final appRouterProvider = Provider<GoRouter>((ref) {
  final noAdviceMode = ref.watch(noAdviceModeProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      if (noAdviceMode) {
        const blockedPaths = ['/breathing', '/music'];
        if (blockedPaths.any((p) => state.matchedLocation.startsWith(p))) {
          return '/home';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/mood', builder: (_, __) => const MoodCheckinScreen()),
          GoRoute(path: '/mood/history', builder: (_, __) => const MoodHistoryScreen()),
          GoRoute(path: '/journal', builder: (_, __) => const JournalScreen()),
          GoRoute(path: '/journal/new', builder: (_, __) => const JournalEntryScreen()),
          GoRoute(path: '/breathing', builder: (_, __) => const BreathingScreen()),
          GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/recovery', builder: (_, __) => const RecoveryDetailScreen()),
          GoRoute(path: '/community', builder: (_, __) => const FriendsScreen()),
          GoRoute(path: '/community/invite', builder: (_, __) => const InviteScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/music', builder: (_, __) => const MusicScreen()),
          GoRoute(path: '/notifications/settings', builder: (_, __) => const NotificationSettingsScreen()),
        ],
      ),
    ],
  );
});
