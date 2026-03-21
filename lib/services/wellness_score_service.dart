import 'dart:developer' as developer;

/// Log data for a single day
class DailyLog {
  final DateTime date;
  final int mood;                         // 1-5
  final double sleepHours;                // 0-24
  final int stress;                       // 1-5
  final int energy;                       // 1-5
  final int anxiety;                      // 1-5
  final bool? exercised;                  // optional
  final String? journalText;              // optional
  final double wellnessScore;             // calculated

  DailyLog({
    required this.date,
    required this.mood,
    required this.sleepHours,
    required this.stress,
    required this.energy,
    required this.anxiety,
    this.exercised,
    this.journalText,
    required this.wellnessScore,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'mood': mood,
    'sleepHours': sleepHours,
    'stress': stress,
    'energy': energy,
    'anxiety': anxiety,
    'exercised': exercised,
    'journalText': journalText,
    'wellnessScore': wellnessScore,
  };

  static DailyLog fromJson(Map<String, dynamic> json) => DailyLog(
    date: DateTime.parse(json['date'] as String),
    mood: json['mood'] as int,
    sleepHours: (json['sleepHours'] as num).toDouble(),
    stress: json['stress'] as int,
    energy: json['energy'] as int,
    anxiety: json['anxiety'] as int,
    exercised: json['exercised'] as bool?,
    journalText: json['journalText'] as String?,
    wellnessScore: (json['wellnessScore'] as num).toDouble(),
  );
}

/// Trend analysis result
class TrendAnalysis {
  final double current7DayAverage;
  final double previous7DayAverage;
  final String trend;                     // "improving", "declining", "stable"
  final double percentageChange;
  final String summary;

  TrendAnalysis({
    required this.current7DayAverage,
    required this.previous7DayAverage,
    required this.trend,
    required this.percentageChange,
    required this.summary,
  });
}

/// Personalized insight
class Insight {
  final String category;
  final String message;
  final String severity;                  // "info", "note", "concern"
  final List<String> suggestions;

  Insight({
    required this.category,
    required this.message,
    required this.severity,
    required this.suggestions,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'message': message,
    'severity': severity,
    'suggestions': suggestions,
  };
}

/// Daily wellness score calculation and analysis service
/// Implements weighted scoring, trend analysis, and personalized insights
class WellnessScoreService {
  static final WellnessScoreService _instance = WellnessScoreService._internal();
  factory WellnessScoreService() => _instance;
  WellnessScoreService._internal();

  static const String _tag = 'WellnessScoreService';

  // Weights for daily wellness score (must sum to 100)
  static const double moodWeight = 0.30;     // 30%
  static const double energyWeight = 0.20;   // 20%
  static const double sleepWeight = 0.20;    // 20%
  static const double stressWeight = 0.20;   // 20% (inverse)
  static const double anxietyWeight = 0.10;  // 10% (inverse)

  /// Calculate daily wellness score (0-5 scale)
  /// Weights: mood(30%), energy(20%), sleep(20%), stress(20% inverse), anxiety(10% inverse)
  double calculateDailyScore({
    required int mood,                      // 1-5
    required double sleepHours,             // 0-24
    required int stress,                    // 1-5
    required int energy,                    // 1-5
    required int anxiety,                   // 1-5
  }) {
    // Validate inputs
    if (mood < 1 || mood > 5 ||
        stress < 1 || stress > 5 ||
        energy < 1 || energy > 5 ||
        anxiety < 1 || anxiety > 5 ||
        sleepHours < 0 || sleepHours > 24) {
      developer.log('Invalid wellness score inputs', name: _tag);
      return 0.0;
    }

    // Normalize to 0-1 scale
    final moodScore = mood / 5.0;
    final energyScore = energy / 5.0;
    final sleepScore = convertSleepHoursToScore(sleepHours) / 5.0;
    final stressScore = 1.0 - (stress / 5.0);    // Inverse
    final anxietyScore = 1.0 - (anxiety / 5.0);  // Inverse

    // Apply weights
    final weighted =
        (moodScore * moodWeight) +
        (energyScore * energyWeight) +
        (sleepScore * sleepWeight) +
        (stressScore * stressWeight) +
        (anxietyScore * anxietyWeight);

    // Scale back to 1-5
    final score = weighted * 5.0;

    developer.log(
      'Calculated wellness score: $score\n'
      '  mood: $moodScore, energy: $energyScore, sleep: $sleepScore\n'
      '  stress: $stressScore, anxiety: $anxietyScore',
      name: _tag,
    );

    return score.clamp(0.0, 5.0);
  }

  /// Convert sleep hours to a score (1-5).
  /// Optimal sleep: 7-9 hours = 5.
  double convertSleepHoursToScore(double sleepHours) {
    if (sleepHours >= 7 && sleepHours <= 9) {
      return 5.0;
    }
    if (sleepHours < 4 || sleepHours > 11) {
      return 1.0;
    }
    if (sleepHours < 7) {
      // Linear interpolation: 4hrs=1, 7hrs=5
      return 1.0 + ((sleepHours - 4) / 3.0) * 4.0;
    } else {
      // Linear interpolation: 9hrs=5, 11hrs=1
      return 5.0 - ((sleepHours - 9) / 2.0) * 4.0;
    }
  }

  /// Analyze 7-day trend by comparing current week to previous week
  TrendAnalysis analyzeTrend({
    required List<DailyLog> logs,
  }) {
    if (logs.isEmpty) {
      return TrendAnalysis(
        current7DayAverage: 0.0,
        previous7DayAverage: 0.0,
        trend: 'stable',
        percentageChange: 0.0,
        summary: 'Insufficient data for trend analysis.',
      );
    }

    // Sort by date (newest first)
    final sorted = List<DailyLog>.from(logs)
        ..sort((a, b) => b.date.compareTo(a.date));

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 7));
    final fourteenDaysAgo = now.subtract(Duration(days: 14));

    // Current 7 days
    final current7Days = sorted
        .where((log) => log.date.isAfter(sevenDaysAgo))
        .toList();

    // Previous 7 days
    final previous7Days = sorted
        .where((log) => log.date.isAfter(fourteenDaysAgo) && log.date.isBefore(sevenDaysAgo))
        .toList();

    if (current7Days.isEmpty) {
      return TrendAnalysis(
        current7DayAverage: 0.0,
        previous7DayAverage: 0.0,
        trend: 'stable',
        percentageChange: 0.0,
        summary: 'Need more data (at least 1 entry in current week).',
      );
    }

    final currentAvg = current7Days.isEmpty
        ? 0.0
        : current7Days.map((l) => l.wellnessScore).reduce((a, b) => a + b) /
            current7Days.length;

    final previousAvg = previous7Days.isEmpty
        ? currentAvg
        : previous7Days.map((l) => l.wellnessScore).reduce((a, b) => a + b) /
            previous7Days.length;

    final change = previousAvg == 0 ? 0.0 : ((currentAvg - previousAvg) / previousAvg);
    final percentChange = change * 100;

    String trend;
    String summary;

    if (percentChange > 5) {
      trend = 'improving';
      summary = 'Your wellness is on an upward trend! Keep up the momentum.';
    } else if (percentChange < -5) {
      trend = 'declining';
      summary = 'Your wellness score is declining. Consider adjusting your routine.';
    } else {
      trend = 'stable';
      summary = 'Your wellness is stable. Small changes can create positive momentum.';
    }

    developer.log(
      'Trend analysis: $trend\n'
      '  Current avg: $currentAvg, Previous avg: $previousAvg\n'
      '  Change: ${percentChange.toStringAsFixed(1)}%',
      name: _tag,
    );

    return TrendAnalysis(
      current7DayAverage: currentAvg,
      previous7DayAverage: previousAvg,
      trend: trend,
      percentageChange: percentChange,
      summary: summary,
    );
  }

  /// Generate personalized insights based on wellness patterns
  List<Insight> generateInsights({
    required List<DailyLog> logs,
  }) {
    if (logs.isEmpty) return [];

    final insights = <Insight>[];
    final sorted = List<DailyLog>.from(logs)..sort((a, b) => b.date.compareTo(a.date));

    // Pattern 1: Low sleep (< 6 hours for 3+ consecutive days)
    _detectLowSleep(sorted, insights);

    // Pattern 2: High stress (> 4 for multiple days)
    _detectHighStress(sorted, insights);

    // Pattern 3: Exercise correlation with mood improvement
    _detectExerciseImpact(sorted, insights);

    // Pattern 4: Anxiety trends
    _detectAnxietyTrends(sorted, insights);

    // Pattern 5: Energy patterns
    _detectEnergyPatterns(sorted, insights);

    // Pattern 6: Overall wellness trend
    _detectWellnessMomentum(sorted, insights);

    return insights;
  }

  void _detectLowSleep(List<DailyLog> logs, List<Insight> insights) {
    int consecutiveLowSleep = 0;
    for (final log in logs.take(14)) {
      if (log.sleepHours < 6) {
        consecutiveLowSleep++;
      } else {
        consecutiveLowSleep = 0;
      }
    }

    if (consecutiveLowSleep >= 3) {
      insights.add(Insight(
        category: 'Sleep',
        message: 'You\'ve had $consecutiveLowSleep consecutive nights with less than 6 hours of sleep.',
        severity: 'concern',
        suggestions: [
          'Establish a consistent bedtime routine',
          'Avoid screens 1 hour before bed',
          'Try the "Meditation Focus" or "Relaxing Music" tracks before sleep',
          'Aim for 7-9 hours of sleep tonight',
        ],
      ));
    }
  }

  void _detectHighStress(List<DailyLog> logs, List<Insight> insights) {
    int highStressDays = 0;
    for (final log in logs.take(7)) {
      if (log.stress >= 4) {
        highStressDays++;
      }
    }

    if (highStressDays >= 3) {
      insights.add(Insight(
        category: 'Stress',
        message: 'You\'ve reported high stress ($highStressDays/7 days this week).',
        severity: 'concern',
        suggestions: [
          'Try the "Breathing Exercise" for immediate relief',
          'Listen to calming music: "Ambient Calm" or "Peaceful Moments"',
          'Journaling can help process stress',
          'Consider exercise for stress relief',
        ],
      ));
    }
  }

  void _detectExerciseImpact(List<DailyLog> logs, List<Insight> insights) {
    int exerciseDays = 0;
    double avgMoodWithExercise = 0.0;
    int exerciseCount = 0;

    double avgMoodWithoutExercise = 0.0;
    int noExerciseCount = 0;

    for (final log in logs.take(14)) {
      if (log.exercised == true) {
        exerciseDays++;
        avgMoodWithExercise += log.mood;
        exerciseCount++;
      } else {
        avgMoodWithoutExercise += log.mood;
        noExerciseCount++;
      }
    }

    if (exerciseCount > 0) {
      avgMoodWithExercise /= exerciseCount;
    }
    if (noExerciseCount > 0) {
      avgMoodWithoutExercise /= noExerciseCount;
    }

    if (exerciseDays > 0 && avgMoodWithExercise > avgMoodWithoutExercise + 0.5) {
      insights.add(Insight(
        category: 'Exercise Impact',
        message: 'Your mood is significantly better on days when you exercise (+${(avgMoodWithExercise - avgMoodWithoutExercise).toStringAsFixed(1)} points).',
        severity: 'info',
        suggestions: [
          'Continue exercising regularly for mood benefits',
          'Aim for at least 3 exercise sessions per week',
          'Mix cardio with strength training for best results',
        ],
      ));
    }
  }

  void _detectAnxietyTrends(List<DailyLog> logs, List<Insight> insights) {
    double avgAnxiety = 0.0;
    int count = 0;

    for (final log in logs.take(7)) {
      avgAnxiety += log.anxiety;
      count++;
    }

    if (count > 0) {
      avgAnxiety /= count;
    }

    if (avgAnxiety > 3.5) {
      insights.add(Insight(
        category: 'Anxiety',
        message: 'Your anxiety levels have been elevated (average: ${avgAnxiety.toStringAsFixed(1)}/5).',
        severity: 'note',
        suggestions: [
          'Practice the "Breathing Exercise" for grounding',
          'Use "Meditation Focus" or "Morning Aura" for calm focus',
          'Share your feelings in your journal',
          'Reach out to a trusted friend or professional',
        ],
      ));
    }
  }

  void _detectEnergyPatterns(List<DailyLog> logs, List<Insight> insights) {
    double avgEnergy = 0.0;
    int count = 0;

    for (final log in logs.take(7)) {
      avgEnergy += log.energy;
      count++;
    }

    if (count > 0) {
      avgEnergy /= count;
    }

    if (avgEnergy < 2.5) {
      insights.add(Insight(
        category: 'Energy Levels',
        message: 'Your energy has been consistently low (average: ${avgEnergy.toStringAsFixed(1)}/5).',
        severity: 'note',
        suggestions: [
          'Check your sleep duration and quality',
          'Increase water intake throughout the day',
          'Try light exercise like a 20-minute walk',
          'Ensure you\'re eating balanced meals',
        ],
      ));
    }
  }

  void _detectWellnessMomentum(List<DailyLog> logs, List<Insight> insights) {
    if (logs.length < 7) return;

    final recentScores = logs
        .take(7)
        .map((l) => l.wellnessScore)
        .toList();

    recentScores.sort();
    final trend = recentScores.last - recentScores.first;

    if (trend > 1.0) {
      insights.add(Insight(
        category: 'Positive Momentum',
        message: 'Great job! Your wellness score has improved by ${trend.toStringAsFixed(1)} points this week.',
        severity: 'info',
        suggestions: [
          'Identify what\'s working well for you',
          'Keep up your current healthy habits',
          'Share your positive momentum with others',
          'Consider helping a friend improve their wellness',
        ],
      ));
    }
  }

  /// Format wellness score for display
  String formatScore(double score) => score.toStringAsFixed(1);

  /// Get wellness level based on score
  String getWellnessLevel(double score) {
    if (score >= 4.5) return 'Excellent';
    if (score >= 3.5) return 'Good';
    if (score >= 2.5) return 'Fair';
    if (score >= 1.5) return 'Need Support';
    return 'Concerning';
  }

  /// Get color recommendation for score visualization (as hex string)
  String getScoreColor(double score) {
    if (score >= 4.5) return '#4CAF50'; // Green
    if (score >= 3.5) return '#8BC34A'; // Light Green
    if (score >= 2.5) return '#FFC107'; // Amber
    if (score >= 1.5) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }
}
