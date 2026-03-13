import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/gradient_background.dart';
import '../services/auth_service.dart';
import '../services/user_preferences_service.dart';
import 'login_screen.dart';
import 'main_shell.dart';

/// Unravel Splash Screen
/// Animated gradient background, floating abstract shapes,
/// "Unravel" title and "Slow down. You're safe here." subtitle.
/// Auto-navigates to login after a calm 3-second pause.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(milliseconds: 3500));
    if (!mounted) return;

    // Check if user is already logged in
    final isLoggedIn = await AuthService().isLoggedIn();
    Widget destination;

    if (isLoggedIn) {
      // Load user preferences from Appwrite (non-fatal on failure)
      try {
        await UserPreferencesService().loadFromRemote();
      } catch (_) {
        // Permission error or network issue — continue with defaults
      }
      destination = const MainShell();
    } else {
      destination = const LoginScreen();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: AppTheme.defaultCurve,
            ),
            child: child,
          );
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
            // ─── Floating Lottie Shapes ───
            Positioned.fill(
              child: Opacity(
                opacity: 0.6,
                child: Lottie.asset(
                  'assets/animations/floating_shapes.json',
                  fit: BoxFit.cover,
                  repeat: true,
                ),
              ),
            ),

            // ─── Centered Title Content ───
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Name
                  Text(
                        'Unravel',
                        style: AppTypography.heroHeading().copyWith(
                          fontSize: 42,
                          letterSpacing: 1.5,
                        ),
                      )
                      .animate()
                      .fadeIn(
                        duration: const Duration(milliseconds: 1000),
                        curve: AppTheme.gentleCurve,
                      )
                      .slideY(
                        begin: 0.15,
                        end: 0,
                        duration: const Duration(milliseconds: 1000),
                        curve: AppTheme.gentleCurve,
                      ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                        'Slow down. You\'re safe here.',
                        style: AppTypography.emotionalText(),
                      )
                      .animate(delay: const Duration(milliseconds: 600))
                      .fadeIn(
                        duration: const Duration(milliseconds: 800),
                        curve: AppTheme.gentleCurve,
                      )
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: const Duration(milliseconds: 800),
                        curve: AppTheme.gentleCurve,
                      ),
                ],
              ),
            ),

            // ─── Bottom Subtle Indicator ───
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child:
                  Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.textTertiary.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                      )
                      .animate(delay: const Duration(milliseconds: 1200))
                      .fadeIn(duration: const Duration(milliseconds: 600)),
            ),
          ],
        ),
      ),
    );
  }
}
