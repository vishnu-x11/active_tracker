import 'package:sqflite/sqflite.dart';
import 'package:active_tracker/data/models/sqlite/workout_log.dart';
import 'package:active_tracker/data/models/sqlite/exercise.dart';
import 'package:active_tracker/data/local/sqlite_manager.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';
import 'package:active_tracker/utils/date_utils.dart';

/// Implementation of TrainingRepository
/// Manages workout logs and exercise tracking using SQLite
class TrainingRepositoryImpl implements TrainingRepository {
  final String userId;

  TrainingRepositoryImpl({required this.userId});

  /// Get database instance
  Database get _db => SqliteManager.getInstance();

  // ============ WORKOUT LOG METHODS ============

  @override
  Future<void> addWorkoutLog(WorkoutLog workoutLog) async {
    try {
      final log = workoutLog.copyWith(userId: userId);

      await _db.insert(
        'workout_logs',
        log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ Workout log added: ${workoutLog.workoutName}');
    } catch (e) {
      print('❌ Error adding workout log: $e');
      rethrow;
    }
  }

  @override
  Future<List<WorkoutLog>> getWorkoutLogsForDate(String dateKey) async {
    try {
      final result = await _db.query(
        'workout_logs',
        where: 'userId = ? AND dateKey = ?',
        whereArgs: [userId, dateKey],
        orderBy: 'timestamp DESC',
      );

      return result.map((map) => WorkoutLog.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting workout logs: $e');
      return [];
    }
  }

  @override
  Future<int> getTotalWorkoutDurationForDate(String dateKey) async {
    try {
      final result = await _db.rawQuery(
        'SELECT COALESCE(SUM(duration), 0) as total FROM workout_logs WHERE userId = ? AND dateKey = ?',
        [userId, dateKey],
      );

      return (result.first['total'] as int);
    } catch (e) {
      print('❌ Error getting total workout duration: $e');
      return 0;
    }
  }

  @override
  Future<void> updateWorkoutLog(WorkoutLog workoutLog) async {
    try {
      await _db.update(
        'workout_logs',
        workoutLog.copyWith(userId: userId).toMap(),
        where: 'id = ? AND userId = ?',
        whereArgs: [workoutLog.id, userId],
      );

      print('✅ Workout log updated');
    } catch (e) {
      print('❌ Error updating workout log: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteWorkoutLog(int id) async {
    try {
      await _db.delete(
        'workout_logs',
        where: 'id = ? AND userId = ?',
        whereArgs: [id, userId],
      );

      print('✅ Workout log deleted');
    } catch (e) {
      print('❌ Error deleting workout log: $e');
      rethrow;
    }
  }

  // ============ EXERCISE METHODS ============

  @override
  Future<void> addExercise(Exercise exercise) async {
    try {
      final ex = exercise.copyWith(userId: userId);

      await _db.insert(
        'exercises',
        ex.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ Exercise added: ${exercise.exerciseType}');
    } catch (e) {
      print('❌ Error adding exercise: $e');
      rethrow;
    }
  }

  @override
  Future<List<Exercise>> getExercisesForDate(String dateKey) async {
    try {
      final result = await _db.query(
        'exercises',
        where: 'userId = ? AND dateKey = ?',
        whereArgs: [userId, dateKey],
        orderBy: 'exerciseType ASC',
      );

      return result.map((map) => Exercise.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting exercises: $e');
      return [];
    }
  }

  @override
  Future<int> getExerciseCountForDate(String dateKey, String exerciseType) async {
    try {
      final result = await _db.rawQuery(
        'SELECT COALESCE(SUM(reps * sets), 0) as total FROM exercises WHERE userId = ? AND dateKey = ? AND exerciseType = ?',
        [userId, dateKey, exerciseType],
      );

      return (result.first['total'] as int);
    } catch (e) {
      print('❌ Error getting exercise count: $e');
      return 0;
    }
  }

  @override
  Future<void> updateExercise(Exercise exercise) async {
    try {
      await _db.update(
        'exercises',
        exercise.copyWith(userId: userId).toMap(),
        where: 'id = ? AND userId = ?',
        whereArgs: [exercise.id, userId],
      );

      print('✅ Exercise updated');
    } catch (e) {
      print('❌ Error updating exercise: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteExercise(int id) async {
    try {
      await _db.delete(
        'exercises',
        where: 'id = ? AND userId = ?',
        whereArgs: [id, userId],
      );

      print('✅ Exercise deleted');
    } catch (e) {
      print('❌ Error deleting exercise: $e');
      rethrow;
    }
  }

  // ============ HELPER METHODS ============

  /// Get exercise summary by type for date range
  Future<Map<String, int>> getExerciseSummaryForDateRange(
      String startDate,
      String endDate,
      ) async {
    try {
      final result = await _db.rawQuery(
        '''SELECT exerciseType, COALESCE(SUM(reps * sets), 0) as total 
        FROM exercises 
        WHERE userId = ? AND dateKey BETWEEN ? AND ?
        GROUP BY exerciseType''',
        [userId, startDate, endDate],
      );

      final summary = <String, int>{};
      for (var row in result) {
        summary[row['exerciseType'] as String] = (row['total'] as int);
      }

      return summary;
    } catch (e) {
      print('❌ Error getting exercise summary: $e');
      return {};
    }
  }

  /// Get total calories burned for date
  Future<double> getTotalCaloriesBurnedForDate(String dateKey) async {
    try {
      final result = await _db.rawQuery(
        'SELECT COALESCE(SUM(caloriesBurned), 0) as total FROM workout_logs WHERE userId = ? AND dateKey = ?',
        [userId, dateKey],
      );

      return (result.first['total'] as num).toDouble();
    } catch (e) {
      print('❌ Error getting calories burned: $e');
      return 0.0;
    }
  }
}