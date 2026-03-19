import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../constants/lottie_urls.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/gradient_background.dart';
import '../services/auth_service.dart';
import '../services/user_preferences_service.dart';
import '../services/community_service.dart';
import '../services/database_service.dart';
import 'login_screen.dart';
import 'main_shell.dart';

/// Unravel Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final isLoggedIn = await AuthService().isLoggedIn();
    Widget destination;

    if (isLoggedIn) {
      final user = AuthService().currentUser;
      if (user != null) {
        await DatabaseService().updateStreak(user.$id);
      }
      await UserPreferencesService().loadFromRemote();
      CommunityService().communityPreference =
          UserPreferencesService().communityPreference;
      destination = const MainShell();
    } else {
      destination = const LoginScreen();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: const [AppColors.warmLavender, AppColors.softPeach],
        secondaryColors: const [AppColors.paleLilac, AppColors.cream],
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.25),
                    radius: 1.0,
                    colors: [
                      AppColors.softIndigo.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                        'Unravel',
                        style: AppTypography.heroHeading().copyWith(
                          fontSize: 42,
                          letterSpacing: 1.5,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 900))
                      .slideY(begin: 0.12, end: 0),
                  const SizedBox(height: 12),
                  Text(
                        'Slow down. You\'re safe here.',
                        style: AppTypography.emotionalText(),
                      )
                      .animate(delay: const Duration(milliseconds: 350))
                      .fadeIn(duration: const Duration(milliseconds: 700)),
                ],
              ),
            ),
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Lottie.network(
                    LottieUrls.loading,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: AppColors.softIndigo.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
