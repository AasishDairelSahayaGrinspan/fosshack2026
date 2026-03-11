import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../theme/theme_provider.dart';
import '../widgets/gradient_background.dart';
import '../widgets/doodle_refresh.dart';
import '../services/auth_service.dart';
import '../services/user_preferences_service.dart';
import 'login_screen.dart';

/// Profile Screen with settings and theme toggle.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GradientBackground(
      child: SafeArea(
        child: DoodleRefresh(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ─── Header ───
                Text(
                  'Your Space',
                  style: AppTypography.heroHeadingC(context),
                ).animate().fadeIn(
                  duration: const Duration(milliseconds: 600),
                  curve: AppTheme.gentleCurve,
                ),

                const SizedBox(height: 6),
                Text(
                  'Settings & preferences',
                  style: AppTypography.subtitleC(context),
                ).animate().fadeIn(
                  duration: const Duration(milliseconds: 600),
                  curve: AppTheme.gentleCurve,
                ),

                const SizedBox(height: 32),

                // ─── Avatar Card ───
                _buildProfileCard(context)
                    .animate(delay: const Duration(milliseconds: 150))
                    .fadeIn(
                      duration: const Duration(milliseconds: 500),
                      curve: AppTheme.gentleCurve,
                    ),

                const SizedBox(height: 24),

                // ─── Settings Section ───
                Text('Settings', style: AppTypography.sectionHeadingC(context))
                    .animate(delay: const Duration(milliseconds: 250))
                    .fadeIn(duration: const Duration(milliseconds: 400)),

                const SizedBox(height: 14),

                // Theme toggle
                _buildSettingsTile(
                      context,
                      icon: isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      title: 'Appearance',
                      subtitle: isDark ? 'Dark mode' : 'Light mode',
                      trailing: Switch.adaptive(
                        value: isDark,
                        onChanged: (_) {
                          _themeProvider.toggleTheme();
                          setState(() {});
                        },
                        activeTrackColor: AppColors.softIndigo,
                        activeThumbColor: Colors.white,
                        inactiveThumbColor: AppColors.softIndigo.withValues(
                          alpha: 0.6,
                        ),
                        inactiveTrackColor: AppColors.dividerColor(context),
                      ),
                    )
                    .animate(delay: const Duration(milliseconds: 300))
                    .fadeIn(duration: const Duration(milliseconds: 400)),

                const SizedBox(height: 8),

                _buildSettingsTile(
                      context,
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Gentle reminders',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.tertiary(context),
                      ),
                    )
                    .animate(delay: const Duration(milliseconds: 350))
                    .fadeIn(duration: const Duration(milliseconds: 400)),

                const SizedBox(height: 8),

                _buildSettingsTile(
                      context,
                      icon: Icons.people_outline_rounded,
                      title: 'Community',
                      subtitle: 'Participation settings',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.tertiary(context),
                      ),
                    )
                    .animate(delay: const Duration(milliseconds: 400))
                    .fadeIn(duration: const Duration(milliseconds: 400)),

                const SizedBox(height: 8),

                _buildSettingsTile(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'About Unravel',
                      subtitle: 'Version 1.0.0',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.tertiary(context),
                      ),
                    )
                    .animate(delay: const Duration(milliseconds: 450))
                    .fadeIn(duration: const Duration(milliseconds: 400)),

                const SizedBox(height: 8),

                // Logout
                GestureDetector(
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    await AuthService().logout();
                    if (!mounted) return;
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: _buildSettingsTile(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Log out',
                    subtitle: 'Sign out of your account',
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.tertiary(context),
                    ),
                  ),
                )
                    .animate(delay: const Duration(milliseconds: 500))
                    .fadeIn(duration: const Duration(milliseconds: 400)),

                const SizedBox(height: 32),

                // ─── Quote ───
                Center(
                      child: Text(
                        '"The quieter you become,\nthe more you can hear."',
                        style: AppTypography.emotionalTextC(context),
                        textAlign: TextAlign.center,
                      ),
                    )
                    .animate(delay: const Duration(milliseconds: 500))
                    .fadeIn(duration: const Duration(milliseconds: 500)),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final prefs = UserPreferencesService();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.cardBorder(context), width: 0.8),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.softIndigo.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.softIndigo.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                prefs.getAvatarUrl(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.card(context),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.softIndigo.withValues(alpha: 0.5),
                      size: 28,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prefs.displayName,
                  style: AppTypography.sectionHeadingC(context),
                ),
                const SizedBox(height: 2),
                Text(
                  'Taking it one day at a time.',
                  style: AppTypography.captionC(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.cardBorder(context), width: 0.8),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.softIndigo.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: AppColors.softIndigo, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.uiLabelC(context)),
                Text(subtitle, style: AppTypography.captionC(context)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
