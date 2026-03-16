import 'package:get/get.dart';

class MetricEntry {
  final DateTime date;
  final double value;

  MetricEntry({required this.date, required this.value});
}

class BodyMetricsController extends GetxController {
  final weightEntries = <MetricEntry>[].obs;
  final bodyFatEntries = <MetricEntry>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadMetrics();
  }

  void loadMetrics() {
    // Mock historical data for trends
    final now = DateTime.now();
    weightEntries.value = List.generate(7, (i) => MetricEntry(
      date: now.subtract(Duration(days: 6 - i)),
      value: 82.0 - (i * 0.2), // Mock weight loss
    ));

    bodyFatEntries.value = List.generate(7, (i) => MetricEntry(
      date: now.subtract(Duration(days: 6 - i)),
      value: 22.0 - (i * 0.1), // Mock BF% loss
    ));
  }

  void addEntry(double weight, double bodyFat) {
    final now = DateTime.now();
    weightEntries.add(MetricEntry(date: now, value: weight));
    bodyFatEntries.add(MetricEntry(date: now, value: bodyFat));
  }
}
