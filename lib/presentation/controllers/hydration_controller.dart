import 'package:get/get.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';
import 'package:active_tracker/data/models/hive/water_log_model.dart';
import 'package:active_tracker/utils/date_utils.dart';
import 'package:active_tracker/presentation/controllers/dashboard_controller.dart';

/// Manages hydration tracking and water intake
class HydrationController extends GetxController {
  // ============ DEPENDENCIES ============
  final HydrationRepository _repository;
  final DailyLogRepository _dailyLogRepository;

  // ============ OBSERVABLE STATE ============
  final totalWater = 0.0.obs;
  final waterGoal = 2500.0.obs;
  final waterProgress = 0.0.obs;
  final waterLogs = <WaterLogModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final selectedDate = DateTime.now().obs;

  // ============ CONSTRUCTOR ============
  HydrationController(this._repository, this._dailyLogRepository);

  // ============ LIFECYCLE ============
  @override
  void onInit() {
    super.onInit();
    print('✅ HydrationController initialized');
    loadHydrationData();

    // Watch for date changes
    ever(selectedDate, (_) {
      loadHydrationData();
    });
  }

  @override
  void onReady() {
    super.onReady();
    print('✅ HydrationController ready');
  }

  @override
  void onClose() {
    super.onClose();
    print('✅ HydrationController closed');
  }

  // ============ BUSINESS LOGIC ============

  /// Load hydration data for selected date
  Future<void> loadHydrationData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final dateKey = DateUtils.getDateKey(date: selectedDate.value);

      totalWater.value = await _repository.getTotalWaterForDate(dateKey);
      waterGoal.value = await _repository.getWaterGoal();
      waterLogs.value = await _repository.getWaterLogsForDate(dateKey);

      _updateProgress();
      print('✅ Hydration data loaded: ${totalWater.value}ml');
    } catch (e) {
      errorMessage.value = 'Failed to load hydration data: $e';
      print('❌ Hydration error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Log water intake
  Future<void> logWater(double ml) async {
    try {
      isLoading.value = true;

      final dateKey = DateUtils.getDateKey(date: selectedDate.value);
      await _repository.logWaterIntake(dateKey, ml);
      await _dailyLogRepository.calculateAndSaveDailySummary(dateKey);
      await loadHydrationData();
      _refreshDashboard();

      print('✅ Water logged: ${ml}ml');
    } catch (e) {
      errorMessage.value = 'Failed to log water: $e';
      print('❌ Error logging water: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Quick log common amounts
  Future<void> logQuickWater(String amount) async {
    double ml = 0.0;
    switch (amount) {
      case 'glass':
        ml = 250; // 1 glass = 250ml
        break;
      case 'bottle':
        ml = 500; // 1 bottle = 500ml
        break;
      case 'liter':
        ml = 1000; // 1 liter = 1000ml
        break;
    }

    if (ml > 0) {
      await logWater(ml);
    }
  }

  /// Update water goal
  Future<void> setWaterGoal(double newGoal) async {
    try {
      // Update local goal
      waterGoal.value = newGoal;
      _updateProgress();

      // TODO: Phase 6 - Optionally save to preferences/repository
      // await _repository.setWaterGoal(newGoal);

      print('✅ Water goal updated: ${newGoal}ml');
    } catch (e) {
      errorMessage.value = 'Failed to update goal: $e';
      print('❌ Error updating water goal: $e');
      rethrow;
    }
  }

  /// Update water log amount
  Future<void> updateWaterAmount(WaterLogModel log, double newAmount) async {
    try {
      isLoading.value = true;
      final updatedLog = log.copyWith(mlConsumed: newAmount);
      await _repository.updateWaterLog(updatedLog);
      
      final dateKey = DateUtils.getDateKey(date: selectedDate.value);
      await _dailyLogRepository.calculateAndSaveDailySummary(dateKey);
      await loadHydrationData();
      _refreshDashboard();
      
      print('✅ Water log updated to ${newAmount}ml');
    } catch (e) {
      errorMessage.value = 'Failed to update water: $e';
      print('❌ Error updating water: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete water log
  Future<void> deleteLog(WaterLogModel log) async {
    try {
      isLoading.value = true;
      await _repository.deleteWaterLog(log);
      
      final dateKey = DateUtils.getDateKey(date: selectedDate.value);
      await _dailyLogRepository.calculateAndSaveDailySummary(dateKey);
      await loadHydrationData();
      _refreshDashboard();
      
      print('✅ Water log deleted');
    } catch (e) {
      errorMessage.value = 'Failed to delete water: $e';
      print('❌ Error deleting water: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // ============ HELPER METHODS ============

  /// Update water progress
  void _updateProgress() {
    waterProgress.value = (totalWater.value / waterGoal.value).clamp(0, 1);
  }

  /// Navigate to previous day
  void previousDay() {
    selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));
  }

  /// Navigate to next day
  void nextDay() {
    selectedDate.value = selectedDate.value.add(const Duration(days: 1));
  }

  /// Go to today
  void goToday() {
    selectedDate.value = DateTime.now();
  }

  /// Get formatted date
  String getSelectedDateString() {
    final dateKey = DateUtils.getDateKey(date: selectedDate.value);
    return DateUtils.formatDateKey(dateKey);
  }

  /// Check if water goal is met
  bool isGoalMet() => waterProgress.value >= 1.0;

  /// Get remaining water amount
  double getRemainingWater() {
    return (waterGoal.value - totalWater.value).clamp(0, double.infinity);
  }

  /// Get water logged string
  String getWaterLoggedString() => '${totalWater.value.toStringAsFixed(0)} ml';

  /// Get water goal string
  String getWaterGoalString() => '${waterGoal.value.toStringAsFixed(0)} ml';

  /// Get remaining water string
  String getRemainingWaterString() {
    final remaining = getRemainingWater();
    if (remaining <= 0) return '✅ Goal met!';
    return '${remaining.toStringAsFixed(0)} ml left';
  }

  /// Get water cups consumed (assuming 250ml per cup)
  int getCupsConsumed() => (totalWater.value / 250).toInt();

  /// Get cups needed (assuming 250ml per cup)
  int getCupsNeeded() => (waterGoal.value / 250).toInt();

  /// Get glasses progress
  String getGlassesProgressString() => '${getCupsConsumed()}/${getCupsNeeded()} glasses';

  /// Get motivational message
  String getMotivationalMessage() {
    if (isGoalMet()) {
      return '💧 Hydration goal met! Great job!';
    }

    final remaining = getRemainingWater();
    final cups = (remaining / 250).ceil();

    if (remaining <= 250) {
      return '🎯 Just 1 more glass!';
    } else if (remaining <= 750) {
      return '💪 Keep it up, $cups glasses to go!';
    } else {
      return '💧 Start hydrating! $cups glasses left!';
    }
  }

  /// Trigger dashboard refresh
  void _refreshDashboard() {
    try {
      if (Get.isRegistered<DashboardController>(tag: 'dashboard')) {
        Get.find<DashboardController>(tag: 'dashboard').loadDashboardData();
      }
    } catch (e) {
      print('⚠️ Could not refresh dashboard from HydrationController: $e');
    }
  }
}