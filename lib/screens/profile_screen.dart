import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../theme/theme_provider.dart';
import '../widgets/gradient_background.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import '../services/user_preferences_service.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';

/// Profile Screen with settings and theme toggle.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ThemeProvider _themeProvider = ThemeProvider();
  bool _sleepReminder = true;
  bool _breathingReminder = true;

  @override
  void initState() {
    super.initState();
    _loadReminderPrefs();
  }

  Future<void> _loadReminderPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sleepReminder = prefs.getBool('pref_sleep_reminder') ?? true;
      _breathingReminder = prefs.getBool('pref_breathing_reminder') ?? true;
    });
  }

  Future<void> _saveReminderPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  String _communitySubtitle() {
    final pref = CommunityService().communityPreference;
    switch (pref) {
      case 'yes':
        return 'Participating in community';
      case 'browsing':
        return 'Browsing community quietly';
      case 'no':
        return 'Community hidden';
      default:
        return 'Participation settings';
    }
  }

  void _showCommunityPreferenceSheet() {
    final currentPref = CommunityService().communityPreference;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _CommunityPreferenceSheet(
          currentPreference: currentPref,
          onChanged: (newPref) async {
            CommunityService().communityPreference = newPref;
            UserPreferencesService().communityPreference = newPref;
            try {
              await UserPreferencesService().saveToRemote();
            } catch (e, st) {
              developer.log('Failed to save community preference',
                  name: 'ProfileScreen', error: e, stackTrace: st);
            }
            if (mounted) setState(() {});
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GradientBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                      subtitle: 'Open app notification settings',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.tertiary(context),
                      ),
                      onTap: () async {
                        final granted =
                            await NotificationService().requestPermissionIfNeeded();
                        await NotificationService().openAppNotificationSettings();
                        if (granted) {
                          await NotificationService()
                              .showTrackerEnabledGreeting();
                        }
                      },
                    )
                    .animate(delay: const Duration(milliseconds: 350))
                    .fadeIn(duration: const Duration(milliseconds: 400)),

                const SizedBox(height: 8),

                Text('Reminders', style: AppTypography.sectionHeadingC(context))
                    .animate(delay: const Duration(milliseconds: 365))
                    .fadeIn(duration: const Duration(milliseconds: 400)),

                const SizedBox(height: 14),

                _buildSettingsTile(
                      context,
                      icon: Icons.nightlight_outlined,
                      title: 'Sleep Reminder',
                      subtitle: 'Daily at 10pm',
                      trailing: Switch.adaptive(
                        value: _sleepReminder,
                        onChanged: (value) async {
                          setState(() => _sleepReminder = value);
                          await _saveReminderPref('pref_sleep_reminder', value);
                          if (value) {
                            await NotificationService().scheduleSleepReminder();
                          } else {
                            await NotificationService().cancelSleepReminder();
                          }
                        },
                        activeTrackColor: AppColors.softIndigo,
                        activeThumbColor: Colors.white,
                        inactiveThumbColor: AppColors.softIndigo.withValues(alpha: 0.6),
                        inactiveTrackColor: AppColors.dividerColor(context),
                      ),
                    )
                    .animate(delay: const Duration(milliseconds: 375))
                    .fadeIn(duration: const Duration(milliseconds: 400)),

                const SizedBox(height: 8),

                _buildSettingsTile(
                      context,
                      icon: Icons.air_rounded,
                      title: 'Breathing Reminder',
                      subtitle: 'Daily at 2pm',
                      trailing: Switch.adaptive(
                        value: _breathingReminder,
                        onChanged: (value) async {
                          setState(() => _breathingReminder = value);
                          await _saveReminderPref('pref_breathing_reminder', value);
                          if (value) {
                            await NotificationService().scheduleBreathingReminder();
                          } else {
                            await NotificationService().cancelBreathingReminder();
                          }
                        },
                        activeTrackColor: AppColors.softIndigo,
                        activeThumbColor: Colors.white,
                        inactiveThumbColor: AppColors.softIndigo.withValues(alpha: 0.6),
                        inactiveTrackColor: AppColors.dividerColor(context),
                      ),
                    )
                    .animate(delay: const Duration(milliseconds: 425))
                    .fadeIn(duration: const Duration(milliseconds: 400)),

                const SizedBox(height: 8),

                _buildSettingsTile(
                      context,
                      icon: Icons.people_outline_rounded,
                      title: 'Community',
                      subtitle: _communitySubtitle(),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.tertiary(context),
                      ),
                      onTap: _showCommunityPreferenceSheet,
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
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
      ),
    );
  }
}

/// Bottom sheet for changing community participation preference.
class _CommunityPreferenceSheet extends StatefulWidget {
  final String currentPreference;
  final ValueChanged<String> onChanged;

  const _CommunityPreferenceSheet({
    required this.currentPreference,
    required this.onChanged,
  });

  @override
  State<_CommunityPreferenceSheet> createState() =>
      _CommunityPreferenceSheetState();
}

class _CommunityPreferenceSheetState extends State<_CommunityPreferenceSheet> {
  late String _selected;

  static const List<Map<String, dynamic>> _options = [
    {
      'label': 'Yes, I\'d love to',
      'description': 'Share and connect with the community.',
      'icon': Icons.favorite_outline_rounded,
      'value': 'yes',
    },
    {
      'label': 'Just browsing',
      'description': 'Read along quietly without posting.',
      'icon': Icons.visibility_outlined,
      'value': 'browsing',
    },
    {
      'label': 'Hide community',
      'description': 'Remove the community tab entirely.',
      'icon': Icons.person_outline_rounded,
      'value': 'no',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentPreference;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Community Participation',
            style: AppTypography.sectionHeadingC(context),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose how you\'d like to engage.',
            style: AppTypography.captionC(context),
          ),
          const SizedBox(height: 20),

          ..._options.map((option) {
            final value = option['value'] as String;
            final isSelected = _selected == value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _selected = value),
                child: AnimatedContainer(
                  duration: AppTheme.fadeInDuration,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.softIndigo.withValues(alpha: 0.1)
                        : AppColors.card(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.softIndigo.withValues(alpha: 0.4)
                          : AppColors.dividerColor(context),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected
                              ? AppColors.softIndigo.withValues(alpha: 0.15)
                              : AppColors.dividerColor(context)
                                  .withValues(alpha: 0.3),
                        ),
                        child: Icon(
                          option['icon'] as IconData,
                          color: isSelected
                              ? AppColors.softIndigo
                              : AppColors.tertiary(context),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option['label'] as String,
                              style: AppTypography.uiLabel(
                                color: isSelected
                                    ? AppColors.softIndigo
                                    : AppColors.primary(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              option['description'] as String,
                              style: AppTypography.captionC(context),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: AppTheme.fadeInDuration,
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.softIndigo
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.softIndigo
                                : AppColors.dividerColor(context),
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          Text(
            'Changing to "Hide community" will remove the tab. You can re-enable it anytime.',
            style: AppTypography.captionC(context),
          ),
          const SizedBox(height: 16),

          // Save button
          GestureDetector(
            onTap: () {
              widget.onChanged(_selected);
              Navigator.of(context).pop();
              // If community visibility changed, user needs to restart the shell
              if (_selected != widget.currentPreference) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _selected == 'no'
                          ? 'Community tab hidden. Restart the app to apply.'
                          : 'Community preference updated. Restart the app to apply.',
                      style: AppTypography.body(color: Colors.white),
                    ),
                    backgroundColor: AppColors.softIndigo,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                );
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.softIndigo.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              ),
              child: Center(
                child: Text(
                  'Save',
                  style: AppTypography.buttonText(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
