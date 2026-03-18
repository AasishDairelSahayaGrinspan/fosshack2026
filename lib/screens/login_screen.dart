import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:appwrite/enums.dart' as enums;
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/gradient_background.dart';
import '../widgets/frosted_glass_card.dart';
import '../widgets/pill_button.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import '../services/user_preferences_service.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';

/// Unravel Login Screen
/// "Welcome back." — spa-like entry experience.
/// Frosted glass card with social login, email/password auth.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ─── State ───
  bool _isSignUp = false;
  bool _isVerifying = false;
  bool _showSuccess = false;
  String? _errorMessage;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }

    if (_isSignUp && _nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your name.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isVerifying = true;
    });

    try {
      if (_isSignUp) {
        await AuthService().signup(
          email: email,
          password: password,
          name: _nameController.text.trim(),
        );
      } else {
        await AuthService().login(email: email, password: password);
      }
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _showSuccess = true;
      });
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      _navigateAfterAuth();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _onGuestLogin() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    try {
      await AuthService().guestLogin();
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _showSuccess = true;
      });
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      _navigateAfterAuth();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Guest login failed. Please try again.';
      });
    }
  }

  Future<void> _onSocialLogin(String provider) async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    try {
      final oauthProvider = provider == 'google'
          ? enums.OAuthProvider.google
          : enums.OAuthProvider.apple;
      await AuthService().oAuthLogin(oauthProvider);
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _showSuccess = true;
      });
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      _navigateAfterAuth();
    } catch (e) {
      developer.log('Login screen caught error: ${e.runtimeType}: $e');
      if (!mounted) return;
      final errorStr = e.toString();
      String errorMsg = 'Login failed. Please try again.';
      if (errorStr.contains('Network') || errorStr.contains('socket')) {
        errorMsg = 'Network error. Check your connection and try again.';
      } else if (errorStr.contains('401') ||
          errorStr.contains('unauthorized')) {
        errorMsg = 'Google OAuth not configured. Contact support.';
      } else if (errorStr.contains('Invalid OAuth2 Response')) {
        errorMsg = 'OAuth redirect failed. Check Appwrite platform config.';
      } else if (errorStr.contains('CANCELED') || errorStr.contains('cancel')) {
        errorMsg = 'Login was cancelled.';
      }
      setState(() {
        _isVerifying = false;
        _errorMessage = errorMsg;
      });
    }
  }

  Future<void> _navigateAfterAuth() async {
    await UserPreferencesService().loadFromRemote();
    CommunityService().communityPreference =
        UserPreferencesService().communityPreference;

    if (!mounted) return;
    final hasCompletedOnboarding =
        UserPreferencesService().hasCompletedOnboarding;
    final destination = hasCompletedOnboarding
        ? const MainShell()
        : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          GradientBackground(
            colors: const [AppColors.mistBlue, AppColors.paleLilac],
            secondaryColors: const [AppColors.cream, AppColors.warmLavender],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: AppTheme.screenPadding,
                child: SizedBox(
                  height:
                      screenHeight - MediaQuery.of(context).padding.top - 32,
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // ─── Frosted Glass Card ───
                      FrostedGlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 32,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Heading
                                Text(
                                  'Welcome back.',
                                  style: AppTypography.heroHeadingC(context),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'We saved your quiet place.',
                                  style: AppTypography.subtitleC(context),
                                ),
                                const SizedBox(height: 32),

                                // ─── Social Login Buttons ───
                                PillButton(
                                  label: 'Continue with Google',
                                  width: double.infinity,
                                  icon: _buildGoogleIcon(),
                                  backgroundColor: Colors.white,
                                  borderColor: AppColors.inputBorder,
                                  onTap: () => _onSocialLogin('google'),
                                ),
                                const SizedBox(height: 12),
                                PillButton(
                                  label: 'Continue with Apple',
                                  width: double.infinity,
                                  icon: Icon(
                                    Icons.apple,
                                    color: AppColors.primary(context),
                                    size: 20,
                                  ),
                                  backgroundColor: Colors.white,
                                  borderColor: AppColors.inputBorder,
                                  onTap: () => _onSocialLogin('apple'),
                                ),

                                const SizedBox(height: 12),
                                PillButton(
                                  label: 'Continue as Guest',
                                  width: double.infinity,
                                  icon: Icon(
                                    Icons.person_outline_rounded,
                                    color: AppColors.tertiary(context),
                                    size: 20,
                                  ),
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.4,
                                  ),
                                  borderColor: AppColors.inputBorder,
                                  onTap: _onGuestLogin,
                                ),

                                const SizedBox(height: 24),

                                // ─── Divider ───
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: AppColors.dividerColor(context),
                                        thickness: 0.8,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'or',
                                        style: AppTypography.captionC(context),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: AppColors.dividerColor(context),
                                        thickness: 0.8,
                                      ),
                                    ),
                                  ],
                                ),

                                // ─── Error Message ───
                                if (_errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Text(
                                      _errorMessage!,
                                      style: AppTypography.caption(
                                        color: AppColors.warmCoral,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),

                                const SizedBox(height: 24),

                                // ─── Email/Password Section ───
                                _buildEmailAuthSection(),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(
                            duration: const Duration(milliseconds: 700),
                            curve: AppTheme.gentleCurve,
                          )
                          .slideY(
                            begin: 0.08,
                            end: 0,
                            duration: const Duration(milliseconds: 700),
                            curve: AppTheme.gentleCurve,
                          ),

                      const Spacer(flex: 3),

                      // ─── Footer ───
                      Text(
                            'By continuing, you agree to our Terms & Privacy Policy',
                            style: AppTypography.captionC(context),
                            textAlign: TextAlign.center,
                          )
                          .animate(delay: const Duration(milliseconds: 500))
                          .fadeIn(duration: const Duration(milliseconds: 500)),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Email/Password Auth Section ───
  Widget _buildEmailAuthSection() {
    return AnimatedSwitcher(
      duration: AppTheme.fadeInDuration,
      switchInCurve: AppTheme.defaultCurve,
      switchOutCurve: AppTheme.defaultCurve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _showSuccess
          ? const Icon(
                  Icons.check_circle_rounded,
                  key: ValueKey('success'),
                  color: AppColors.sageGreen,
                  size: 48,
                )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: const Duration(milliseconds: 300))
          : Column(
              key: ValueKey<bool>(_isSignUp),
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name field (sign up only)
                if (_isSignUp) ...[
                  _buildInputField(
                    controller: _nameController,
                    hintText: 'Your name',
                    icon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 12),
                ],

                // Email field
                _buildInputField(
                  controller: _emailController,
                  hintText: 'Email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                // Password field
                _buildInputField(
                  controller: _passwordController,
                  hintText: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffix: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.tertiary(context),
                      size: 18,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Submit button
                PillButton(
                  label: _isSignUp ? 'Create Account' : 'Log In',
                  width: double.infinity,
                  backgroundColor: AppColors.softIndigo.withValues(alpha: 0.85),
                  textColor: Colors.white,
                  isLoading: _isVerifying,
                  onTap: _onEmailAuth,
                ),

                const SizedBox(height: 16),

                // Toggle sign up / login
                GestureDetector(
                  onTap: () => setState(() {
                    _isSignUp = !_isSignUp;
                    _errorMessage = null;
                  }),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Log in'
                        : 'Don\'t have an account? Sign up',
                    style:
                        AppTypography.caption(color: AppColors.softIndigo),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        border: Border.all(color: AppColors.inputBorder, width: 1),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(icon, color: AppColors.tertiary(context), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              style: AppTypography.uiLabelC(context),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTypography.uiLabel(
                  color: AppColors.tertiary(context),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: suffix,
            ),
        ],
      ),
    );
  }

  // ─── Google Icon ───
  Widget _buildGoogleIcon() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

/// Multicolor Google "G" logo painter.
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const Color _blue = Color(0xFF4285F4);
  static const Color _red = Color(0xFFEA4335);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _green = Color(0xFF34A853);

  double _deg(double d) => d * (math.pi / 180);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint arcPaint(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, _deg(-45), _deg(85), false, arcPaint(_blue));
    canvas.drawArc(rect, _deg(40), _deg(95), false, arcPaint(_red));
    canvas.drawArc(rect, _deg(135), _deg(95), false, arcPaint(_yellow));
    canvas.drawArc(rect, _deg(230), _deg(95), false, arcPaint(_green));

    final barPaint = Paint()
      ..color = _blue
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.50,
        size.height * 0.42,
        size.width * 0.36,
        stroke * 0.55,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
