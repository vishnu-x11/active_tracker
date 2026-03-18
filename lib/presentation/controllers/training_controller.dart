import 'package:flutter/material.dart' hide DateUtils;
import 'package:get/get.dart';
import 'package:active_tracker/data/models/sqlite/workout_log.dart';
import 'package:active_tracker/data/models/sqlite/exercise.dart';
import 'package:active_tracker/data/models/sqlite/exercise_definition.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';
import 'package:active_tracker/utils/date_utils.dart';
import 'package:active_tracker/presentation/controllers/auth_controller.dart';
import 'package:active_tracker/presentation/controllers/dashboard_controller.dart';
import 'package:active_tracker/utils/health_utils.dart';

/// Manages training data and workout tracking
class TrainingController extends GetxController {
  // ============ DEPENDENCIES ============
  final TrainingRepository _repository;
  final DailyLogRepository _dailyLogRepository;

  // ============ OBSERVABLE STATE ============
  final workoutLogs = <WorkoutLog>[].obs;
  final exercises = <Exercise>[].obs;
  final totalDuration = 0.obs;
  final totalCaloriesBurned = 0.0.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final selectedDate = DateTime.now().obs;
  
  // Exercise Categorization
  final categories = <String>[
    'Pushups',
    'Pullups',
    'Shoulder',
    'Triceps',
    'Fore Arms',
    'Biceps',
    'Leg',
    'Abs',
    'Back',
    'Chest',
    'General',
    'Cardio'
  ].obs;
  final selectedCategory = ''.obs;
  final exercisesByCategory = <ExerciseDefinition>[].obs;
  final exerciseSuggestions = <ExerciseDefinition>[].obs;
  final isSearching = false.obs;

  // ============ CONSTRUCTOR ============
  TrainingController(this._repository, this._dailyLogRepository);

  // ============ LIFECYCLE ============
  @override
  void onInit() {
    super.onInit();
    print('✅ TrainingController initialized');
    loadTrainingData();

    // Watch for date changes
    ever(selectedDate, (_) {
      loadTrainingData();
    });
  }

  @override
  void onReady() {
    super.onReady();
    print('✅ TrainingController ready');
  }

  @override
  void onClose() {
    super.onClose();
    print('✅ TrainingController closed');
  }

  // ============ BUSINESS LOGIC ============

  /// Load training data for selected date
  Future<void> loadTrainingData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final dateKey = DateUtils.getDateKey(date: selectedDate.value);

      final logs = await _repository.getWorkoutLogsForDate(dateKey);
      final exs = await _repository.getExercisesForDate(dateKey);

      workoutLogs.value = logs;
      exercises.value = exs;

      _calculateTotals();
      print('✅ Training data loaded: ${logs.length} workouts, ${exs.length} exercises');
    } catch (e) {
      errorMessage.value = 'Failed to load training data: $e';
      print('❌ Training error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Add new workout
  Future<void> addWorkout({
    required String workoutName,
    required int duration,
    required double caloriesBurned,
    String? notes,
  }) async {
    try {
      isLoading.value = true;

      final now = DateTime.now();
      final dateKey = DateUtils.getDateKey(date: selectedDate.value);

      final workout = WorkoutLog(
        userId: Get.find<AuthController>().userId.value,
        dateKey: dateKey,
        workoutName: workoutName,
        duration: duration,
        caloriesBurned: caloriesBurned,
        notes: notes,
        timestamp: now.millisecondsSinceEpoch,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      );

      await _repository.addWorkoutLog(workout);
      await _dailyLogRepository.calculateAndSaveDailySummary(dateKey);
      await loadTrainingData();
      _refreshDashboard();

      print('✅ Workout added: $workoutName');
    } catch (e) {
      errorMessage.value = 'Failed to add workout: $e';
      print('❌ Error adding workout: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update existing workout
  Future<void> updateWorkout(WorkoutLog log) async {
    try {
      isLoading.value = true;
      await _repository.updateWorkoutLog(log);
      await _dailyLogRepository.calculateAndSaveDailySummary(log.dateKey);
      await loadTrainingData();
      _refreshDashboard();
      print('✅ Workout updated: ${log.workoutName}');
    } catch (e) {
      errorMessage.value = 'Failed to update workout: $e';
      print('❌ Error updating workout: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Add exercise to workout
  /// Parameters: exerciseType, reps, sets, optional weight (kg)
  Future<void> addExercise({
    required String exerciseType,
    required String category,
    required int reps,
    required int sets,
    double? weight,
  }) async {
    try {
      isLoading.value = true;

      final now = DateTime.now();
      final dateKey = DateUtils.getDateKey(date: selectedDate.value);

      final exercise = Exercise(
        userId: Get.find<AuthController>().userId.value,
        dateKey: dateKey,
        exerciseType: exerciseType,
        category: category,
        reps: reps,
        sets: sets,
        weight: weight,
        timestamp: now.millisecondsSinceEpoch,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      );

      await _repository.addExercise(exercise);
      await _dailyLogRepository.calculateAndSaveDailySummary(dateKey);
      await loadTrainingData();
      _refreshDashboard();

      print('✅ Exercise added: $exerciseType ($reps reps x $sets sets)');
    } catch (e) {
      errorMessage.value = 'Failed to add exercise: $e';
      print('❌ Error adding exercise: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete workout
  Future<void> deleteWorkout(int id) async {
    try {
      isLoading.value = true;
      await _repository.deleteWorkoutLog(id);
      final dateKey = DateUtils.getDateKey(date: selectedDate.value);
      await _dailyLogRepository.calculateAndSaveDailySummary(dateKey);
      await loadTrainingData();
      _refreshDashboard();
      print('✅ Workout deleted');
    } catch (e) {
      errorMessage.value = 'Failed to delete workout: $e';
      print('❌ Error deleting workout: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update existing exercise
  Future<void> updateExercise(Exercise exercise) async {
    try {
      isLoading.value = true;
      await _repository.updateExercise(exercise);
      final dateKey = DateUtils.getDateKey(date: selectedDate.value);
      await _dailyLogRepository.calculateAndSaveDailySummary(dateKey);
      await loadTrainingData();
      _refreshDashboard();
      print('✅ Exercise updated: ${exercise.exerciseType}');
    } catch (e) {
      errorMessage.value = 'Failed to update exercise: $e';
      print('❌ Error updating exercise: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete exercise
  Future<void> deleteExercise(int id) async {
    try {
      isLoading.value = true;
      await _repository.deleteExercise(id);
      final dateKey = DateUtils.getDateKey(date: selectedDate.value);
      await _dailyLogRepository.calculateAndSaveDailySummary(dateKey);
      await loadTrainingData();
      _refreshDashboard();
      print('✅ Exercise deleted');
    } catch (e) {
      errorMessage.value = 'Failed to delete exercise: $e';
      print('❌ Error deleting exercise: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // ============ HELPER METHODS ============

  /// Calculate totals
  void _calculateTotals() {
    // 1. Sum up general workout sessions
    int workoutDuration = workoutLogs.fold(
      0,
          (sum, log) => sum + log.duration,
    );

    double workoutCalories = workoutLogs.fold(
      0.0,
          (sum, log) => sum + log.caloriesBurned,
    );

    // 2. Sum up individual exercise estimates
    int exerciseDuration = exercises.fold(
      0,
          (sum, ex) => sum + HealthUtils.estimateExerciseDuration(ex),
    );

    double exerciseCalories = exercises.fold(
      0.0,
          (sum, ex) => sum + HealthUtils.estimateExerciseCalories(ex),
    );

    // 3. Update reactive totals
    totalDuration.value = workoutDuration + exerciseDuration;
    totalCaloriesBurned.value = workoutCalories + exerciseCalories;
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

  /// Select date using calendar picker
  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate.value) {
      selectedDate.value = picked;
    }
  }

  /// Get formatted date
  String getSelectedDateString() {
    final dateKey = DateUtils.getDateKey(date: selectedDate.value);
    return DateUtils.formatDateKey(dateKey);
  }

  /// Get total workout time formatted
  String getTotalDurationString() {
    if (totalDuration.value == 0) return '0 min';
    if (totalDuration.value < 60) return '${totalDuration.value} min';

    final hours = totalDuration.value ~/ 60;
    final mins = totalDuration.value % 60;
    return '${hours}h ${mins}min';
  }

  /// Get calories burned string
  String getCaloriesBurnedString() => '${totalCaloriesBurned.value.toStringAsFixed(0)} kcal';

  /// Get all exercises for selected date
  List<Exercise> getAllExercises() {
    return exercises.toList();
  }

  // ============ SEARCH & AUTO-FILL ============

  /// Search for exercises in library
  Future<void> searchExercises(String query) async {
    if (query.isEmpty) {
      exerciseSuggestions.clear();
      return;
    }

    try {
      isSearching.value = true;
      final suggestions = await _repository.searchExercises(query);
      
      // Deduplicate: remove already added exercises for the day
      final addedExerciseNames = exercises.map((e) => e.exerciseType).toSet();
      exerciseSuggestions.value = suggestions
          .where((s) => !addedExerciseNames.contains(s.name))
          .toList();
    } catch (e) {
      print('❌ Error searching exercises: $e');
    } finally {
      isSearching.value = false;
    }
  }

  /// Get specific exercise details
  Future<ExerciseDefinition?> getExerciseDetails(String name) async {
    try {
      return await _repository.getExerciseDefinitionByName(name);
    } catch (e) {
      print('❌ Error getting exercise details: $e');
      return null;
    }
  }

  /// Clear suggestions
  void clearSuggestions() {
    exerciseSuggestions.clear();
  }

  // ============ CATEGORIZATION ============

  /// Select a category and load its exercises
  Future<void> selectCategory(String category) async {
    selectedCategory.value = category;
    await loadExercisesByCategory(category);
  }

  /// Load exercises for a specific category
  Future<void> loadExercisesByCategory(String category) async {
    try {
      isLoading.value = true;
      final list = await _repository.getExercisesByCategory(category);
      
      // Deduplicate: remove already added exercises for the day
      final addedExerciseNames = exercises.map((e) => e.exerciseType).toSet();
      exercisesByCategory.value = list
          .where((s) => !addedExerciseNames.contains(s.name))
          .toList();
    } catch (e) {
      print('❌ Error loading exercises by category: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear categorization state
  void clearSelection() {
    selectedCategory.value = '';
    exercisesByCategory.clear();
  }

  // ============ UI HELPERS ============

  /// Group exercises by category/type
  Map<String, List<Exercise>> getGroupedExercises() {
    final grouped = <String, List<Exercise>>{};
    for (final ex in exercises) {
      if (!grouped.containsKey(ex.category)) {
        grouped[ex.category] = [];
      }
      grouped[ex.category]!.add(ex);
    }
    return grouped;
  }

  /// Trigger dashboard refresh
  void _refreshDashboard() {
    try {
      if (Get.isRegistered<DashboardController>(tag: 'dashboard')) {
        Get.find<DashboardController>(tag: 'dashboard').loadDashboardData();
      }
    } catch (e) {
      print('⚠️ Could not refresh dashboard from TrainingController: $e');
    }
  }
}