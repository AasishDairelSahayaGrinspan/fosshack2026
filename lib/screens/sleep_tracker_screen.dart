import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

/// Sleep Tracker — moon-themed UI with slider and weekly graph.
class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen>
    with TickerProviderStateMixin {
  double _hoursSlept = 7.0;
  bool _saved = false;

  // Weekly data — loaded from database (index 0 = 6 days ago, index 6 = today)
  final List<double> _weeklyData = List.filled(7, 0.0);

  late AnimationController _starsController;
  late AnimationController _chartController;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutCubic,
    );
    _loadSleepData();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _chartController.forward();
    });
  }

  @override
  void dispose() {
    _starsController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    setState(() {
      _weeklyData[6] = _hoursSlept;
      _saved = true;
    });
    _chartController.reset();
    _chartController.forward();

    // Persist to local database
    final user = AuthService().currentUser;
    if (user != null) {
      try {
        await DatabaseService().saveSleepLog(
          userId: user.$id,
          hours: _hoursSlept,
          dreamType: '',
          dreamDescription: '',
        );
      } catch (e, st) {
        developer.log(
          'Failed to save sleep log',
          name: 'SleepTracker',
          error: e,
          stackTrace: st,
        );
      }
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  Future<void> _loadSleepData() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    try {
      final logs = await DatabaseService().getSleepLogs(user.$id, days: 7);
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < logs.length && i < 7; i++) {
          _weeklyData[i] = (logs[i]['hours'] as num?)?.toDouble() ?? 0.0;
        }
      });
    } catch (e, st) {
      developer.log(
        'Failed to load sleep data',
        name: 'SleepTracker',
        error: e,
        stackTrace: st,
      );
    }
  }

  String get _sleepMessage {
    if (_hoursSlept >= 8) return 'Wonderful rest.';
    if (_hoursSlept >= 7) return 'A solid night.';
    if (_hoursSlept >= 6) return 'Not bad, be gentle.';
    if (_hoursSlept >= 5) return 'Your body needs more.';
    return 'Please rest tonight.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.black, AppColors.black, AppColors.ink304057],
          ),
        ),
        child: Stack(
          children: [
            // ─── Animated Stars ───
            _AnimatedStars(controller: _starsController),

            // ─── Content ───
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 24),

                    // ─── Moon & Heading ───
                    Center(
                      child: Column(
                        children: [
                          // Moon icon with glow
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.amberFdb903.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.nightlight_round,
                              color: AppColors.amberFdb903,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sleep Tracker',
                            style: AppTypography.heroHeading(
                              color: AppColors.amberFdb903,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'How did you sleep last night?',
                            style: AppTypography.subtitle(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      curve: AppTheme.gentleCurve,
                    ),

                    const SizedBox(height: 40),

                    // ─── Hours Slider ───
                    _buildSliderCard()
                        .animate(delay: const Duration(milliseconds: 200))
                        .fadeIn(
                          duration: const Duration(milliseconds: 500),
                          curve: AppTheme.gentleCurve,
                        )
                        .slideY(
                          begin: 0.06,
                          end: 0,
                          duration: const Duration(milliseconds: 500),
                          curve: AppTheme.gentleCurve,
                        ),

                    const SizedBox(height: 24),

                    // ─── Weekly Chart ───
                    _buildWeeklyChart()
                        .animate(delay: const Duration(milliseconds: 350))
                        .fadeIn(
                          duration: const Duration(milliseconds: 500),
                          curve: AppTheme.gentleCurve,
                        )
                        .slideY(
                          begin: 0.06,
                          end: 0,
                          duration: const Duration(milliseconds: 500),
                          curve: AppTheme.gentleCurve,
                        ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
          ),
          Text(
            'Sleep',
            style: AppTypography.uiLabel(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildSliderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Hours display
          Text(
            '${_hoursSlept.toStringAsFixed(1)}h',
            style: AppTypography.heroHeading(
              color: AppColors.amberFdb903,
            ).copyWith(fontSize: 48),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _sleepMessage,
              key: ValueKey<String>(_sleepMessage),
              style: AppTypography.subtitle(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.amberFdb903.withValues(alpha: 0.6),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: AppColors.amberFdb903,
              overlayColor: AppColors.amberFdb903.withValues(alpha: 0.1),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _hoursSlept,
              min: 0,
              max: 12,
              divisions: 24,
              onChanged: (v) => setState(() => _hoursSlept = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0h',
                style: AppTypography.caption(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              Text(
                '12h',
                style: AppTypography.caption(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Save button
          GestureDetector(
            onTap: _saveEntry,
            child: AnimatedContainer(
              duration: AppTheme.fadeInDuration,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: _saved
                    ? AppColors.sageGreen.withValues(alpha: 0.3)
                    : AppColors.amberFdb903.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                border: Border.all(
                  color: _saved
                      ? AppColors.sageGreen.withValues(alpha: 0.5)
                      : AppColors.amberFdb903.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _saved ? Icons.check_rounded : Icons.save_outlined,
                    color: _saved ? AppColors.sageGreen : AppColors.amberFdb903,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _saved ? 'Saved' : 'Log Sleep',
                    style: AppTypography.buttonText(
                      color: _saved
                          ? AppColors.sageGreen
                          : AppColors.amberFdb903,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns short day labels for the last 7 days (index 0 = 6 days ago, 6 = today).
  List<String> _dayLabels() {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return names[day.weekday - 1];
    });
  }

  /// Returns date labels like "12" for bar chart sub-labels.
  List<String> _dateLabels() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return '${day.day}';
    });
  }

  String _formattedToday() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  Widget _buildWeeklyChart() {
    final dayNames = _dayLabels();
    final dateNums = _dateLabels();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: AppTypography.sectionHeading(color: AppColors.amberFdb903),
          ),
          const SizedBox(height: 4),
          Text(
            _formattedToday(),
            style: AppTypography.caption(
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),

          // Bar chart
          SizedBox(
            height: 140,
            child: AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final maxH = 120.0;
                    final barH =
                        ((_weeklyData[i] / 12.0) * maxH * _chartAnimation.value)
                            .clamp(0.0, maxH);
                    final isToday = i == 6;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_weeklyData[i] > 0)
                              Text(
                                _weeklyData[i].toStringAsFixed(1),
                                style: AppTypography.caption(
                                  color: isToday
                                      ? AppColors.amberFdb903
                                      : Colors.white.withValues(alpha: 0.4),
                                ).copyWith(fontSize: 10),
                              ),
                            const SizedBox(height: 4),
                            // Glowing bar
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              height: barH,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: Colors.white.withValues(
                                  alpha: isToday ? 0.7 : 0.35,
                                ),
                                boxShadow: barH > 0
                                    ? [
                                        BoxShadow(
                                          color: Colors.white.withValues(
                                            alpha: isToday ? 0.3 : 0.12,
                                          ),
                                          blurRadius: isToday ? 14 : 8,
                                          spreadRadius: isToday ? 2 : 1,
                                        ),
                                        BoxShadow(
                                          color: AppColors.amberFdb903
                                              .withValues(
                                                alpha: isToday ? 0.2 : 0.06,
                                              ),
                                          blurRadius: 20,
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Day name + date number labels
          Row(
            children: List.generate(7, (i) {
              final isToday = i == 6;
              return Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dayNames[i],
                        style: AppTypography.caption(
                          color: isToday
                              ? AppColors.amberFdb903
                              : Colors.white.withValues(alpha: 0.4),
                        ).copyWith(fontSize: 10),
                      ),
                      Text(
                        dateNums[i],
                        style: AppTypography.caption(
                          color: isToday
                              ? AppColors.amberFdb903
                              : Colors.white.withValues(alpha: 0.25),
                        ).copyWith(fontSize: 8),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Animated twinkling stars for the sleep background.
class _AnimatedStars extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedStars({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _StarsPainter(twinkle: controller.value),
        );
      },
    );
  }
}

class _StarsPainter extends CustomPainter {
  final double twinkle;

  _StarsPainter({required this.twinkle});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42); // Fixed seed for consistent star positions
    final starPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.7;
      final baseRadius = rng.nextDouble() * 1.5 + 0.5;
      final phase = rng.nextDouble();

      // Each star twinkles at its own phase
      final opacity = 0.2 + 0.6 * ((sin((twinkle + phase) * pi * 2) + 1) / 2);
      starPaint.color = Colors.white.withValues(alpha: opacity);

      canvas.drawCircle(Offset(x, y), baseRadius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) =>
      oldDelegate.twinkle != twinkle;
}
