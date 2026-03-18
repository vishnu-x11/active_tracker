import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/auth_controller.dart';
import 'package:sqflite/sqflite.dart';
import 'package:active_tracker/data/models/sqlite/workout_log.dart';
import 'package:active_tracker/data/models/sqlite/exercise.dart';
import 'package:active_tracker/data/models/sqlite/exercise_definition.dart';
import 'package:active_tracker/data/local/sqlite_manager.dart';
import 'package:active_tracker/data/sync/sync_manager.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';
import 'package:active_tracker/utils/date_utils.dart';

/// Implementation of TrainingRepository
/// Manages workout logs and exercise tracking using SQLite
class TrainingRepositoryImpl implements TrainingRepository {
  String get _userId => Get.find<AuthController>().userId.value;

  TrainingRepositoryImpl();

  /// Get database instance
  Database get _db => SqliteManager.getInstance();

  // ============ WORKOUT LOG METHODS ============

  @override
  Future<void> addWorkoutLog(WorkoutLog workoutLog) async {
    try {
      final log = workoutLog.copyWith(userId: _userId);

      final id = await _db.insert(
        'workout_logs',
        log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Queue for sync
      await SyncManager().queueOperation(
        userId: _userId,
        operationType: 'create',
        tableName: 'workout_logs',
        entityId: id.toString(),
        data: log.copyWith(id: id).toMap(),
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
        whereArgs: [_userId, dateKey],
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
        [_userId, dateKey],
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
      final log = workoutLog.copyWith(userId: _userId);
      await _db.update(
        'workout_logs',
        log.toMap(),
        where: 'id = ? AND userId = ?',
        whereArgs: [workoutLog.id, _userId],
      );

      // Queue for sync
      await SyncManager().queueOperation(
        userId: _userId,
        operationType: 'update',
        tableName: 'workout_logs',
        entityId: workoutLog.id.toString(),
        data: log.toMap(),
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
        whereArgs: [id, _userId],
      );

      // Queue for sync
      await SyncManager().queueOperation(
        userId: _userId,
        operationType: 'delete',
        tableName: 'workout_logs',
        entityId: id.toString(),
        data: {'id': id},
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
      final ex = exercise.copyWith(userId: _userId);

      final id = await _db.insert(
        'exercises',
        ex.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Queue for sync
      await SyncManager().queueOperation(
        userId: _userId,
        operationType: 'create',
        tableName: 'exercises',
        entityId: id.toString(),
        data: ex.copyWith(id: id).toMap(),
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
        whereArgs: [_userId, dateKey],
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
        [_userId, dateKey, exerciseType],
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
      final ex = exercise.copyWith(userId: _userId);
      await _db.update(
        'exercises',
        ex.toMap(),
        where: 'id = ? AND userId = ?',
        whereArgs: [exercise.id, _userId],
      );

      // Queue for sync
      await SyncManager().queueOperation(
        userId: _userId,
        operationType: 'update',
        tableName: 'exercises',
        entityId: exercise.id.toString(),
        data: ex.toMap(),
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
        whereArgs: [id, _userId],
      );

      // Queue for sync
      await SyncManager().queueOperation(
        userId: _userId,
        operationType: 'delete',
        tableName: 'exercises',
        entityId: id.toString(),
        data: {'id': id},
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
        [_userId, startDate, endDate],
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
        [_userId, dateKey],
      );

      return (result.first['total'] as num).toDouble();
    } catch (e) {
      print('❌ Error getting calories burned: $e');
      return 0.0;
    }
  }

  @override
  Future<List<ExerciseDefinition>> searchExercises(String query) async {
    try {
      final result = await _db.query(
        'exercise_definitions',
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
        limit: 10,
      );

      return result.map((map) => ExerciseDefinition.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error searching exercises: $e');
      return [];
    }
  }

  @override
  Future<ExerciseDefinition?> getExerciseDefinitionByName(String name) async {
    try {
      final result = await _db.query(
        'exercise_definitions',
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return ExerciseDefinition.fromMap(result.first);
    } catch (e) {
      print('❌ Error getting exercise definition by name: $e');
      return null;
    }
  }

  @override
  Future<double> getTrainingVolume(String dateKey) async {
    try {
      final result = await _db.rawQuery(
        '''SELECT SUM(CAST(reps AS REAL) * CAST(sets AS REAL) * COALESCE(weight, 0)) as totalVolume 
           FROM exercises 
           WHERE userId = ? AND dateKey = ?''',
        [_userId, dateKey],
      );

      return (result.first['totalVolume'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      print('❌ Error calculating training volume: $e');
      return 0.0;
    }
  }

  @override
  double calculate1RM(double weight, int reps) {
    if (reps <= 0) return 0;
    if (reps == 1) return weight;
    // Epley Formula: 1RM = W * (1 + r/30)
    return weight * (1 + reps / 30);
  }

  @override
  Future<List<ExerciseDefinition>> getExercisesByCategory(String category) async {
    try {
      final result = await _db.query(
        'exercise_definitions',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'name ASC',
      );

      return result.map((map) => ExerciseDefinition.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting exercises by category: $e');
      return [];
    }
  }
}