import 'package:cinmovies_app/core/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LibraryDonutProgress extends StatelessWidget {
  const LibraryDonutProgress({
    super.key,
    required this.progress,
    this.size = 82,
  });

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final progressValue = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              centerSpaceRadius: size * 0.34,
              sectionsSpace: 0,
              borderData: FlBorderData(show: false),
              sections: [
                PieChartSectionData(
                  value: progressValue,
                  color: AppColors.loginPrimary,
                  radius: size * 0.12,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: 1 - progressValue,
                  color: AppColors.surfaceBorder,
                  radius: size * 0.12,
                  showTitle: false,
                ),
              ],
            ),
            duration: const Duration(milliseconds: 450),
          ),
          Text(
            '${(progressValue * 100).round()}%',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
