import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/analytics/analytics_controller.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

class AnalyticsScreen extends GetView<AnalyticsController> {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Insights'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInsightCard('Calories Trend', _buildCalorieChart()),
              const SizedBox(height: AppPadding.lg),
              _buildInsightCard('Protein Intake (g)', _buildProteinChart()),
              const SizedBox(height: AppPadding.lg),
              _buildInsightCard('Workout Duration (min)', _buildWorkoutChart()),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInsightCard(String title, Widget chart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppPadding.xl),
            SizedBox(
              height: 200,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: controller.weeklyCalorieData.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value);
            }).toList(),
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProteinChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 200,
        barTouchData: BarTouchData(enabled: false),
        titlesData: _buildTitlesData(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: controller.weeklyProteinData.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value,
                color: AppTheme.success,
                width: 15,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWorkoutChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: _buildTitlesData(),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: controller.weeklyWorkoutData.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.toDouble());
            }).toList(),
            isCurved: true,
            color: AppTheme.accent,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.accent.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            int index = value.toInt();
            if (index >= 0 && index < controller.dayLabels.length) {
              return Text(
                controller.dayLabels[index],
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}
