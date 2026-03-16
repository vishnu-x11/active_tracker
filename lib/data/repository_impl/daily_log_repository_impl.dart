import 'package:sqflite/sqflite.dart';
import 'package:active_tracker/data/models/sqlite/daily_log_summary.dart';
import 'package:active_tracker/data/local/sqlite_manager.dart';
import 'package:active_tracker/data/sync/sync_manager.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';
import 'package:active_tracker/utils/date_utils.dart';
import 'package:active_tracker/data/local/hive_manager.dart';

/// Implementation of DailyLogRepository
/// Manages daily log summaries and aggregated data
class DailyLogRepositoryImpl implements DailyLogRepository {
  final String userId;
  final HydrationRepository _hydrationRepository;

  DailyLogRepositoryImpl({
    required this.userId,
    required HydrationRepository hydrationRepository,
  }) : _hydrationRepository = hydrationRepository;

  /// Get database instance
  Database get _db => SqliteManager.getInstance();

  @override
  Future<DailyLogSummary?> getDailyLogSummaryForDate(String dateKey) async {
    try {
      final result = await _db.query(
        'daily_log_summary',
        where: 'userId = ? AND dateKey = ?',
        whereArgs: [userId, dateKey],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return DailyLogSummary.fromMap(result.first);
    } catch (e) {
      print('❌ Error getting daily log summary: $e');
      return null;
    }
  }

  @override
  Future<void> updateDailyLogSummary(DailyLogSummary dailySummary) async {
    try {
      final summary = dailySummary.copyWith(userId: userId);

      await _db.insert(
        'daily_log_summary',
        summary.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Queue for sync
      await SyncManager().queueOperation(
        userId: userId,
        operationType: 'update',
        tableName: 'daily_log_summary',
        entityId: summary.dateKey,
        data: summary.toMap(),
      );

      print('✅ Daily log summary updated for ${dailySummary.dateKey}');
    } catch (e) {
      print('❌ Error updating daily log summary: $e');
      rethrow;
    }
  }

  @override
  Future<List<DailyLogSummary>> getDailyLogSummariesForDateRange(
      String startDate,
      String endDate,
      ) async {
    try {
      final result = await _db.query(
        'daily_log_summary',
        where: 'userId = ? AND dateKey BETWEEN ? AND ?',
        whereArgs: [userId, startDate, endDate],
        orderBy: 'dateKey DESC',
      );

      return result.map((map) => DailyLogSummary.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting daily log summaries: $e');
      return [];
    }
  }

  @override
  Future<void> calculateAndSaveDailySummary(String dateKey) async {
    try {
      // Get totals from food logs
      final foodResult = await _db.rawQuery(
        '''SELECT 
          COALESCE(SUM(calories), 0) as calories,
          COALESCE(SUM(protein), 0) as protein,
          COALESCE(SUM(fat), 0) as fat,
          COALESCE(SUM(carbs), 0) as carbs
        FROM food_logs 
        WHERE userId = ? AND dateKey = ?''',
        [userId, dateKey],
      );

      final calories = (foodResult.first['calories'] as num).toDouble();
      final protein = (foodResult.first['protein'] as num).toDouble();
      final fat = (foodResult.first['fat'] as num).toDouble();
      final carbs = (foodResult.first['carbs'] as num).toDouble();

      // Get workout duration and calories burned
      final workoutResult = await _db.rawQuery(
        'SELECT COALESCE(SUM(duration), 0) as totalDuration, COALESCE(SUM(caloriesBurned), 0) as totalBurned FROM workout_logs WHERE userId = ? AND dateKey = ?',
        [userId, dateKey],
      );

      final workoutMinutes = (workoutResult.first['totalDuration'] as int);
      final caloriesBurned = (workoutResult.first['totalBurned'] as num).toDouble();

      // Get water intake from actual Hydration storage (Hive)
      final totalWater = await _hydrationRepository.getTotalWaterForDate(dateKey);

      // Get exercise counts
      final pushupResult = await _db.rawQuery(
        'SELECT COALESCE(SUM(reps * sets), 0) as total FROM exercises WHERE userId = ? AND dateKey = ? AND exerciseType = ?',
        [userId, dateKey, 'pushup'],
      );

      final pullupResult = await _db.rawQuery(
        'SELECT COALESCE(SUM(reps * sets), 0) as total FROM exercises WHERE userId = ? AND dateKey = ? AND exerciseType = ?',
        [userId, dateKey, 'pullup'],
      );

      final pushups = (pushupResult.first['total'] as int);
      final pullups = (pullupResult.first['total'] as int);

      // Create summary
      final now = DateTime.now().millisecondsSinceEpoch;
      final summary = DailyLogSummary(
        userId: userId,
        dateKey: dateKey,
        totalCalories: calories,
        totalProtein: protein,
        totalFat: fat,
        totalCarbs: carbs,
        totalWater: totalWater,
        workoutMinutes: workoutMinutes,
        totalCaloriesBurned: caloriesBurned,
        pushups: pushups,
        pullups: pullups,
        createdAt: now,
        updatedAt: now,
      );

      await updateDailyLogSummary(summary);
      print('✅ Daily summary calculated for $dateKey');
    } catch (e) {
      print('❌ Error calculating daily summary: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, bool>> getGoalsMet(String dateKey) async {
    try {
      final summary = await getDailyLogSummaryForDate(dateKey);

      if (summary == null) {
        return {
          'calories': false,
          'protein': false,
          'water': false,
          'workout': false,
          'calories_burned': false,
        };
      }

      // Fetch goals from User Profile
      final profileBox = HiveManager.getUserBox();
      final profile = profileBox.get('userProfile'); // Consistent with OnboardingRepository

      final calorieGoal = profile?.calorieGoal ?? 2000.0;
      final proteinGoal = profile?.proteinGoal ?? 150.0;
      final waterGoal = (profile?.waterGoalMl ?? 2500).toDouble();
      final burnedGoal = profile?.burnedCalorieGoal ?? 500.0;
      const workoutGoalMinutes = 30;

      return {
        'calories': summary.isCalorieGoalMet(calorieGoal),
        'protein': summary.isProteinGoalMet(proteinGoal),
        'water': summary.isWaterGoalMet(waterGoal),
        'workout': summary.isWorkoutGoalMet(minMinutes: workoutGoalMinutes),
        'calories_burned': summary.totalCaloriesBurned >= burnedGoal,
      };
    } catch (e) {
      print('❌ Error getting goals met: $e');
      return {};
    }
  }

  @override
  Future<void> updateDailyMood(String dateKey, String mood) async {
    try {
      final summary = await getDailyLogSummaryForDate(dateKey);

      if (summary == null) {
        throw Exception('Daily log summary not found for $dateKey');
      }

      final updated = summary.copyWith(mood: mood);
      await updateDailyLogSummary(updated);

      print('✅ Daily mood updated: $mood');
    } catch (e) {
      print('❌ Error updating daily mood: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateDailyNotes(String dateKey, String notes) async {
    try {
      final summary = await getDailyLogSummaryForDate(dateKey);

      if (summary == null) {
        throw Exception('Daily log summary not found for $dateKey');
      }

      final updated = summary.copyWith(notes: notes);
      await updateDailyLogSummary(updated);

      print('✅ Daily notes updated');
    } catch (e) {
      print('❌ Error updating daily notes: $e');
      rethrow;
    }
  }

  // ============ HELPER METHODS ============

  /// Get goals met status for date range
  Future<Map<String, int>> getGoalMetCountForDateRange(
      String startDate,
      String endDate,
      ) async {
    try {
      final summaries = await getDailyLogSummariesForDateRange(startDate, endDate);

      int caloriesMet = 0;
      int proteinMet = 0;
      int waterMet = 0;
      int workoutMet = 0;

      const calorieGoal = 2000.0;
      const proteinGoal = 150.0;
      const waterGoal = 2500.0;

      for (var summary in summaries) {
        if (summary.isCalorieGoalMet(calorieGoal)) caloriesMet++;
        if (summary.isProteinGoalMet(proteinGoal)) proteinMet++;
        if (summary.isWaterGoalMet(waterGoal)) waterMet++;
        if (summary.isWorkoutGoalMet()) workoutMet++;
      }

      return {
        'calories': caloriesMet,
        'protein': proteinMet,
        'water': waterMet,
        'workout': workoutMet,
        'total_days': summaries.length,
      };
    } catch (e) {
      print('❌ Error getting goal met count: $e');
      return {};
    }
  }

  /// Get average daily stats for date range
  Future<Map<String, double>> getAverageDailyStatsForDateRange(
      String startDate,
      String endDate,
      ) async {
    try {
      final summaries = await getDailyLogSummariesForDateRange(startDate, endDate);

      if (summaries.isEmpty) {
        return {
          'calories': 0,
          'protein': 0,
          'fat': 0,
          'carbs': 0,
          'water': 0,
          'workout': 0,
        };
      }

      final avgCalories = summaries.fold<double>(
        0,
            (sum, s) => sum + s.totalCalories,
      ) / summaries.length;

      final avgProtein = summaries.fold<double>(
        0,
            (sum, s) => sum + s.totalProtein,
      ) / summaries.length;

      final avgFat = summaries.fold<double>(
        0,
            (sum, s) => sum + s.totalFat,
      ) / summaries.length;

      final avgCarbs = summaries.fold<double>(
        0,
            (sum, s) => sum + s.totalCarbs,
      ) / summaries.length;

      final avgWater = summaries.fold<double>(
        0,
            (sum, s) => sum + s.totalWater,
      ) / summaries.length;

      final avgWorkout = summaries.fold<int>(
        0,
            (sum, s) => sum + s.workoutMinutes,
      ) / summaries.length;

      return {
        'calories': avgCalories,
        'protein': avgProtein,
        'fat': avgFat,
        'carbs': avgCarbs,
        'water': avgWater,
        'workout': avgWorkout,
      };
    } catch (e) {
      print('❌ Error getting average daily stats: $e');
      return {};
    }
  }

  /// Delete daily log summary
  Future<void> deleteDailyLogSummary(String dateKey) async {
    try {
      await _db.delete(
        'daily_log_summary',
        where: 'userId = ? AND dateKey = ?',
        whereArgs: [userId, dateKey],
      );

      // Queue for sync
      await SyncManager().queueOperation(
        userId: userId,
        operationType: 'delete',
        tableName: 'daily_log_summary',
        entityId: dateKey,
        data: {'dateKey': dateKey},
      );

      print('✅ Daily log summary deleted');
    } catch (e) {
      print('❌ Error deleting daily log summary: $e');
      rethrow;
    }
  }
}