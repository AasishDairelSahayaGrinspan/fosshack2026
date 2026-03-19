import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../theme/theme_provider.dart';
import '../widgets/gradient_background.dart';
import '../widgets/doodle_refresh.dart';
import '../models/avatar_config.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/user_preferences_service.dart';
import '../services/notification_service.dart';
import '../widgets/avatar_renderer.dart';
import 'avatar_customization_screen.dart';
import 'login_screen.dart';

/// Profile Screen with settings and theme toggle.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ThemeProvider _themeProvider = ThemeProvider();
  int _streakDays = 0;
  int _journalCount = 0;
  bool _isEditingName = false;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    final db = DatabaseService();
    try {
      final streak = await db.getOrCreateStreak(user.$id);
      final journals = await db.getJournalEntries(user.$id, limit: 1000);
      if (!mounted) return;
      setState(() {
        _streakDays = (streak.data['currentStreak'] as num?)?.toInt() ?? 0;
        _journalCount = journals.rows.length;
      });
    } catch (_) {}
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;
    await AuthService().updateName(newName);
    UserPreferencesService().name = newName;
    await UserPreferencesService().saveToRemote();
    if (mounted) {
      setState(() => _isEditingName = false);
    }
  }

  void _showCommunityDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Community Participation', style: AppTypography.heroHeadingC(context)),
              const SizedBox(height: 8),
              Text('Share your recovery scores and mood trends anonymously with the Unravel community.', style: AppTypography.captionC(context)),
              const SizedBox(height: 24),
              ListTile(
                title: Text('Public - Share insights', style: AppTypography.uiLabelC(context)),
                leading: const Icon(Icons.public_rounded, color: AppColors.softIndigo),
                trailing: UserPreferencesService().communityPreference == 'yes' ? const Icon(Icons.check_circle, color: AppColors.sageGreen) : null,
                onTap: () async {
                  UserPreferencesService().communityPreference = 'yes';
                  await UserPreferencesService().saveToRemote();
                  if (mounted) setState(() {});
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Private - Just for me', style: AppTypography.uiLabelC(context)),
                leading: Icon(Icons.lock_outline_rounded, color: AppColors.tertiary(context)),
                trailing: UserPreferencesService().communityPreference != 'yes' ? const Icon(Icons.check_circle, color: AppColors.sageGreen) : null,
                onTap: () async {
                  UserPreferencesService().communityPreference = 'no';
                  await UserPreferencesService().saveToRemote();
                  if (mounted) setState(() {});
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showIntendedUseDialog(BuildContext context) {
    final prefs = UserPreferencesService();
    final Set<String> selected = Set.from(prefs.concerns);
    final List<Map<String, dynamic>> allConcerns = [
      {'label': 'Stress', 'icon': Icons.bolt_rounded},
      {'label': 'Sleep', 'icon': Icons.nightlight_outlined},
      {'label': 'Anxiety', 'icon': Icons.waves_rounded},
      {'label': 'Focus', 'icon': Icons.center_focus_strong_outlined},
      {'label': 'Healing', 'icon': Icons.favorite_outline_rounded},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0, right: 24.0, top: 24.0,
                bottom: MediaQuery.of(context).padding.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Goals', style: AppTypography.heroHeadingC(context)),
                  const SizedBox(height: 8),
                  Text('Select all the areas you want to focus on.', style: AppTypography.captionC(context)),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: allConcerns.map((c) {
                      final label = c['label'] as String;
                      final isSelected = selected.contains(label);
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              selected.remove(label);
                            } else {
                              selected.add(label);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: AppTheme.fadeInDuration,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.softIndigo.withValues(alpha: 0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.softIndigo : AppColors.dividerColor(context),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(c['icon'] as IconData, size: 18, color: isSelected ? AppColors.softIndigo : AppColors.tertiary(context)),
                              const SizedBox(width: 8),
                              Text(label, style: AppTypography.buttonText(color: isSelected ? AppColors.softIndigo : AppColors.primary(context))),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.softIndigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        prefs.concerns = selected.toList();
                        await prefs.saveToRemote();
                        if (mounted) setState(() {});
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text('Save Goals', style: AppTypography.buttonText(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
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

                _buildSettingsTile(
                      context,
                      icon: Icons.people_outline_rounded,
                      title: 'Community',
                      subtitle: UserPreferencesService().communityPreference == 'yes' ? 'Public - Sharing insights' : 'Private',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.tertiary(context),
                      ),
                      onTap: () => _showCommunityDialog(context),
                    )
                    .animate(delay: const Duration(milliseconds: 400))
                    .fadeIn(duration: const Duration(milliseconds: 400)),

                const SizedBox(height: 8),

                _buildSettingsTile(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'Intended Use',
                      subtitle: UserPreferencesService().concerns.isNotEmpty ? UserPreferencesService().concerns.join(', ') : 'Set your goals',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.tertiary(context),
                      ),
                      onTap: () => _showIntendedUseDialog(context),
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

  Widget _buildAvatarWidget(double size) {
    final prefs = UserPreferencesService();
    if (prefs.avatarData != null && prefs.avatarData!.isNotEmpty) {
      return AvatarRenderer(
        config: AvatarConfig.fromJsonString(prefs.avatarData!),
        size: size,
      );
    }
    return Image.network(
      prefs.getAvatarUrl(),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.card(context),
          child: Icon(
            Icons.person_outline_rounded,
            color: AppColors.softIndigo.withValues(alpha: 0.5),
            size: size * 0.45,
          ),
        );
      },
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
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AvatarCustomizationScreen(
                        onSaved: () => setState(() {}),
                      ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
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
                      child: ClipOval(child: _buildAvatarWidget(80)),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.softIndigo,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.card(context), width: 2),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditingName)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              style: AppTypography.sectionHeadingC(context),
                              decoration: InputDecoration(
                                hintText: 'Your name',
                                hintStyle: AppTypography.sectionHeading(
                                  color: AppColors.tertiary(context),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              onSubmitted: (_) => _saveName(),
                            ),
                          ),
                          GestureDetector(
                            onTap: _saveName,
                            child: Icon(
                              Icons.check_rounded,
                              color: AppColors.sageGreen,
                              size: 20,
                            ),
                          ),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          _nameController.text = prefs.displayName;
                          setState(() => _isEditingName = true);
                        },
                        child: Row(
                          children: [
                            Text(
                              prefs.displayName,
                              style: AppTypography.sectionHeadingC(context),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: AppColors.tertiary(context),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      prefs.concerns.isNotEmpty ? prefs.concerns.join(' • ') : 'Taking it one day at a time.',
                      style: AppTypography.captionC(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ─── Stats Row ───
          Row(
            children: [
              _buildStatChip(
                icon: Icons.local_fire_department_outlined,
                label: '$_streakDays day streak',
                color: AppColors.warmCoral,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                icon: Icons.edit_note_rounded,
                label: '$_journalCount entries',
                color: AppColors.sageGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTypography.caption(color: color)
                    .copyWith(fontWeight: FontWeight.w500, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
