import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/noise_reading.dart';
import '../theme/app_theme.dart';

/// Mini chart sparkline untuk deret waktu 10-30 menit terakhir
class SparklineWidget extends StatelessWidget {
  final List<NoiseReading> readings;
  final double height;

  const SparklineWidget({
    super.key,
    required this.readings,
    this.height = 70.0,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Menunggu aliran data telemetri...',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < readings.length; i++) {
      spots.add(FlSpot(i.toDouble(), readings[i].leqDba));
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: 40,
          maxY: 95,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: AppTheme.primaryBlue,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryBlue.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
