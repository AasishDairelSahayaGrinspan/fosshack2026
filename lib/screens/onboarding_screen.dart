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

/// Multi-step onboarding — 12 pages via PageView.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final UserPreferencesService _prefs = UserPreferencesService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
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

  // Page 2 — age wheel picker
  int _selectedAge = 22;
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

  void _onAgeChanged(int value) {
    if (_selectedAge != value && _milestones.containsKey(value)) {
      setState(() {
        _selectedAge = value;
        _milestoneEmoji = _milestones[value]!['emoji'];
      });
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _milestoneEmoji = null);
      });
    } else {
      setState(() => _selectedAge = value);
    }
  }

  String get _ageGroupLabel {
    if (_selectedAge < 18) return 'Under 18';
    if (_selectedAge < 25) return '18-24';
    if (_selectedAge < 35) return '25-34';
    if (_selectedAge < 45) return '35-44';
    return '45+';
  }

  String _suggestedEmploymentStatus(int age) {
    if (age < 25) return 'Student';
    if (age <= 65) return 'IT Employee';
    return 'Retired';
  }

  // Page 4 — employment status
  String? _selectedEmploymentStatus;
  static const List<Map<String, dynamic>> _employmentStatuses = [
    {'label': 'Student', 'icon': Icons.school_rounded},
    {'label': 'IT Employee', 'icon': Icons.computer_rounded},
    {'label': 'Retired', 'icon': Icons.beach_access_rounded},
  ];

  // Page 5 — shift preference (for employed)
  String? _selectedShift;
  static const List<Map<String, dynamic>> _shifts = [
    {'label': 'Day Shift', 'icon': Icons.light_mode_rounded, 'time': '6am - 6pm'},
    {'label': 'Night Shift', 'icon': Icons.dark_mode_rounded, 'time': '6pm - 6am'},
  ];

  // Page 6 — BMI calculator
  double? _calculatedBmi;
  String? _bmiStatus;

  String _calculateBmi(String? heightCm, String? weightKg) {
    if (heightCm == null || weightKg == null) return '';
    try {
      final height = double.parse(heightCm);
      final weight = double.parse(weightKg);
      if (height <= 0 || weight <= 0) return '';
      final heightM = height / 100;
      final bmi = weight / (heightM * heightM);
      _calculatedBmi = bmi;
      if (bmi < 18.5) {
        _bmiStatus = 'Underweight';
      } else if (bmi < 25) {
        _bmiStatus = 'Normal';
      } else if (bmi < 30) {
        _bmiStatus = 'Overweight';
      } else {
        _bmiStatus = 'Obese';
      }
      return bmi.toStringAsFixed(1);
    } catch (e) {
      return '';
    }
  }

  // Page 4 — concerns
  final Set<int> _selectedConcerns = {};
  static const List<Map<String, dynamic>> _concerns = [
    {'label': 'Stress', 'icon': Icons.bolt_rounded},
    {'label': 'Sleep', 'icon': Icons.nightlight_outlined},
    {'label': 'Anxiety', 'icon': Icons.waves_rounded},
    {'label': 'Overthinking', 'icon': Icons.psychology_alt_outlined},
    {'label': 'Focus', 'icon': Icons.center_focus_strong_outlined},
    {'label': 'Healing', 'icon': Icons.favorite_outline_rounded},
  ];

  // Page 8 — sleep schedule
  int _selectedSleep = -1;

  // Page 9 — mood baseline
  double _moodBaseline = 0.5;

  // Page 10 — avatar customization

  void _nextPage() {
    if (_currentPage < 11) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: AppTheme.defaultCurve,
      );
    }
  }

  Future<void> _finish() async {
    _prefs.name = _nameController.text.trim();
    _prefs.gender = _selectedGender;
    _prefs.age = _selectedAge;
    _prefs.ageGroup = _ageGroupLabel;
    _prefs.relationshipStatus = _selectedRelationship;
    _prefs.employmentStatus = _selectedEmploymentStatus;
    _prefs.shiftPreference = _selectedShift;
    _prefs.heightCm = _heightController.text.trim();
    _prefs.weightKg = _weightController.text.trim();
    _prefs.bmi = _calculatedBmi;
    _prefs.bmiStatus = _bmiStatus;
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
      developer.log(
        'Failed to save onboarding preferences',
        name: 'OnboardingScreen',
        error: e,
        stackTrace: st,
      );
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
        return true; // age wheel always has a value
      case 3:
        return _selectedRelationship != null;
      case 4:
        return _selectedEmploymentStatus != null;
      case 5:
        return _selectedEmploymentStatus == 'Student' || _selectedShift != null;
      case 6:
        return _heightController.text.isNotEmpty && _weightController.text.isNotEmpty && _calculatedBmi != null;
      case 7:
        return _selectedConcerns.isNotEmpty;
      case 8:
        return _selectedSleep >= 0;
      case 9:
        return true; // mood slider always has a value
      case 10:
        return true; // avatar always has defaults
      case 11:
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
                    _buildEmploymentStatusPage(),
                    _buildShiftPreferencePage(),
                    _buildBmiCalculatorPage(),
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
        children: List.generate(12, (i) {
          final isActive = i <= _currentPage;
          return Expanded(
            child: AnimatedContainer(
              duration: AppTheme.fadeInDuration,
              height: 3,
              margin: EdgeInsets.only(right: i < 11 ? 4 : 0),
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
              onTap: () =>
                  setState(() => _selectedGender = g['label'] as String),
              child: AnimatedContainer(
                duration: AppTheme.fadeInDuration,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 20,
                ),
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
                      color: isSelected
                          ? AppColors.softIndigo
                          : AppColors.tertiary(context),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      g['label'] as String,
                      style: AppTypography.buttonText(
                        color: isSelected
                            ? AppColors.softIndigo
                            : AppColors.primary(context),
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.softIndigo,
                        size: 22,
                      ),
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
              onTap: () =>
                  setState(() => _selectedRelationship = r['label'] as String),
              child: AnimatedContainer(
                duration: AppTheme.fadeInDuration,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 20,
                ),
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
                      color: isSelected
                          ? AppColors.softIndigo
                          : AppColors.tertiary(context),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      r['label'] as String,
                      style: AppTypography.buttonText(
                        color: isSelected
                            ? AppColors.softIndigo
                            : AppColors.primary(context),
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.softIndigo,
                        size: 22,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Page 4: Employment Status ───
  Widget _buildEmploymentStatusPage() {
    final suggested = _suggestedEmploymentStatus(_selectedAge);
    return _pageWrapper(
      heading: 'What\'s your\nemployment status?',
      subtitle: 'Based on your age, $suggested is suggested.',
      child: Column(
        children: _employmentStatuses.map((e) {
          final isSelected = _selectedEmploymentStatus == e['label'];
          final isSuggested = e['label'] == suggested;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedEmploymentStatus = e['label'] as String),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: AppTheme.fadeInDuration,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 20,
                    ),
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
                          e['icon'] as IconData,
                          size: 28,
                          color: isSelected
                              ? AppColors.softIndigo
                              : AppColors.tertiary(context),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          e['label'] as String,
                          style: AppTypography.buttonText(
                            color: isSelected
                                ? AppColors.softIndigo
                                : AppColors.primary(context),
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.softIndigo,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                  if (isSuggested)
                    Positioned(
                      top: -8,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softIndigo,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Suggested',
                          style: AppTypography.caption(
                            color: AppColors.cream,
                          ).copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Page 5: Shift Preference (for employed) ───
  Widget _buildShiftPreferencePage() {
    if (_selectedEmploymentStatus == 'Student' || _selectedEmploymentStatus == 'Retired') {
      Future.microtask(() {
        if (_currentPage == 5 && mounted) {
          _nextPage();
        }
      });
    }

    return _pageWrapper(
      heading: 'What shift\ndo you work?',
      subtitle: 'This helps us schedule notifications for you.',
      child: Column(
        children: _shifts.map((s) {
          final isSelected = _selectedShift == s['label'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedShift = s['label'] as String),
              child: AnimatedContainer(
                duration: AppTheme.fadeInDuration,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 20,
                ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          s['icon'] as IconData,
                          size: 28,
                          color: isSelected
                              ? AppColors.softIndigo
                              : AppColors.tertiary(context),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          s['label'] as String,
                          style: AppTypography.buttonText(
                            color: isSelected
                                ? AppColors.softIndigo
                                : AppColors.primary(context),
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.softIndigo,
                            size: 22,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s['time'] as String,
                      style: AppTypography.caption(
                        color: AppColors.tertiary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Page 6: BMI Calculator ───
  Widget _buildBmiCalculatorPage() {
    final bmiValue = _calculateBmi(_heightController.text, _weightController.text);
    
    return _pageWrapper(
      heading: 'What\'s your\nhealth profile?',
      subtitle: 'Height & weight help us personalize wellness tips.',
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              border: Border.all(color: AppColors.dividerColor(context), width: 1),
            ),
            child: TextField(
              controller: _heightController,
              style: AppTypography.uiLabelC(context),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Height (cm)',
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
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              border: Border.all(color: AppColors.dividerColor(context), width: 1),
            ),
            child: TextField(
              controller: _weightController,
              style: AppTypography.uiLabelC(context),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Weight (kg)',
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
          const SizedBox(height: 20),

          if (bmiValue.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softIndigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(
                  color: AppColors.softIndigo.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Your BMI',
                    style: AppTypography.caption(
                      color: AppColors.tertiary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bmiValue,
                    style: AppTypography.heroHeading(
                      color: AppColors.softIndigo,
                    ).copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getBmiColor(_bmiStatus).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getBmiColor(_bmiStatus).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _bmiStatus ?? 'Calculate to see status',
                      style: AppTypography.buttonText(
                        color: _getBmiColor(_bmiStatus),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getBmiColor(String? status) {
    switch (status) {
      case 'Underweight':
        return AppColors.softIndigo;
      case 'Normal':
        return Colors.green;
      case 'Overweight':
        return Colors.orange;
      case 'Obese':
        return Colors.red;
      default:
        return AppColors.tertiary(context);
    }
  }

  // ─── Page 2: Age Slider with Milestones ───
  Widget _buildAgeGroupPage() {
    final milestone = _milestones[_selectedAge];

    return _pageWrapper(
      heading: 'How old\nare you?',
      subtitle: 'Scroll to select your age.',
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Big age number
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Text(
              '$_selectedAge',
              key: ValueKey(_selectedAge),
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
                            .animate(key: ValueKey('emoji_$_selectedAge'))
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
                            .animate(key: ValueKey('label_$_selectedAge'))
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

          const SizedBox(height: 24),

          // Wheel picker (like iOS/Samsung clock)
          SizedBox(
            height: 200,
            child: ListWheelScrollView(
              itemExtent: 50,
              diameterRatio: 1.2,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) => _onAgeChanged(13 + index),
              children: List.generate(68, (index) {
                final age = 13 + index;
                final isSelected = age == _selectedAge;
                return Center(
                  child: Text(
                    '$age',
                    style: AppTypography.buttonText(
                      color: isSelected
                          ? AppColors.softIndigo
                          : AppColors.tertiary(context),
                    ).copyWith(
                      fontSize: isSelected ? 28 : 18,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          // Suggested employment status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.softIndigo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(
                color: AppColors.softIndigo.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.softIndigo,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Next we\'ll confirm if you\'re a ${_suggestedEmploymentStatus(_selectedAge)}',
                    style: AppTypography.caption(
                      color: AppColors.softIndigo,
                    ),
                  ),
                ),
              ],
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
      child: const AvatarCustomizationScreen(fullScreen: false),
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
