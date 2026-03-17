import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// Frosted glass card with social login, phone + OTP flow.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ─── State ───
  bool _showOtp = false;
  bool _isVerifying = false;
  bool _showSuccess = false;
  String? _otpUserId; // Appwrite token userId for OTP verification
  String? _errorMessage;
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final n in _otpFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _onSendOtp() async {
    if (_phoneController.text.length < 10) return;
    setState(() {
      _errorMessage = null;
      _isVerifying = true;
    });
    try {
      final token = await AuthService().sendOtp('+91${_phoneController.text}');
      _otpUserId = token.userId;
      setState(() {
        _isVerifying = false;
        _showOtp = true;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _otpFocusNodes[0].requestFocus();
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Failed to send OTP. Please try again.';
      });
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    // Auto-verify when all 6 digits are entered
    if (_otpControllers.every((c) => c.text.isNotEmpty)) {
      _verifyOtp();
    }
  }

  void _onOtpKeyPress(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6 || _otpUserId == null) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    try {
      await AuthService().verifyOtp(userId: _otpUserId!, otp: otp);
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
      final errorStr = e.toString();
      String errorMsg = 'Invalid OTP. Please try again.';
      if (errorStr.contains('expired')) {
        errorMsg = 'OTP expired. Please request a new code.';
      }
      setState(() {
        _isVerifying = false;
        _errorMessage = errorMsg;
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

                                // ─── Phone / OTP Section ───
                                AnimatedSwitcher(
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
                                  child: _showOtp
                                      ? _buildOtpSection()
                                      : _buildPhoneSection(),
                                ),
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

  // ─── Phone Input Section ───
  Widget _buildPhoneSection() {
    return Column(
      key: const ValueKey('phone'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Phone number input
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusInput),
            border: Border.all(color: AppColors.inputBorder, width: 1),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('+91', style: AppTypography.uiLabelC(context)),
              ),
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: AppColors.dividerColor(context),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: AppTypography.uiLabelC(context),
                  decoration: InputDecoration(
                    hintText: 'Mobile number',
                    hintStyle: AppTypography.uiLabel(
                      color: AppColors.tertiary(context),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PillButton(
          label: 'Send OTP',
          width: double.infinity,
          backgroundColor: AppColors.softIndigo.withValues(alpha: 0.85),
          textColor: Colors.white,
          onTap: _onSendOtp,
        ),
      ],
    );
  }

  // ─── OTP Input Section ───
  Widget _buildOtpSection() {
    return Column(
      key: const ValueKey('otp'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Check your notification for the code',
          style: AppTypography.subtitleC(context),
        ),
        const SizedBox(height: 8),
        Text(
          _phoneController.text.isNotEmpty
              ? '+91 ${_phoneController.text}'
              : '',
          style: AppTypography.captionC(context),
        ),
        const SizedBox(height: 24),

        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Expanded(
              child: Container(
                height: 52,
                margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) => _onOtpKeyPress(index, event),
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: AppTypography.otpDigit(),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                        borderSide: BorderSide(
                          color: AppColors.inputBorder,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                        borderSide: BorderSide(
                          color: AppColors.inputBorder,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                        borderSide: BorderSide(
                          color: AppColors.inputFocusBorder,
                          width: 1.5,
                        ),
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => _onOtpChanged(index, value),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 24),

        // Verify / Loading / Success
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
                  key: const ValueKey('verify'),
                  label: 'Verify',
                  width: double.infinity,
                  backgroundColor: AppColors.softIndigo.withValues(alpha: 0.85),
                  textColor: Colors.white,
                  isLoading: _isVerifying,
                  onTap: _verifyOtp,
                ),
        ),

        const SizedBox(height: 16),

        // Change number link
        GestureDetector(
          onTap: () => setState(() => _showOtp = false),
          child: Text(
            'Change number',
            style: AppTypography.caption(color: AppColors.softIndigo),
          ),
        ),
      ],
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
