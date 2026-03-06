class ReportDataPoint {
  final DateTime date;
  final double? moodValence;
  final String? moodQuadrant;
  final double? recoveryScore;

  const ReportDataPoint({
    required this.date,
    this.moodValence,
    this.moodQuadrant,
    this.recoveryScore,
  });
}

enum ReportRange { daily, weekly }
