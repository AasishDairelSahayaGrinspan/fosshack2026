import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
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
/// Frosted glass card with email/password auth.
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
  void initState() {
    super.initState();
    // On web, check if we're returning from an OAuth callback
    if (kIsWeb) {
      _handleOAuthCallbackOnWeb();
    }
  }

  /// Handle OAuth callback on web platform after redirect from OAuth provider.
  /// Automatically completes login if session was established.
  Future<void> _handleOAuthCallbackOnWeb() async {
    try {
      // Check if user is already authenticated after OAuth redirect
      await Future.delayed(const Duration(milliseconds: 500));
      
      final isLoggedIn = await AuthService().isLoggedIn();
      if (isLoggedIn && mounted) {
        developer.log('OAuth callback: User authenticated successfully');
        setState(() {
          _isVerifying = false;
          _showSuccess = true;
        });
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) {
          _navigateAfterAuth();
        }
      }
    } catch (e) {
      developer.log('OAuth callback handling error: $e');
      // Not an error - user might not have completed OAuth flow
    }
  }

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
      developer.log('Guest login error: $e');
      if (!mounted) return;
      final errorStr = e.toString().toLowerCase();
      String message = 'Guest login failed. Please try again.';
      if (errorStr.contains('network') || errorStr.contains('socket')) {
        message = 'Network error. Check your connection and try again.';
      } else if (errorStr.contains('project') || errorStr.contains('endpoint')) {
        message = 'Server configuration issue. Please contact support.';
      }
      setState(() {
        _isVerifying = false;
        _errorMessage = message;
      });
    }
  }

  Future<void> _onGoogleLogin() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    try {
      await AuthService().oAuthLogin(enums.OAuthProvider.google);
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _showSuccess = true;
      });
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      _navigateAfterAuth();
    } catch (e) {
      developer.log('Google OAuth error: $e');
      if (!mounted) return;
      final errorStr = e.toString().toLowerCase();
      String message = 'Google login failed. Please try again.';
      if (errorStr.contains('network') || errorStr.contains('socket')) {
        message = 'Network error. Check your connection and try again.';
      } else if (errorStr.contains('cancel')) {
        message = 'Google login was cancelled.';
      } else if (errorStr.contains('redirect') || errorStr.contains('uri')) {
        message = 'OAuth redirect error. Please ensure Google OAuth is enabled in Appwrite.';
      } else if (errorStr.contains('oauth') || errorStr.contains('provider')) {
        message = 'Google OAuth is not configured. Please check Appwrite settings.';
      }
      setState(() {
        _isVerifying = false;
        _errorMessage = message;
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

                                PillButton(
                                  label: 'Continue with Google',
                                  width: double.infinity,
                                  icon: _buildGoogleLogo(),
                                  backgroundColor: Colors.white,
                                  borderColor: AppColors.inputBorder,
                                  onTap: _onGoogleLogin,
                                ),
                                const SizedBox(height: 12),

                                const SizedBox(height: 8),
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

                                const SizedBox(height: 20),

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
                                        'or use email',
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

  // ─── Google Logo Builder ───
  Widget _buildGoogleLogo() {
    return Image.asset(
      'assets/google_icon.png',
      width: 20,
      height: 20,
      fit: BoxFit.contain,
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
                    style: AppTypography.caption(color: AppColors.softIndigo),
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
            Padding(padding: const EdgeInsets.only(right: 12), child: suffix),
        ],
      ),
    );
  }
}
