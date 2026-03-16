import 'package:sqflite/sqflite.dart';
import 'package:active_tracker/data/models/sqlite/food_log.dart';
import 'package:active_tracker/data/models/sqlite/food_item.dart';
import 'package:active_tracker/data/local/sqlite_manager.dart';
import 'package:active_tracker/data/sync/sync_manager.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';

/// Implementation of NutritionRepository
/// Manages food logs and nutrition tracking using SQLite
class NutritionRepositoryImpl implements NutritionRepository {
  final String userId;

  NutritionRepositoryImpl({required this.userId});

  /// Get database instance
  Database get _db => SqliteManager.getInstance();

  @override
  Future<void> addFoodLog(FoodLog foodLog) async {
    try {
      // Add userId if not set
      final log = foodLog.copyWith(userId: userId);

      final id = await _db.insert(
        'food_logs',
        log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Queue for sync
      await SyncManager().queueOperation(
        userId: userId,
        operationType: 'create',
        tableName: 'food_logs',
        entityId: id.toString(),
        data: log.copyWith(id: id).toMap(),
      );

      print('✅ Food log added: ${foodLog.foodName}');
    } catch (e) {
      print('❌ Error adding food log: $e');
      rethrow;
    }
  }

  @override
  Future<List<FoodLog>> getFoodLogsForDate(String dateKey) async {
    try {
      final result = await _db.query(
        'food_logs',
        where: 'userId = ? AND dateKey = ?',
        whereArgs: [userId, dateKey],
        orderBy: 'timestamp DESC',
      );

      return result.map((map) => FoodLog.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting food logs for date: $e');
      return [];
    }
  }

  @override
  Future<double> getTotalCaloriesForDate(String dateKey) async {
    try {
      final result = await _db.rawQuery(
        'SELECT COALESCE(SUM(calories), 0) as total FROM food_logs WHERE userId = ? AND dateKey = ?',
        [userId, dateKey],
      );

      return (result.first['total'] as num).toDouble();
    } catch (e) {
      print('❌ Error getting total calories: $e');
      return 0.0;
    }
  }

  @override
  Future<Map<String, double>> getMacrosForDate(String dateKey) async {
    try {
      final result = await _db.rawQuery(
        '''SELECT 
          COALESCE(SUM(protein), 0) as protein,
          COALESCE(SUM(fat), 0) as fat,
          COALESCE(SUM(carbs), 0) as carbs
        FROM food_logs 
        WHERE userId = ? AND dateKey = ?''',
        [userId, dateKey],
      );

      if (result.isEmpty) {
        return {'protein': 0, 'fat': 0, 'carbs': 0};
      }

      return {
        'protein': (result.first['protein'] as num).toDouble(),
        'fat': (result.first['fat'] as num).toDouble(),
        'carbs': (result.first['carbs'] as num).toDouble(),
      };
    } catch (e) {
      print('❌ Error getting macros: $e');
      return {'protein': 0, 'fat': 0, 'carbs': 0};
    }
  }

  @override
  Future<void> updateFoodLog(FoodLog foodLog) async {
    try {
      final log = foodLog.copyWith(userId: userId);
      await _db.update(
        'food_logs',
        log.toMap(),
        where: 'id = ? AND userId = ?',
        whereArgs: [foodLog.id, userId],
      );

      // Queue for sync
      await SyncManager().queueOperation(
        userId: userId,
        operationType: 'update',
        tableName: 'food_logs',
        entityId: foodLog.id.toString(),
        data: log.toMap(),
      );

      print('✅ Food log updated');
    } catch (e) {
      print('❌ Error updating food log: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteFoodLog(int id) async {
    try {
      await _db.delete(
        'food_logs',
        where: 'id = ? AND userId = ?',
        whereArgs: [id, userId],
      );

      // Queue for sync
      await SyncManager().queueOperation(
        userId: userId,
        operationType: 'delete',
        tableName: 'food_logs',
        entityId: id.toString(),
        data: {'id': id},
      );

      print('✅ Food log deleted');
    } catch (e) {
      print('❌ Error deleting food log: $e');
      rethrow;
    }
  }

  @override
  Future<List<FoodLog>> getFoodLogsForDateRange(
      String startDate,
      String endDate,
      ) async {
    try {
      final result = await _db.query(
        'food_logs',
        where: 'userId = ? AND dateKey BETWEEN ? AND ?',
        whereArgs: [userId, startDate, endDate],
        orderBy: 'dateKey DESC, timestamp DESC',
      );

      return result.map((map) => FoodLog.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting food logs for date range: $e');
      return [];
    }
  }

  /// Get calorie summary for date range
  Future<Map<String, double>> getCalorieSummaryForDateRange(
      String startDate,
      String endDate,
      ) async {
    try {
      final result = await _db.rawQuery(
        '''SELECT dateKey, COALESCE(SUM(calories), 0) as total 
        FROM food_logs 
        WHERE userId = ? AND dateKey BETWEEN ? AND ?
        GROUP BY dateKey''',
        [userId, startDate, endDate],
      );

      final summary = <String, double>{};
      for (var row in result) {
        summary[row['dateKey'] as String] = (row['total'] as num).toDouble();
      }

      return summary;
    } catch (e) {
      print('❌ Error getting calorie summary: $e');
      return {};
    }
  }

  /// Get average daily calories for date range
  Future<double> getAverageDailyCaloriesForDateRange(
      String startDate,
      String endDate,
      ) async {
    try {
      final summary = await getCalorieSummaryForDateRange(startDate, endDate);

      if (summary.isEmpty) return 0.0;

      final total = summary.values.fold<double>(0, (sum, val) => sum + val);
      return total / summary.length;
    } catch (e) {
      print('❌ Error getting average calories: $e');
      return 0.0;
    }
  }

  @override
  Future<List<FoodItem>> searchFoodItems(String query) async {
    try {
      final result = await _db.query(
        'food_items',
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
        limit: 10,
      );

      return result.map((map) => FoodItem.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error searching food items: $e');
      return [];
    }
  }

  @override
  Future<FoodItem?> getFoodItemByName(String name) async {
    try {
      final result = await _db.query(
        'food_items',
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return FoodItem.fromMap(result.first);
    } catch (e) {
      print('❌ Error getting food item by name: $e');
      return null;
    }
  }
}