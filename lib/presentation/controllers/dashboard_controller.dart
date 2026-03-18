import 'dart:async';
import 'package:get/get.dart';

import 'package:active_tracker/domain/repositories/repositories.dart';
import 'package:active_tracker/utils/date_utils.dart';

/// Manages dashboard state, daily goal progress, and sync status
class DashboardController extends GetxController {
  // ============ DEPENDENCIES ============
  final DailyLogRepository _dailyLogRepository;
  final OnboardingRepository _onboardingRepository;

  // ============ OBSERVABLE GOALS & PROGRESS ============
  final today = DateTime.now().obs;

  // Goal values
  final caloriesGoal = 2000.0.obs;
  final proteinGoal = 150.0.obs;
  final waterGoal = 2500.0.obs;
  final workoutGoal = 30.obs;
  final burnedCalorieGoal = 500.0.obs;

  // Today's progress
  final todayCalories = 0.0.obs;
  final todayProtein = 0.0.obs;
  final todayWater = 0.0.obs;
  final todayWorkoutMinutes = 0.obs;
  final todayWeight = 0.0.obs; // ✅ Added for dashboard card
  final todayBurnedCalories = 0.0.obs;

  // Progress percentages (0.0 to 1.0)
  final caloriesProgress = 0.0.obs;
  final proteinProgress = 0.0.obs;
  final waterProgress = 0.0.obs;
  final workoutProgress = 0.0.obs;
  final caloriesBurnedProgress = 0.0.obs;
  
  // Detailed macro breakdown
  final todayCarbs = 0.0.obs;
  final todayFat = 0.0.obs;
  final carbsGoal = 250.0.obs;
  final fatGoal = 65.0.obs;

  final streakCount = 0.obs;

  // ============ CONSTRUCTOR ============
  DashboardController(this._dailyLogRepository, this._onboardingRepository);

  // ============ SYNC STATUS ============
  final isOnline = true.obs; // ✅ Added
  final isSyncing = false.obs; // ✅ Added
  final lastSyncTime = Rx<DateTime?>(null); // ✅ Added

  // ============ UI STATE ============
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // ============ TIMERS ============
  Timer? _refreshTimer;

  // ============ LIFECYCLE ============
  @override
  void onInit() {
    super.onInit();
    print('✅ DashboardController initialized');
    loadDashboardData();

    // Refresh dashboard every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
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
    _refreshTimer?.cancel(); // ✅ Cancel timer on close
    super.onClose();
    print('✅ DashboardController closed');
  }

  // ============ LOAD DATA ============

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final dateKey = DateUtils.getDateKey(date: today.value);

      // 1. Load Goals from Profile
      final profile = await _onboardingRepository.getUserProfileSync();
      if (profile != null) {
        caloriesGoal.value = profile.calorieGoal;
        proteinGoal.value = profile.proteinGoal;
        waterGoal.value = profile.waterGoalMl.toDouble();
        burnedCalorieGoal.value = profile.burnedCalorieGoal;
      }

      // 2. Load Progress from Daily Summary
      final summary = await _dailyLogRepository.getDailyLogSummaryForDate(dateKey);
      if (summary != null) {
        todayCalories.value = summary.totalCalories;
        todayProtein.value = summary.totalProtein;
        todayCarbs.value = summary.totalCarbs;
        todayFat.value = summary.totalFat;
        todayWater.value = summary.totalWater;
        todayWorkoutMinutes.value = summary.workoutMinutes;
        todayBurnedCalories.value = summary.totalCaloriesBurned;
        todayWeight.value = summary.totalCaloriesBurned > 0 ? 0.0 : 0.0; // Placeholder logic
      }

      _calculateProgress();
      await calculateStreak();
      lastSyncTime.value = DateTime.now();
      print('✅ Dashboard data loaded for $dateKey');
    } catch (e) {
      errorMessage.value = 'Failed to load dashboard: $e';
      print('❌ Dashboard error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Update selected date
  Future<void> updateSelectedDate(DateTime date) async {
    today.value = date;
    await loadDashboardData();
  }

  /// Calculate user's current streak
  Future<void> calculateStreak() async {
    try {
      int streak = 0;
      DateTime checkDate = DateTime.now();
      
      while (true) {
        final dateKey = DateUtils.getDateKey(date: checkDate);
        final summary = await _dailyLogRepository.getDailyLogSummaryForDate(dateKey);
        
        if (summary != null && (summary.totalCalories > 0 || summary.workoutMinutes > 0 || summary.totalWater > 0)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          // If it's today and no data yet, don't break the streak from yesterday
          if (DateUtils.getDateKey(date: checkDate) == DateUtils.getDateKey(date: DateTime.now())) {
            checkDate = checkDate.subtract(const Duration(days: 1));
            continue;
          }
          break;
        }
        
        // Safety break
        if (streak > 365) break;
      }
      
      streakCount.value = streak;
    } catch (e) {
      print('⚠️ Error calculating streak: $e');
    }
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  // ============ PROGRESS CALCULATION ============

  /// Calculate progress percentages
  void _calculateProgress() {
    caloriesProgress.value = _clampProgress(todayCalories.value / caloriesGoal.value);
    proteinProgress.value = _clampProgress(todayProtein.value / proteinGoal.value);
    waterProgress.value = _clampProgress(todayWater.value / waterGoal.value);
    workoutProgress.value = _clampProgress(todayWorkoutMinutes.value / workoutGoal.value);
    caloriesBurnedProgress.value = _clampProgress(todayBurnedCalories.value / burnedCalorieGoal.value);
  }

  /// Clamp progress between 0 and 1
  double _clampProgress(double progress) {
    return progress.clamp(0.0, 1.0);
  }

  // ============ GOAL CHECKING ============

  /// Check if goal is met (90% or more for calories/protein, 100% for water/workout)
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
      case 'burned':
        return caloriesBurnedProgress.value >= 1.0;
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
    if (isGoalMet('burned')) count++;
    return count;
  }

  // ============ GOAL PROGRESS STRINGS ============

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
      case 'burned':
        return '${todayBurnedCalories.value.toStringAsFixed(0)} / ${burnedCalorieGoal.value.toStringAsFixed(0)} kcal';
      default:
        return '';
    }
  }

  /// Get goal remaining
  num getGoalRemaining(String goal) {
    switch (goal) {
      case 'calories':
        return remainingCalories;
      case 'protein':
        return (proteinGoal.value - todayProtein.value).clamp(0, double.infinity);
      case 'water':
        return (waterGoal.value - todayWater.value).clamp(0, double.infinity);
      case 'workout':
        return (workoutGoal.value - todayWorkoutMinutes.value).clamp(0, double.infinity);
      case 'burned':
        return (burnedCalorieGoal.value - todayBurnedCalories.value).clamp(0, double.infinity);
      default:
        return 0;
    }
  }

  /// Get remaining calories (Goal - Consumed + Exercise)
  double get remainingCalories {
    final remaining = caloriesGoal.value - todayCalories.value + todayBurnedCalories.value;
    return remaining.clamp(0, double.infinity);
  }

  /// Get goal status string
  String getGoalStatusString(String goal) {
    if (isGoalMet(goal)) {
      return '✅ Goal met!';
    } else {
      final remaining = getGoalRemaining(goal);
      if (remaining == 0) return '✅ Complete!';

      switch (goal) {
        case 'calories':
          return '${remainingCalories.toStringAsFixed(0)} left';
        case 'water':
          return '${remaining.toStringAsFixed(0)} ml left';
        case 'protein':
          return '${remaining.toStringAsFixed(1)}g left';
        case 'workout':
          return '${remaining.toStringAsFixed(0)} min left';
        case 'burned':
          return '${remaining.toStringAsFixed(0)} kcal left';
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

  // ============ SYNC STATUS HELPERS ============

  /// Update sync status
  void updateSyncStatus({required bool isOnlineNow, required bool syncing}) {
    isOnline.value = isOnlineNow;
    isSyncing.value = syncing;
    if (!syncing && isOnlineNow) {
      lastSyncTime.value = DateTime.now();
    }
  }

  /// Mark as online
  void markAsOnline() {
    isOnline.value = true;
  }

  /// Mark as offline
  void markAsOffline() {
    isOnline.value = false;
  }

  /// Start sync
  void startSync() {
    isSyncing.value = true;
  }

  /// End sync
  void endSync() {
    isSyncing.value = false;
    lastSyncTime.value = DateTime.now();
  }

  // ============ NAVIGATION ============

  /// Navigate to nutrition screen
  void navigateToNutrition() {
    Get.toNamed('/nutrition');
  }

  /// Navigate to training screen
  void navigateToTraining() {
    Get.toNamed('/training');
  }

  /// Navigate to hydration screen
  void navigateToHydration() {
    Get.toNamed('/hydration');
  }

  /// Navigate to BMI screen
  void navigateToBmi() {
    Get.toNamed('/bmi');
  }

  /// Navigate to settings screen
  void navigateToSettings() {
    Get.toNamed('/settings');
  }
}