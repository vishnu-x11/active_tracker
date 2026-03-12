import 'dart:async';

import 'package:get/get.dart';

/// Manages dashboard state and daily goal progress
class DashboardController extends GetxController {
  // ============ OBSERVABLE STATE ============
  final today = DateTime.now().obs;

  // Goals
  final caloriesGoal = 2000.0.obs;
  final proteinGoal = 150.0.obs;
  final waterGoal = 2500.0.obs;
  final workoutGoal = 30.obs;

  // Today's progress
  final todayCalories = 0.0.obs;
  final todayProtein = 0.0.obs;
  final todayWater = 0.0.obs;
  final todayWorkoutMinutes = 0.obs;

  // Progress percentages (0.0 to 1.0)
  final caloriesProgress = 0.0.obs;
  final proteinProgress = 0.0.obs;
  final waterProgress = 0.0.obs;
  final workoutProgress = 0.0.obs;

  // UI state
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // ============ LIFECYCLE ============
  @override
  void onInit() {
    super.onInit();
    print('✅ DashboardController initialized');
    loadDashboardData();

    // Refresh dashboard every minute

    Timer.periodic(const Duration(minutes: 1), (_) {
      if (!isLoading.value) {
        loadDashboardData();
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    print('✅ DashboardController ready');
  }

  @override
  void onClose() {
    super.onClose();
    print('✅ DashboardController closed');
  }

  // ============ BUSINESS LOGIC ============

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // TODO: Load data from repositories
      // 1. Load nutrition progress
      // 2. Load hydration progress
      // 3. Load training progress
      // 4. Load BMI/weight progress
      // 5. Load goals

      // For now, simulating loaded data
      _calculateProgress();

      print('✅ Dashboard data loaded');
    } catch (e) {
      errorMessage.value = 'Failed to load dashboard: $e';
      print('❌ Dashboard error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  /// Calculate progress percentages
  void _calculateProgress() {
    caloriesProgress.value = _clampProgress(todayCalories.value / caloriesGoal.value);
    proteinProgress.value = _clampProgress(todayProtein.value / proteinGoal.value);
    waterProgress.value = _clampProgress(todayWater.value / waterGoal.value);
    workoutProgress.value = _clampProgress(todayWorkoutMinutes.value / workoutGoal.value);
  }

  /// Clamp progress between 0 and 1
  double _clampProgress(double progress) {
    return progress.clamp(0.0, 1.0);
  }

  // ============ HELPER METHODS ============

  /// Check if goal is met (90% or more)
  bool isGoalMet(String goal) {
    switch (goal) {
      case 'calories':
        return caloriesProgress.value >= 0.9;
      case 'protein':
        return proteinProgress.value >= 0.9;
      case 'water':
        return waterProgress.value >= 1.0;
      case 'workout':
        return workoutProgress.value >= 1.0;
      default:
        return false;
    }
  }

  /// Get number of goals met today
  int getGoalsMet() {
    int count = 0;
    if (isGoalMet('calories')) count++;
    if (isGoalMet('protein')) count++;
    if (isGoalMet('water')) count++;
    if (isGoalMet('workout')) count++;
    return count;
  }

  /// Get goal progress string
  String getGoalProgressString(String goal) {
    switch (goal) {
      case 'calories':
        return '${todayCalories.value.toStringAsFixed(0)} / ${caloriesGoal.value.toStringAsFixed(0)} kcal';
      case 'protein':
        return '${todayProtein.value.toStringAsFixed(0)} / ${proteinGoal.value.toStringAsFixed(0)}g';
      case 'water':
        return '${todayWater.value.toStringAsFixed(0)} / ${waterGoal.value.toStringAsFixed(0)} ml';
      case 'workout':
        return '${todayWorkoutMinutes.value} / ${workoutGoal.value} min';
      default:
        return '';
    }
  }

  /// Get goal remaining
  num getGoalRemaining(String goal) {
    switch (goal) {
      case 'calories':
        return (caloriesGoal.value - todayCalories.value).clamp(0, double.infinity);
      case 'protein':
        return (proteinGoal.value - todayProtein.value).clamp(0, double.infinity);
      case 'water':
        return (waterGoal.value - todayWater.value).clamp(0, double.infinity);
      case 'workout':
        return (workoutGoal.value - todayWorkoutMinutes.value).clamp(0, double.infinity);
      default:
        return 0;
    }
  }

  /// Is goal met string
  String getGoalStatusString(String goal) {
    if (isGoalMet(goal)) {
      return '✅ Goal met!';
    } else {
      final remaining = getGoalRemaining(goal);
      if (remaining == 0) return '✅ Complete!';

      switch (goal) {
        case 'calories':
        case 'water':
          return '${remaining.toStringAsFixed(0)} left';
        case 'protein':
          return '${remaining.toStringAsFixed(1)}g left';
        case 'workout':
          return '${remaining.toStringAsFixed(0)} min left';
        default:
          return '';
      }
    }
  }

  /// Get motivational message
  String getMotivationalMessage() {
    final goalsMet = getGoalsMet();
    switch (goalsMet) {
      case 0:
        return 'Start your day strong! 💪';
      case 1:
        return 'Great start! Keep it up! 🔥';
      case 2:
        return 'You\'re doing amazing! 🌟';
      case 3:
        return 'Almost there! One more goal! 🎯';
      case 4:
        return 'Perfect day! All goals met! 🏆';
      default:
        return 'Keep going! 💪';
    }
  }
}