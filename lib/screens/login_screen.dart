import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/gradient_background.dart';
import '../widgets/frosted_glass_card.dart';
import '../widgets/pill_button.dart';
import 'onboarding_screen.dart';

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

  void _onSendOtp() {
    if (_phoneController.text.length >= 10) {
      setState(() => _showOtp = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _otpFocusNodes[0].requestFocus();
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
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _showSuccess = true;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _navigateToHome();
  }

  Future<void> _onSocialLogin(String provider) async {
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _showSuccess = true;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _navigateToHome();
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
        Text('Enter the code we sent you', style: AppTypography.subtitleC(context)),
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
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      borderSide: BorderSide(
                        color: AppColors.inputBorder,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      borderSide: BorderSide(
                        color: AppColors.inputBorder,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
