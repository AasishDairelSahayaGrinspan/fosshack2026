import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/report_data.dart';

class CombinedOverlayChart extends StatelessWidget {
  final List<ReportDataPoint> dataPoints;
  const CombinedOverlayChart({super.key, required this.dataPoints});

  Color _quadrantColor(String? quadrant) {
    switch (quadrant) {
      case 'highEnergyPleasant':
        return AppColors.highEnergyPleasant;
      case 'highEnergyUnpleasant':
        return AppColors.highEnergyUnpleasant;
      case 'lowEnergyUnpleasant':
        return AppColors.lowEnergyUnpleasant;
      case 'lowEnergyPleasant':
        return AppColors.lowEnergyPleasant;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodSpots = <FlSpot>[];
    final recoverySpots = <FlSpot>[];
    final moodColors = <Color>[];

    for (int i = 0; i < dataPoints.length; i++) {
      final dp = dataPoints[i];
      if (dp.moodValence != null) {
        moodSpots.add(FlSpot(i.toDouble(), dp.moodValence!));
        moodColors.add(_quadrantColor(dp.moodQuadrant));
      }
      if (dp.recoveryScore != null) {
        recoverySpots.add(FlSpot(i.toDouble(), dp.recoveryScore! / 100));
      }
    }

    return LineChart(
      LineChartData(
        minY: -1,
        maxY: 1,
        lineBarsData: [
          if (moodSpots.isNotEmpty)
            LineChartBarData(
              spots: moodSpots,
              isCurved: true,
              color: Colors.purple,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, index) => FlDotCirclePainter(
                  radius: 5,
                  color: index < moodColors.length
                      ? moodColors[index]
                      : Colors.purple,
                  strokeWidth: 0,
                ),
              ),
            ),
          if (recoverySpots.isNotEmpty)
            LineChartBarData(
              spots: recoverySpots,
              isCurved: true,
              color: Colors.teal,
              barWidth: 2,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
            ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 1) return const Text('Pleasant');
                if (value == 0) return const Text('Neutral');
                if (value == -1) return const Text('Unpleasant');
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 1) return const Text('100');
                if (value == 0.5) return const Text('50');
                if (value == 0) return const Text('0');
                return const Text('');
              },
            ),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }
}
