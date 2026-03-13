import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite/appwrite.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/gradient_background.dart';
import '../widgets/frosted_glass_card.dart';
import '../widgets/pill_button.dart';
import '../services/auth_service.dart';
import 'onboarding_screen.dart';

/// Unravel Login Screen
/// "Welcome back." / "Create your space." — spa-like entry experience.
/// Frosted glass card with social login and email/password auth.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ─── State ───
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _showSuccess = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _parseAuthError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (e is AppwriteException) {
      final m = e.message?.toLowerCase() ?? '';
      if (m.contains('already exists') || m.contains('user_already_exists')) {
        return 'An account with this email already exists.';
      }
      if (m.contains('invalid credentials') || m.contains('user_invalid_credentials')) {
        return 'Invalid email or password.';
      }
      if (m.contains('rate limit') || m.contains('too many')) {
        return 'Too many attempts. Please wait a moment.';
      }
      if (e.message != null && e.message!.isNotEmpty) {
        return e.message!;
      }
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Network error. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _onEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter email and password.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await AuthService().emailLogin(email: email, password: password);
      if (!mounted) return;
      setState(() { _isLoading = false; _showSuccess = true; });
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      _navigateToHome();
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = _parseAuthError(e); });
    }
  }

  Future<void> _onEmailSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await AuthService().emailSignUp(email: email, password: password, name: name);
      if (!mounted) return;
      setState(() { _isLoading = false; _showSuccess = true; });
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      _navigateToHome();
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = _parseAuthError(e); });
    }
  }

  Future<void> _onForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Enter your email first, then tap Forgot password.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await AuthService().forgotPassword(email);
      if (!mounted) return;
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recovery email sent to $email', style: AppTypography.body(color: Colors.white)),
          backgroundColor: AppColors.sageGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = _parseAuthError(e); });
    }
  }

  Future<void> _onSocialLogin(String provider) async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final oauthProvider = provider == 'google'
          ? enums.OAuthProvider.google
          : enums.OAuthProvider.apple;
      await AuthService().oAuthLogin(oauthProvider);
      if (!mounted) return;
      setState(() { _isLoading = false; _showSuccess = true; });
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      _navigateToHome();
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = _parseAuthError(e); });
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreen(),
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
      body: GradientBackground(
        colors: const [AppColors.mistBlue, AppColors.paleLilac],
        secondaryColors: const [AppColors.cream, AppColors.warmLavender],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: AppTheme.screenPadding,
            child: SizedBox(
              height: screenHeight - MediaQuery.of(context).padding.top - 32,
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
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _isSignUp ? 'Create your space.' : 'Welcome back.',
                                key: ValueKey<bool>(_isSignUp),
                                style: AppTypography.heroHeadingC(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _isSignUp
                                    ? 'A quiet place, just for you.'
                                    : 'We saved your quiet place.',
                                key: ValueKey<String>(_isSignUp ? 'signup' : 'login'),
                                style: AppTypography.subtitleC(context),
                              ),
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

                            // ─── Email / Password Section ───
                            _buildEmailSection(),
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
    );
  }

  // ─── Email / Password Section ───
  Widget _buildEmailSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name field (sign-up only)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: AppTheme.defaultCurve,
          child: _isSignUp
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildInputField(
                    controller: _nameController,
                    hint: 'Your name',
                    icon: Icons.person_outline_rounded,
                    textInputType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Email field
        _buildInputField(
          controller: _emailController,
          hint: 'Email',
          icon: Icons.email_outlined,
          textInputType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),

        // Password field with visibility toggle
        _buildInputField(
          controller: _passwordController,
          hint: 'Password',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _isSignUp ? _onEmailSignUp() : _onEmailLogin(),
          suffix: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.tertiary(context),
                size: 20,
              ),
            ),
          ),
        ),

        // Forgot password (login mode only)
        if (!_isSignUp)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: _onForgotPassword,
                child: Text(
                  'Forgot password?',
                  style: AppTypography.caption(color: AppColors.softIndigo),
                ),
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Submit button / Success
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
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
              : PillButton(
                  key: const ValueKey('submit'),
                  label: _isSignUp ? 'Create Account' : 'Log In',
                  width: double.infinity,
                  backgroundColor: AppColors.softIndigo.withValues(alpha: 0.85),
                  textColor: Colors.white,
                  isLoading: _isLoading,
                  onTap: _isSignUp ? _onEmailSignUp : _onEmailLogin,
                ),
        ),

        const SizedBox(height: 16),

        // Toggle sign-up / log-in
        GestureDetector(
          onTap: () => setState(() {
            _isSignUp = !_isSignUp;
            _errorMessage = null;
          }),
          child: Text.rich(
            TextSpan(
              text: _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
              style: AppTypography.captionC(context),
              children: [
                TextSpan(
                  text: _isSignUp ? 'Log in' : 'Sign up',
                  style: AppTypography.caption(color: AppColors.softIndigo)
                      .copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? textInputType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffix,
    void Function(String)? onSubmitted,
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
            padding: const EdgeInsets.only(left: 14),
            child: Icon(icon, color: AppColors.tertiary(context), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: textInputType,
              textInputAction: textInputAction,
              obscureText: obscureText,
              onSubmitted: onSubmitted,
              style: AppTypography.uiLabelC(context),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTypography.uiLabel(
                  color: AppColors.tertiary(context),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (suffix != null) suffix,
        ],
      ),
    );
  }

  // ─── Google Icon ───
  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

/// Simple Google "G" logo painter
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Blue arc
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.butt;

    // Red arc
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.butt;

    // Yellow arc
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.butt;

    // Green arc
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.8);

    // Draw arcs (approximate G shape)
    canvas.drawArc(rect, -0.6, -1.2, false, redPaint);
    canvas.drawArc(rect, -1.8, -1.0, false, yellowPaint);
    canvas.drawArc(rect, -2.8, -1.0, false, greenPaint);
    canvas.drawArc(rect, -0.6, 0.9, false, bluePaint);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.5, h * 0.42, w * 0.42, h * 0.16),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
