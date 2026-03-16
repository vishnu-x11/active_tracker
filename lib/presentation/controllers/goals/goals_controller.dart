import 'package:get/get.dart';

class UserGoal {
  final String type; // 'Weight', 'Steps', 'Calories'
  final double target;
  final double current;
  final String unit;

  UserGoal({
    required this.type,
    required this.target,
    required this.current,
    required this.unit,
  });
}

class GoalsController extends GetxController {
  final isLoading = false.obs;
  final goals = <UserGoal>[].obs;
  final predictedDaysToGoal = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchGoals();
  }

  void fetchGoals() {
    // Mock data for v4.0
    goals.value = [
      UserGoal(type: 'Weight', target: 75.0, current: 82.0, unit: 'kg'),
      UserGoal(type: 'Steps', target: 10000, current: 6500, unit: 'steps'),
      UserGoal(type: 'Calories', target: 2000, current: 1850, unit: 'kcal'),
    ];
    
    _calculatePrediction();
  }

  void _calculatePrediction() {
    // Simple "AI" heuristic for prediction
    // If losing 0.5kg per week (mock rate), calculate days
    final weightGoal = goals.firstWhere((g) => g.type == 'Weight');
    final diff = weightGoal.current - weightGoal.target;
    if (diff > 0) {
      // Assume 0.1kg per day loss on average
      predictedDaysToGoal.value = (diff / 0.1).round();
    } else {
      predictedDaysToGoal.value = 0;
    }
  }

  Future<void> updateGoal(String type, double newTarget) async {
    // In real app, update DB
    final index = goals.indexWhere((g) => g.type == type);
    if (index != -1) {
      final old = goals[index];
      goals[index] = UserGoal(
        type: old.type,
        target: newTarget,
        current: old.current,
        unit: old.unit,
      );
      _calculatePrediction();
    }
  }
}
