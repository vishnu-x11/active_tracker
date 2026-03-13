import 'package:get/get.dart';
import 'package:active_tracker/data/models/sqlite/food_log.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';
import 'package:active_tracker/utils/date_utils.dart';

/// Manages nutrition tracking state and operations
class NutritionController extends GetxController {
  // ============ DEPENDENCIES ============
  final NutritionRepository _repository;

  // ============ OBSERVABLE STATE ============
  final foodLogs = <FoodLog>[].obs;
  final totalCalories = 0.0.obs;
  final totalProtein = 0.0.obs;
  final totalFat = 0.0.obs;
  final totalCarbs = 0.0.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final selectedDate = DateTime.now().obs;

  // ============ CONSTRUCTOR ============
  NutritionController(this._repository);

  // ============ LIFECYCLE ============
  @override
  void onInit() {
    super.onInit();
    print('✅ NutritionController initialized');
    loadFoodLogs();

    // Watch for date changes
    ever(selectedDate, (_) {
      loadFoodLogs();
    });
  }

  @override
  void onReady() {
    super.onReady();
    print('✅ NutritionController ready');
  }

  @override
  void onClose() {
    super.onClose();
    print('✅ NutritionController closed');
  }

  // ============ BUSINESS LOGIC ============

  /// Load food logs for selected date
  Future<void> loadFoodLogs() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final dateKey = DateUtils.getDateKey(date: selectedDate.value);
      final logs = await _repository.getFoodLogsForDate(dateKey);

      foodLogs.value = logs;
      _calculateTotals();

      print('✅ Loaded ${logs.length} food logs');
    } catch (e) {
      errorMessage.value = 'Failed to load food logs: $e';
      print('❌ Error loading food logs: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Add new food log
  Future<void> addFoodLog({
    required String foodName,
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    required double quantity,
    String? unit,
  }) async {
    try {
      isLoading.value = true;

      final now = DateTime.now();
      final dateKey = DateUtils.getDateKey(date: selectedDate.value);

      final foodLog = FoodLog(
        userId: 'current-user-id',  // TODO: Get from auth
        dateKey: dateKey,
        foodName: foodName,
        calories: calories,
        protein: protein,
        fat: fat,
        carbs: carbs,
        quantity: quantity,
        unit: unit,
        timestamp: now.millisecondsSinceEpoch,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      );

      await _repository.addFoodLog(foodLog);
      await loadFoodLogs();

      print('✅ Food log added: $foodName');
    } catch (e) {
      errorMessage.value = 'Failed to add food log: $e';
      print('❌ Error adding food log: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update existing food log
  Future<void> updateFoodLog(FoodLog foodLog) async {
    try {
      isLoading.value = true;

      final updated = foodLog.copyWith(
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _repository.updateFoodLog(updated);
      await loadFoodLogs();

      print('✅ Food log updated');
    } catch (e) {
      errorMessage.value = 'Failed to update food log: $e';
      print('❌ Error updating food log: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete food log
  Future<void> deleteFoodLog(int id) async {
    try {
      isLoading.value = true;

      await _repository.deleteFoodLog(id);
      await loadFoodLogs();

      print('✅ Food log deleted');
    } catch (e) {
      errorMessage.value = 'Failed to delete food log: $e';
      print('❌ Error deleting food log: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Change selected date
  void setSelectedDate(DateTime date) {
    selectedDate.value = date;
  }

  /// Get previous day
  void previousDay() {
    selectedDate.value = selectedDate.value.subtract(Duration(days: 1));
  }

  /// Get next day
  void nextDay() {
    selectedDate.value = selectedDate.value.add(Duration(days: 1));
  }

  /// Get today
  void goToday() {
    selectedDate.value = DateTime.now();
  }

  // ============ HELPER METHODS ============

  /// Calculate nutrition totals
  void _calculateTotals() {
    totalCalories.value = foodLogs.fold(
      0.0,
          (sum, log) => sum + log.calories,
    );

    totalProtein.value = foodLogs.fold(
      0.0,
          (sum, log) => sum + log.protein,
    );

    totalFat.value = foodLogs.fold(
      0.0,
          (sum, log) => sum + log.fat,
    );

    totalCarbs.value = foodLogs.fold(
      0.0,
          (sum, log) => sum + log.carbs,
    );
  }

  /// Check if calorie goal met
  bool isCalorieGoalMet(double goal) {
    return totalCalories.value >= (goal * 0.9);
  }

  /// Format calories for display
  String getCaloriesDisplay() => '${totalCalories.value.toStringAsFixed(0)} kcal';

  /// Get selected date as formatted string
  String getSelectedDateString() {
    final dateKey = DateUtils.getDateKey(date: selectedDate.value);
    return DateUtils.formatDateKey(dateKey);
  }
}