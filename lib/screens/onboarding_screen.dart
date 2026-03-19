import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/gradient_background.dart';
import '../services/user_preferences_service.dart';
import '../services/auth_service.dart';
import 'avatar_customization_screen.dart';
import 'community_onboarding_screen.dart';

/// Multi-step onboarding — 9 pages via PageView.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final UserPreferencesService _prefs = UserPreferencesService();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;

  // Page 1 — gender
  String? _selectedGender;
  static const List<Map<String, dynamic>> _genders = [
    {'label': 'Male', 'icon': Icons.male_rounded},
    {'label': 'Female', 'icon': Icons.female_rounded},
    {'label': 'Other', 'icon': Icons.transgender_rounded},
  ];

  // Page 3 — relationship
  String? _selectedRelationship;
  static const List<Map<String, dynamic>> _relationships = [
    {'label': 'Married', 'icon': Icons.favorite_rounded},
    {'label': 'Single', 'icon': Icons.person_outline_rounded},
    {'label': 'Broke up', 'icon': Icons.heart_broken_rounded},
    {'label': 'Missing partner', 'icon': Icons.people_outline_rounded},
  ];

  // Page 2 — age slider
  double _ageValue = 22;
  String? _milestoneEmoji;

  static const Map<int, Map<String, String>> _milestones = {
    13: {'emoji': '🎮', 'label': 'Teenager!'},
    16: {'emoji': '🚗', 'label': 'Driving age!'},
    18: {'emoji': '🎈', 'label': 'Adulthood!'},
    21: {'emoji': '🎓', 'label': 'Milestone!'},
    25: {'emoji': '💼', 'label': 'Quarter century!'},
    30: {'emoji': '🎯', 'label': 'Thirty & thriving!'},
    40: {'emoji': '🌟', 'label': 'Fabulous forty!'},
    50: {'emoji': '🏆', 'label': 'Golden years!'},
    60: {'emoji': '🌅', 'label': 'Wisdom era!'},
  };

  void _onAgeChanged(double value) {
    final oldAge = _ageValue.round();
    final newAge = value.round();
    setState(() {
      _ageValue = value;
      if (oldAge != newAge && _milestones.containsKey(newAge)) {
        _milestoneEmoji = _milestones[newAge]!['emoji'];
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) setState(() => _milestoneEmoji = null);
        });
      }
    });
  }

  String get _ageGroupLabel {
    final age = _ageValue.round();
    if (age < 18) return 'Under 18';
    if (age < 25) return '18-24';
    if (age < 35) return '25-34';
    if (age < 45) return '35-44';
    return '45+';
  }

  // Page 3 — concerns
  final Set<int> _selectedConcerns = {};
  static const List<Map<String, dynamic>> _concerns = [
    {'label': 'Stress', 'icon': Icons.bolt_rounded},
    {'label': 'Sleep', 'icon': Icons.nightlight_outlined},
    {'label': 'Anxiety', 'icon': Icons.waves_rounded},
    {'label': 'Focus', 'icon': Icons.center_focus_strong_outlined},
    {'label': 'Healing', 'icon': Icons.favorite_outline_rounded},
  ];

  // Page 4 — sleep schedule
  int _selectedSleep = -1;

  // Page 5 — mood baseline
  double _moodBaseline = 0.5;

  // Page 6 — avatar customization

  void _nextPage() {
    if (_currentPage < 8) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: AppTheme.defaultCurve,
      );
    }
  }

  Future<void> _finish() async {
    _prefs.name = _nameController.text.trim();
    _prefs.gender = _selectedGender;
    _prefs.ageGroup = _ageGroupLabel;
    _prefs.relationshipStatus = _selectedRelationship;
    _prefs.concerns = _selectedConcerns
        .map((i) => _concerns[i]['label'] as String)
        .toList();
    _prefs.sleepSchedule = _selectedSleep == 0 ? 'morning' : 'night';
    _prefs.moodBaseline = _moodBaseline;
    // Save preferences to Appwrite (fire and forget)
    try {
      await _prefs.saveToRemote();
      await AuthService().updateName(_prefs.name ?? 'friend');
    } catch (e, st) {
      developer.log('Failed to save onboarding preferences', name: 'OnboardingScreen', error: e, stackTrace: st);
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CommunityOnboardingScreen(),
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

  bool get _canProceed {
    switch (_currentPage) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _selectedGender != null;
      case 2:
        return true; // age slider always has a value
      case 3:
        return _selectedRelationship != null;
      case 4:
        return _selectedConcerns.isNotEmpty;
      case 5:
        return _selectedSleep >= 0;
      case 6:
        return true; // mood slider always has a value
      case 7:
        return true; // avatar always has defaults
      case 8:
        return true;
      default:
        return false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GradientBackground(
        colors: const [AppColors.cream, AppColors.paleLilac],
        secondaryColors: const [AppColors.lightBlush, AppColors.cream],
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Progress dots
              _buildProgressDots(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildNamePage(),
                    _buildGenderPage(),
                    _buildAgeGroupPage(),
                    _buildRelationshipPage(),
                    _buildConcernsPage(),
                    _buildSleepPage(),
                    _buildMoodBaselinePage(),
                    _buildAvatarPage(),
                    _buildFinishPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: List.generate(9, (i) {
          final isActive = i <= _currentPage;
          return Expanded(
            child: AnimatedContainer(
              duration: AppTheme.fadeInDuration,
              height: 3,
              margin: EdgeInsets.only(right: i < 8 ? 4 : 0),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.softIndigo.withValues(alpha: 0.7)
                    : AppColors.dividerColor(context).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Page 1: Name ───
  Widget _buildNamePage() {
    return _pageWrapper(
      heading: 'What should\nwe call you?',
      subtitle: 'A name, a nickname — whatever feels right.',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          border: Border.all(color: AppColors.dividerColor(context), width: 1),
        ),
        child: TextField(
          controller: _nameController,
          style: AppTypography.uiLabelC(context),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Your name',
            hintStyle: AppTypography.uiLabel(
              color: AppColors.tertiary(context),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Page 1: Gender ───
  Widget _buildGenderPage() {
    return _pageWrapper(
      heading: 'How do you\nidentify?',
      subtitle: 'This helps us personalize your experience.',
      child: Column(
        children: _genders.map((g) {
          final isSelected = _selectedGender == g['label'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedGender = g['label'] as String),
              child: AnimatedContainer(
                duration: AppTheme.fadeInDuration,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
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
                    Icon(
                      g['icon'] as IconData,
                      size: 28,
                      color: isSelected ? AppColors.softIndigo : AppColors.tertiary(context),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      g['label'] as String,
                      style: AppTypography.buttonText(
                        color: isSelected ? AppColors.softIndigo : AppColors.primary(context),
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: AppColors.softIndigo, size: 22),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Page 3: Relationship ───
  Widget _buildRelationshipPage() {
    return _pageWrapper(
      heading: 'What\'s your\nrelationship status?',
      subtitle: 'We\'ll tailor content that feels right for you.',
      child: Column(
        children: _relationships.map((r) {
          final isSelected = _selectedRelationship == r['label'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedRelationship = r['label'] as String),
              child: AnimatedContainer(
                duration: AppTheme.fadeInDuration,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
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
                    Icon(
                      r['icon'] as IconData,
                      size: 28,
                      color: isSelected ? AppColors.softIndigo : AppColors.tertiary(context),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      r['label'] as String,
                      style: AppTypography.buttonText(
                        color: isSelected ? AppColors.softIndigo : AppColors.primary(context),
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: AppColors.softIndigo, size: 22),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Page 2: Age Slider with Milestones ───
  Widget _buildAgeGroupPage() {
    final age = _ageValue.round();
    final milestone = _milestones[age];

    return _pageWrapper(
      heading: 'How old\nare you?',
      subtitle: 'Drag the slider to your age.',
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Big age number
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Text(
              '$age',
              key: ValueKey(age),
              style: AppTypography.heroHeading(
                color: AppColors.softIndigo,
              ).copyWith(fontSize: 56),
            ),
          ),
          const SizedBox(height: 4),
          Text('years old', style: AppTypography.captionC(context)),

          const SizedBox(height: 8),

          // Milestone emoji animation
          SizedBox(
            height: 48,
            child: Center(
              child: milestone != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                              milestone['emoji']!,
                              style: const TextStyle(fontSize: 28),
                            )
                            .animate(key: ValueKey('emoji_$age'))
                            .scale(
                              begin: const Offset(0.3, 0.3),
                              end: const Offset(1, 1),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.elasticOut,
                            ),
                        const SizedBox(width: 8),
                        Text(
                              milestone['label']!,
                              style: AppTypography.uiLabel(
                                color: AppColors.softIndigo,
                              ).copyWith(fontWeight: FontWeight.w500),
                            )
                            .animate(key: ValueKey('label_$age'))
                            .fadeIn(duration: const Duration(milliseconds: 300))
                            .slideX(
                              begin: -0.1,
                              end: 0,
                              duration: const Duration(milliseconds: 300),
                            ),
                      ],
                    )
                  : null,
            ),
          ),

          // Floating milestone emoji
          if (_milestoneEmoji != null)
            SizedBox(
              height: 40,
              child:
                  Text(_milestoneEmoji!, style: const TextStyle(fontSize: 32))
                      .animate()
                      .slideY(
                        begin: 0,
                        end: -1.5,
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOut,
                      )
                      .fadeOut(
                        delay: const Duration(milliseconds: 600),
                        duration: const Duration(milliseconds: 400),
                      ),
            ),

          const SizedBox(height: 16),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.softIndigo.withValues(alpha: 0.6),
              inactiveTrackColor: AppColors.dividerColor(context),
              thumbColor: AppColors.softIndigo,
              overlayColor: AppColors.softIndigo.withValues(alpha: 0.1),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: _ageValue,
              min: 10,
              max: 70,
              divisions: 60,
              onChanged: _onAgeChanged,
            ),
          ),

          const SizedBox(height: 8),

          // Min/Max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('10', style: AppTypography.captionC(context)),
                Text('70', style: AppTypography.captionC(context)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Milestone markers row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _milestones.entries.map((e) {
                final isReached = age >= e.key;
                return AnimatedContainer(
                  duration: AppTheme.fadeInDuration,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isReached
                        ? AppColors.softIndigo.withValues(alpha: 0.1)
                        : AppColors.card(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                    border: Border.all(
                      color: isReached
                          ? AppColors.softIndigo.withValues(alpha: 0.3)
                          : AppColors.dividerColor(context),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${e.value['emoji']} ${e.key}',
                    style:
                        AppTypography.caption(
                          color: isReached
                              ? AppColors.softIndigo
                              : AppColors.tertiary(context),
                        ).copyWith(
                          fontWeight: isReached
                              ? FontWeight.w500
                              : FontWeight.w300,
                        ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Page 3: Concerns ───
  Widget _buildConcernsPage() {
    return _pageWrapper(
      heading: 'What brings\nyou here?',
      subtitle: 'Select all that resonate.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(_concerns.length, (i) {
          final isSelected = _selectedConcerns.contains(i);
          final concern = _concerns[i];
          return GestureDetector(
            onTap: () => setState(() {
              if (isSelected) {
                _selectedConcerns.remove(i);
              } else {
                _selectedConcerns.add(i);
              }
            }),
            child: AnimatedContainer(
              duration: AppTheme.fadeInDuration,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.softIndigo.withValues(alpha: 0.1)
                    : AppColors.card(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                border: Border.all(
                  color: isSelected
                      ? AppColors.softIndigo.withValues(alpha: 0.4)
                      : AppColors.dividerColor(context),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    concern['icon'] as IconData,
                    size: 18,
                    color: isSelected
                        ? AppColors.softIndigo
                        : AppColors.tertiary(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    concern['label'] as String,
                    style: AppTypography.buttonText(
                      color: isSelected
                          ? AppColors.softIndigo
                          : AppColors.primary(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Page 4: Sleep Schedule ───
  Widget _buildSleepPage() {
    return _pageWrapper(
      heading: 'Are you a morning\nor night person?',
      subtitle: 'We\'ll adjust reminders and tips.',
      child: Row(
        children: [
          _buildSleepCard(0, Icons.wb_sunny_outlined, 'Morning\nperson'),
          const SizedBox(width: 14),
          _buildSleepCard(1, Icons.nightlight_outlined, 'Night\nperson'),
        ],
      ),
    );
  }

  Widget _buildSleepCard(int index, IconData icon, String label) {
    final isSelected = _selectedSleep == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSleep = index),
        child: AnimatedContainer(
          duration: AppTheme.fadeInDuration,
          padding: const EdgeInsets.symmetric(vertical: 28),
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
          child: Column(
            children: [
              Icon(
                icon,
                size: 36,
                color: isSelected
                    ? AppColors.softIndigo
                    : AppColors.tertiary(context),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.buttonText(
                  color: isSelected
                      ? AppColors.softIndigo
                      : AppColors.primary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Page 5: Mood Baseline ───
  Widget _buildMoodBaselinePage() {
    final moodLabels = ['Very low', 'Low', 'Okay', 'Good', 'Great'];
    final moodIndex = (_moodBaseline * 4).round().clamp(0, 4);

    return _pageWrapper(
      heading: 'How have you\nbeen feeling?',
      subtitle: 'Just a gentle check-in.',
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            moodLabels[moodIndex],
            style: AppTypography.sectionHeading(color: AppColors.softIndigo),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.softIndigo.withValues(alpha: 0.6),
              inactiveTrackColor: AppColors.dividerColor(context),
              thumbColor: AppColors.softIndigo,
              overlayColor: AppColors.softIndigo.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: _moodBaseline,
              onChanged: (v) => setState(() => _moodBaseline = v),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Page 6: Avatar Customization ───
  Widget _buildAvatarPage() {
    return _pageWrapper(
      heading: 'Create your\navatar.',
      subtitle: 'A little you for this space.',
      child: const AvatarCustomizationScreen(
        fullScreen: false,
      ),
    );
  }

  // ─── Page 7: Finish ───
  Widget _buildFinishPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
                Icons.spa_outlined,
                size: 56,
                color: AppColors.softIndigo.withValues(alpha: 0.6),
              )
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 800))
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: const Duration(milliseconds: 800),
                curve: AppTheme.gentleCurve,
              ),
          const SizedBox(height: 24),
          Text(
                'Your space\nis ready.',
                textAlign: TextAlign.center,
                style: AppTypography.heroHeadingC(context),
              )
              .animate(delay: const Duration(milliseconds: 300))
              .fadeIn(duration: const Duration(milliseconds: 700)),
          const SizedBox(height: 12),
          Text(
                'Take a breath. You belong here.',
                textAlign: TextAlign.center,
                style: AppTypography.subtitleC(context),
              )
              .animate(delay: const Duration(milliseconds: 600))
              .fadeIn(duration: const Duration(milliseconds: 500)),
          const SizedBox(height: 48),
          GestureDetector(
                onTap: _finish,
                child: AnimatedContainer(
                  duration: AppTheme.fadeInDuration,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.softIndigo.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  ),
                  child: Center(
                    child: Text(
                      'Continue',
                      style: AppTypography.buttonText(color: Colors.white),
                    ),
                  ),
                ),
              )
              .animate(delay: const Duration(milliseconds: 900))
              .fadeIn(duration: const Duration(milliseconds: 400)),
        ],
      ),
    );
  }

  // ─── Shared page wrapper ───
  Widget _pageWrapper({
    required String heading,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text(heading, style: AppTypography.heroHeadingC(context))
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
          Text(subtitle, style: AppTypography.subtitleC(context))
              .animate(delay: const Duration(milliseconds: 200))
              .fadeIn(duration: const Duration(milliseconds: 500)),
          const SizedBox(height: 36),
          child
              .animate(delay: const Duration(milliseconds: 350))
              .fadeIn(duration: const Duration(milliseconds: 400)),
          const SizedBox(height: 48),
          // Continue button
          GestureDetector(
                onTap: _canProceed ? _nextPage : null,
                child: AnimatedContainer(
                  duration: AppTheme.fadeInDuration,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _canProceed
                        ? AppColors.softIndigo.withValues(alpha: 0.85)
                        : AppColors.dividerColor(
                            context,
                          ).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  ),
                  child: Center(
                    child: Text(
                      'Continue',
                      style: AppTypography.buttonText(
                        color: _canProceed
                            ? Colors.white
                            : AppColors.tertiary(context),
                      ),
                    ),
                  ),
                ),
              )
              .animate(delay: const Duration(milliseconds: 500))
              .fadeIn(duration: const Duration(milliseconds: 400)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

