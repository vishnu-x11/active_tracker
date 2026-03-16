import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/body_metrics/body_metrics_controller.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

class BodyMetricsScreen extends GetView<BodyMetricsController> {
  const BodyMetricsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Metrics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartSection(context, 'Weight Trend (kg)', controller.weightEntries, AppTheme.primary),
            const SizedBox(height: AppPadding.xl),
            _buildChartSection(context, 'Body Fat %', controller.bodyFatEntries, AppTheme.accent),
            const SizedBox(height: AppPadding.xl),
            _buildInputSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, String title, RxList<MetricEntry> entries, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.white)),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.only(right: 16, top: 16),
          decoration: BoxDecoration(
            color: AppTheme.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Obx(() => LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: entries.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
                  isCurved: true,
                  color: color,
                  barWidth: 4,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildInputSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Log New Entry', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.white)),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: TextField(decoration: InputDecoration(labelText: 'Weight (kg)'))),
                SizedBox(width: 16),
                Expanded(child: TextField(decoration: InputDecoration(labelText: 'Body Fat %'))),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.snackbar('Logged', 'Your metrics have been updated.');
                },
                child: const Text('UPDATE METRICS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
