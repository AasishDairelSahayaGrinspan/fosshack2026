import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/gradient_background.dart';
import '../services/community_service.dart';
import '../services/user_preferences_service.dart';
import 'main_shell.dart';

/// Community Onboarding — optional question about community participation.
/// "Would you like to participate in the community?"
class CommunityOnboardingScreen extends StatefulWidget {
  const CommunityOnboardingScreen({super.key});

  @override
  State<CommunityOnboardingScreen> createState() =>
      _CommunityOnboardingScreenState();
}

class _CommunityOnboardingScreenState
    extends State<CommunityOnboardingScreen> {
  int _selectedIndex = -1;
  final CommunityService _service = CommunityService();

  static const List<Map<String, dynamic>> _options = [
    {
      'label': 'Yes',
      'description': 'I\'d love to share and connect.',
      'icon': Icons.favorite_outline_rounded,
      'value': 'yes',
    },
    {
      'label': 'Just browsing',
      'description': 'I\'ll read along quietly.',
      'icon': Icons.visibility_outlined,
      'value': 'browsing',
    },
    {
      'label': 'No thanks',
      'description': 'I prefer to keep to myself.',
      'icon': Icons.person_outline_rounded,
      'value': 'no',
    },
  ];

  Future<void> _continue() async {
    if (_selectedIndex < 0) return;

    _service.communityPreference =
        _options[_selectedIndex]['value'] as String;
    UserPreferencesService().communityPreference = _service.communityPreference;
    try {
      await UserPreferencesService().saveToRemote();
    } catch (e, st) {
      developer.log('Failed to save community preference', name: 'CommunityOnboarding', error: e, stackTrace: st);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainShell(),
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
        colors: const [AppColors.cream, AppColors.paleLilac],
        secondaryColors: const [AppColors.lightBlush, AppColors.cream],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),

                // ─── Heading ───
                Text(
                  'One more\ngentle question.',
                  style: AppTypography.heroHeadingC(context),
                )
                    .animate()
                    .fadeIn(
                      duration: const Duration(milliseconds: 700),
                      curve: AppTheme.gentleCurve,
                    )
                    .slideY(
                      begin: 0.1,
                      end: 0,
                      duration: const Duration(milliseconds: 700),
                      curve: AppTheme.gentleCurve,
                    ),

                const SizedBox(height: 12),

                Text(
                  'Would you like to participate in the community?',
                  style: AppTypography.subtitleC(context),
                )
                    .animate(delay: const Duration(milliseconds: 200))
                    .fadeIn(
                      duration: const Duration(milliseconds: 500),
                      curve: AppTheme.gentleCurve,
                    ),

                const SizedBox(height: 36),

                // ─── Options ───
                ...List.generate(_options.length, (i) {
                  final option = _options[i];
                  final isSelected = _selectedIndex == i;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = i),
                      child: AnimatedContainer(
                        duration: AppTheme.fadeInDuration,
                        curve: AppTheme.defaultCurve,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.softIndigo.withValues(alpha: 0.1)
                              : AppColors.card(context),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusCard),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.softIndigo.withValues(alpha: 0.4)
                                : AppColors.dividerColor(context),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.softIndigo
                                        .withValues(alpha: 0.1),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : AppColors.subtleShadow,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: AppTheme.fadeInDuration,
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: isSelected
                                    ? AppColors.softIndigo
                                        .withValues(alpha: 0.15)
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
                                    style: AppTypography.buttonText(
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
                            // Selection indicator
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
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate(delay: Duration(milliseconds: 300 + i * 100))
                        .fadeIn(
                          duration: const Duration(milliseconds: 400),
                          curve: AppTheme.gentleCurve,
                        )
                        .slideY(
                          begin: 0.06,
                          end: 0,
                          duration: const Duration(milliseconds: 400),
                          curve: AppTheme.gentleCurve,
                        ),
                  );
                }),

                const SizedBox(height: 8),

                Text(
                  'You can always change this later.',
                  style: AppTypography.captionC(context),
                )
                    .animate(delay: const Duration(milliseconds: 700))
                    .fadeIn(duration: const Duration(milliseconds: 400)),

                const Spacer(flex: 2),

                // ─── Continue Button ───
                GestureDetector(
                  onTap: _selectedIndex >= 0 ? () => _continue() : null,
                  child: AnimatedContainer(
                    duration: AppTheme.fadeInDuration,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _selectedIndex >= 0
                          ? AppColors.softIndigo.withValues(alpha: 0.85)
                          : AppColors.dividerColor(context).withValues(alpha: 0.5),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusButton),
                    ),
                    child: Center(
                      child: Text(
                        'Continue',
                        style: AppTypography.buttonText(
                          color: _selectedIndex >= 0
                              ? Colors.white
                              : AppColors.tertiary(context),
                        ),
                      ),
                    ),
                  ),
                )
                    .animate(delay: const Duration(milliseconds: 800))
                    .fadeIn(duration: const Duration(milliseconds: 400)),

                const SizedBox(height: 16),

                // Skip option
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      _service.communityPreference = 'yes';
                      await _continue();
                    },
                    child: Text(
                      'Skip for now',
                      style: AppTypography.caption(
                        color: AppColors.softIndigo,
                      ),
                    ),
                  ),
                )
                    .animate(delay: const Duration(milliseconds: 900))
                    .fadeIn(duration: const Duration(milliseconds: 400)),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
