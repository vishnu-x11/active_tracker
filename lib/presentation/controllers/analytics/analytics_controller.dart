import 'package:get/get.dart';
import '../../../data/local/sqlite_manager.dart';
import 'package:intl/intl.dart';

class AnalyticsController extends GetxController {
  final isLoading = false.obs;
  
  // Weekly data
  final weeklyCalorieData = <double>[].obs;
  final weeklyProteinData = <double>[].obs;
  final weeklyWorkoutData = <int>[].obs;
  final dayLabels = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchWeeklyData();
  }

  Future<void> fetchWeeklyData() async {
    try {
      isLoading.value = true;
      final db = SqliteManager.getInstance();
      
      final now = DateTime.now();
      final List<double> calories = [];
      final List<double> protein = [];
      final List<int> workouts = [];
      final List<String> labels = [];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        labels.add(DateFormat('E').format(date));

        // Fetch daily summary
        final List<Map<String, dynamic>> maps = await db.query(
          'daily_log_summary',
          where: 'dateKey = ?',
          whereArgs: [dateKey],
        );

        if (maps.isNotEmpty) {
          final map = maps.first;
          calories.add(map['totalCalories']?.toDouble() ?? 0.0);
          protein.add(map['totalProtein']?.toDouble() ?? 0.0);
          workouts.add(map['workoutMinutes']?.toInt() ?? 0);
        } else {
          calories.add(0.0);
          protein.add(0.0);
          workouts.add(0);
        }
      }

      weeklyCalorieData.value = calories;
      weeklyProteinData.value = protein;
      weeklyWorkoutData.value = workouts;
      dayLabels.value = labels;

    } catch (e) {
      print('❌ Error fetching analytics data: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
