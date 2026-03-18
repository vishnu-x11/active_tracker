



// ============ 1. ONBOARDING REPOSITORY ============
import 'package:active_tracker/data/models/sqlite/body_weight_log.dart';
import 'package:active_tracker/data/models/sqlite/daily_log_summary.dart';
import 'package:active_tracker/data/models/sqlite/exercise.dart';
import 'package:active_tracker/data/models/sqlite/food_log.dart';
import 'package:active_tracker/data/models/sqlite/workout_log.dart';
import 'package:active_tracker/data/models/sqlite/food_item.dart';
import 'package:active_tracker/data/models/sqlite/exercise_definition.dart';
import 'package:active_tracker/data/models/hive/user_profile_model.dart';
import 'package:active_tracker/data/models/hive/water_log_model.dart';

/// Manages user onboarding flow and initial setup
abstract class OnboardingRepository {
  /// Get current user profile
  Future<void> getUserProfile();

  /// Get current user profile synchronously
  UserProfileModel? getUserProfileSync();

  /// Save user profile during onboarding
  Future<void> saveUserProfile({
    required String userId,
    required String name,
    required int age,
    required double weight,
    required double height,
    required int goalType,
    required int intensityLevel,
    required double burnedCalorieGoal,
  });

  /// Sync user profile from cloud to local Hive
  Future<bool> syncUserProfileFromCloud(String userId);

  /// Clear user profile (for logout)
  Future<void> clearUserProfile();

  /// Update user goals and preferences
  Future<void> updateUserGoals({
    required double calorieGoal,
    required double proteinGoal,
    required double fatGoal,
    required double carbsGoal,
    required int waterGoalMl,
  });

  /// Update user profile image URL
  Future<void> updateUserProfileImage(String imageUrl);

  /// Check if user has completed onboarding
  Future<bool> isOnboardingComplete();
}

// ============ 2. NUTRITION REPOSITORY ============
/// Manages food logs and nutrition tracking
abstract class NutritionRepository {
  /// Add new food log entry
  Future<void> addFoodLog(FoodLog foodLog);

  /// Get food logs for specific date
  Future<List<FoodLog>> getFoodLogsForDate(String dateKey);

  /// Get total calories for date
  Future<double> getTotalCaloriesForDate(String dateKey);

  /// Get total macros for date
  Future<Map<String, double>> getMacrosForDate(String dateKey);

  /// Update existing food log
  Future<void> updateFoodLog(FoodLog foodLog);

  /// Delete food log
  Future<void> deleteFoodLog(int id);

  /// Get food logs for date range
  Future<List<FoodLog>> getFoodLogsForDateRange(String startDate, String endDate);

  /// Search for food items in library
  Future<List<FoodItem>> searchFoodItems(String query);

  /// Get food item by name
  Future<FoodItem?> getFoodItemByName(String name);
}

// ============ 3. TRAINING REPOSITORY ============
/// Manages workout logs and exercise tracking
abstract class TrainingRepository {
  /// Add new workout log
  Future<void> addWorkoutLog(WorkoutLog workoutLog);

  /// Get workout logs for date
  Future<List<WorkoutLog>> getWorkoutLogsForDate(String dateKey);

  /// Get total workout duration for date (minutes)
  Future<int> getTotalWorkoutDurationForDate(String dateKey);

  /// Update workout log
  Future<void> updateWorkoutLog(WorkoutLog workoutLog);

  /// Delete workout log
  Future<void> deleteWorkoutLog(int id);

  /// Add exercise entry (pushups, pullups, etc.)
  Future<void> addExercise(Exercise exercise);

  /// Get exercises for date
  Future<List<Exercise>> getExercisesForDate(String dateKey);

  /// Get exercise count for date (total reps)
  Future<int> getExerciseCountForDate(String dateKey, String exerciseType);

  /// Update exercise
  Future<void> updateExercise(Exercise exercise);

  /// Delete exercise
  Future<void> deleteExercise(int id);

  /// Search for exercise definitions
  Future<List<ExerciseDefinition>> searchExercises(String query);

  /// Get exercise definition by name
  Future<ExerciseDefinition?> getExerciseDefinitionByName(String name);

  /// Get training volume for date
  Future<double> getTrainingVolume(String dateKey);

  /// Get exercises from library by category
  Future<List<ExerciseDefinition>> getExercisesByCategory(String category);

  /// Calculate estimated One-Rep Max (1RM)
  double calculate1RM(double weight, int reps);
}

// ============ 4. HYDRATION REPOSITORY ============
/// Manages water intake tracking
abstract class HydrationRepository {
  /// Get total water for date (ml)
  Future<double> getTotalWaterForDate(String dateKey);

  /// Log water intake
  Future<void> logWaterIntake(String dateKey, double mlConsumed);

  /// Get water goal for user
  Future<double> getWaterGoal();

  /// Check if water goal met for date
  Future<bool> isWaterGoalMet(String dateKey);

  /// Get water intake history for date range
  Future<Map<String, double>> getWaterHistoryForDateRange(String startDate, String endDate);

  /// Get individual water logs for date
  Future<List<WaterLogModel>> getWaterLogsForDate(String dateKey);

  /// Update water log
  Future<void> updateWaterLog(WaterLogModel waterLog);

  /// Delete water log
  Future<void> deleteWaterLog(WaterLogModel waterLog);
}

// ============ 5. BMI REPOSITORY ============
/// Manages BMI calculations and body weight tracking
abstract class BmiRepository {
  /// Calculate BMI and save result
  Future<void> calculateAndSaveBmi({
    required String userId,
    required String dateKey,
    required double weight,
    required double height,
    required double dailyCalories,
    required double proteinGrams,
    required double fatGrams,
    required double carbsGrams,
  });

  /// Get latest BMI result
  Future<dynamic> getLatestBmiResult();

  /// Get BMI history for date range
  Future<List<dynamic>> getBmiHistoryForDateRange(String startDate, String endDate);

  /// Add body weight log
  Future<void> addBodyWeightLog(BodyWeightLog bodyWeightLog);

  /// Get body weight logs for date range
  Future<List<BodyWeightLog>> getBodyWeightLogsForDateRange(String startDate, String endDate);

  /// Get weight trend (average for week/month)
  Future<double> getWeightTrendForDateRange(String startDate, String endDate);
}

// ============ 6. DAILY LOG REPOSITORY ============
/// Manages daily log summaries and aggregated data
abstract class DailyLogRepository {
  /// Get daily log summary for date
  Future<DailyLogSummary?> getDailyLogSummaryForDate(String dateKey);

  /// Create or update daily log summary
  Future<void> updateDailyLogSummary(DailyLogSummary dailySummary);

  /// Get daily log summaries for date range
  Future<List<DailyLogSummary>> getDailyLogSummariesForDateRange(
      String startDate,
      String endDate,
      );

  /// Calculate and save daily summary
  Future<void> calculateAndSaveDailySummary(String dateKey);

  /// Get all goals met status for date
  Future<Map<String, bool>> getGoalsMet(String dateKey);

  /// Update daily mood
  Future<void> updateDailyMood(String dateKey, String mood);

  /// Update daily notes
  Future<void> updateDailyNotes(String dateKey, String notes);
}