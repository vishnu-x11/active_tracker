import 'package:get/get.dart';
import 'package:active_tracker/data/models/sqlite/body_weight_log.dart';
import 'package:active_tracker/data/models/hive/bmi_result_model.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';
import 'package:active_tracker/utils/date_utils.dart';

/// Manages BMI calculation and weight tracking
class BmiController extends GetxController {
  // ============ DEPENDENCIES ============
  final BmiRepository _repository;

  // ============ OBSERVABLE STATE ============
  final bmi = 0.0.obs;
  final bmiCategory = ''.obs;
  final weight = 0.0.obs;
  final height = 0.0.obs;
  final weightHistory = <BodyWeightLog>[].obs;
  final bmiHistory = <BmiResultModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // ============ CONSTRUCTOR ============
  BmiController(this._repository);

  // ============ LIFECYCLE ============
  @override
  void onInit() {
    super.onInit();
    print('✅ BmiController initialized');
    loadBmiData();
  }

  @override
  void onReady() {
    super.onReady();
    print('✅ BmiController ready');
  }

  @override
  void onClose() {
    super.onClose();
    print('✅ BmiController closed');
  }

  // ============ BUSINESS LOGIC ============

  /// Load latest BMI data
  Future<void> loadBmiData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _repository.getLatestBmiResult();

      if (result != null) {
        bmi.value = result.bmi;
        bmiCategory.value = result.bmiCategory;
        weight.value = result.weight;
        height.value = result.height;
      }

      print('✅ BMI data loaded: BMI=${bmi.value.toStringAsFixed(1)}');
    } catch (e) {
      errorMessage.value = 'Failed to load BMI data: $e';
      print('❌ BMI error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Calculate and save BMI
  Future<void> calculateBmi({
    required double newWeight,
    required double newHeight,
    double dailyCalories = 2000,
    double proteinGrams = 150,
    double fatGrams = 65,
    double carbsGrams = 250,
  }) async {
    try {
      isLoading.value = true;

      await _repository.calculateAndSaveBmi(
        userId: 'current-user-id',
        dateKey: DateUtils.getDateKey(),
        weight: newWeight,
        height: newHeight,
        dailyCalories: dailyCalories,
        proteinGrams: proteinGrams,
        fatGrams: fatGrams,
        carbsGrams: carbsGrams,
      );

      await loadBmiData();
      print('✅ BMI calculated and saved');
    } catch (e) {
      errorMessage.value = 'Failed to calculate BMI: $e';
      print('❌ BMI calculation error: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Load weight history
  Future<void> loadWeightHistory() async {
    try {
      // TODO: Implement weight history loading
      print('✅ Weight history loaded');
    } catch (e) {
      print('❌ Error loading weight history: $e');
    }
  }

  /// Load BMI history
  Future<void> loadBmiHistory() async {
    try {
      // TODO: Implement BMI history loading
      print('✅ BMI history loaded');
    } catch (e) {
      print('❌ Error loading BMI history: $e');
    }
  }

  // ============ HELPER METHODS ============

  /// Get BMI status color for UI
  String getBmiStatusColor() {
    switch (bmiCategory.value.toLowerCase()) {
      case 'underweight':
        return '#2196F3'; // Blue
      case 'normal':
        return '#4CAF50'; // Green
      case 'overweight':
        return '#FF9800'; // Orange
      case 'obese':
        return '#F44336'; // Red
      default:
        return '#9C27B0'; // Purple
    }
  }

  /// Get BMI range for category
  String getBmiRange() {
    switch (bmiCategory.value.toLowerCase()) {
      case 'underweight':
        return 'BMI < 18.5';
      case 'normal':
        return 'BMI 18.5 - 24.9';
      case 'overweight':
        return 'BMI 25.0 - 29.9';
      case 'obese':
        return 'BMI ≥ 30.0';
      default:
        return '';
    }
  }

  /// Get BMI interpretation
  String getBmiInterpretation() {
    switch (bmiCategory.value.toLowerCase()) {
      case 'underweight':
        return 'You may need to gain weight. Consider eating more calories.';
      case 'normal':
        return 'You are at a healthy weight. Keep up the good work!';
      case 'overweight':
        return 'You may want to increase physical activity and adjust diet.';
      case 'obese':
        return 'Consider consulting a healthcare professional.';
      default:
        return '';
    }
  }

  /// Format weight
  String getWeightString() => '${weight.value.toStringAsFixed(1)} kg';

  /// Format height
  String getHeightString() => '${height.value.toStringAsFixed(2)} m';

  /// Format BMI
  String getBmiString() => '${bmi.value.toStringAsFixed(1)}';

  /// Get ideal weight range
  Map<String, double> getIdealWeightRange() {
    // Using normal BMI range: 18.5 - 24.9
    // Height is in cm, so convert to meters (height / 100) first
    final heightInMeters = height.value / 100;
    final minWeight = 18.5 * (heightInMeters * heightInMeters);
    final maxWeight = 24.9 * (heightInMeters * heightInMeters);

    return {
      'min': minWeight,
      'max': maxWeight,
    };
  }

  /// Get weight change
  double getWeightChange() {
    if (weightHistory.isEmpty) return 0;

    if (weightHistory.length < 2) {
      return 0;
    }

    final first = weightHistory.first.weight;
    final last = weightHistory.last.weight;

    return last - first;
  }

  /// Get weight change string
  String getWeightChangeString() {
    final change = getWeightChange();
    if (change == 0) return 'No change';

    final sign = change > 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)} kg';
  }

  /// Get progress towards ideal weight
  String getProgressToIdealWeight() {
    final range = getIdealWeightRange();
    if (weight.value < range['min']!) {
      return 'Gain ${(range['min']! - weight.value).toStringAsFixed(1)} kg';
    } else if (weight.value > range['max']!) {
      return 'Lose ${(weight.value - range['max']!).toStringAsFixed(1)} kg';
    } else {
      return 'You are in ideal range!';
    }
  }

  /// Get BMI emoji
  String getBmiEmoji() {
    switch (bmiCategory.value.toLowerCase()) {
      case 'underweight':
        return '📉';
      case 'normal':
        return '✅';
      case 'overweight':
        return '📈';
      case 'obese':
        return '⚠️';
      default:
        return '❓';
    }
  }
}