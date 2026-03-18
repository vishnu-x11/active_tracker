import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/auth_controller.dart';
import 'package:sqflite/sqflite.dart';
import 'package:active_tracker/data/models/sqlite/body_weight_log.dart';
import 'package:active_tracker/data/models/hive/bmi_result_model.dart';
import 'package:active_tracker/data/local/sqlite_manager.dart';
import 'package:active_tracker/data/local/hive_manager.dart';
import 'package:active_tracker/data/sync/sync_manager.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';
import 'package:active_tracker/utils/date_utils.dart';
import 'package:hive/hive.dart';

/// Implementation of BmiRepository
/// Manages BMI calculations and body weight tracking
class BmiRepositoryImpl implements BmiRepository {
  String get _userId => Get.find<AuthController>().userId.value;

  BmiRepositoryImpl();

  /// Get database instance
  Database get _db => SqliteManager.getInstance();

  /// Get Hive box instance
  Box<BmiResultModel> get _bmiBox => HiveManager.getBmiResultBox();

  // ============ BMI CALCULATION METHODS ============

  @override
  Future<void> calculateAndSaveBmi({
    required String userId,
    required String dateKey,
    required double weight,
    required double height,
    required double dailyCalories,
    required double proteinGrams,
    required double fatGrams,
    required double carbsGrams,
  }) async {
    try {
      // Calculate BMI: weight (kg) / (height (m) ^ 2)
      final heightInMeters = height / 100;
      final bmi = weight / (heightInMeters * heightInMeters);

      // Determine BMI category
      String category;
      if (bmi < 18.5) {
        category = 'underweight';
      } else if (bmi < 25) {
        category = 'normal';
      } else if (bmi < 30) {
        category = 'overweight';
      } else {
        category = 'obese';
      }

      final now = DateTime.now();
      final bmiResult = BmiResultModel(
        userId: userId,
        dateKey: dateKey,
        bmi: bmi,
        weight: weight,
        height: height,
        dailyCalories: dailyCalories,
        proteinGrams: proteinGrams,
        fatGrams: fatGrams,
        carbsGrams: carbsGrams,
        bmiCategory: category,
        timestamp: now,
        createdAt: now,
        updatedAt: now,
      );

      // Save to Hive
      await _bmiBox.put('${dateKey}_bmi', bmiResult);
      
      // Queue for sync (Treating Hive box as table)
      await SyncManager().queueOperation(
        userId: userId,
        operationType: 'update',
        tableName: 'bmi_results',
        entityId: dateKey,
        data: bmiResult.toMap(),
      );
      
      print('✅ BMI calculated and saved: $bmi ($category)');
    } catch (e) {
      print('❌ Error calculating BMI: $e');
      rethrow;
    }
  }

  @override
  Future<BmiResultModel?> getLatestBmiResult() async {
    try {
      BmiResultModel? latest;

      for (var result in _bmiBox.values) {
        if (result.userId == _userId) {
          if (latest == null ||
              result.timestamp.isAfter(latest.timestamp)) {
            latest = result;
          }
        }
      }

      return latest;
    } catch (e) {
      print('❌ Error getting latest BMI result: $e');
      return null;
    }
  }

  @override
  Future<List<BmiResultModel>> getBmiHistoryForDateRange(
      String startDate,
      String endDate,
      ) async {
    try {
      final results = <BmiResultModel>[];
      final dates = DateUtils.getDatesBetween(startDate, endDate);

      for (var dateKey in dates) {
        final result = _bmiBox.get('${dateKey}_bmi');
        if (result != null && result.userId == _userId) {
          results.add(result);
        }
      }

      return results;
    } catch (e) {
      print('❌ Error getting BMI history: $e');
      return [];
    }
  }

  // ============ BODY WEIGHT LOG METHODS ============

  @override
  Future<void> addBodyWeightLog(BodyWeightLog bodyWeightLog) async {
    try {
      final log = bodyWeightLog.copyWith(userId: _userId);

      final id = await _db.insert(
        'body_weight_logs',
        log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Queue for sync
      await SyncManager().queueOperation(
        userId: _userId,
        operationType: 'create',
        tableName: 'body_weight_logs',
        entityId: id.toString(),
        data: log.copyWith(id: id).toMap(),
      );

      print('✅ Body weight log added: ${bodyWeightLog.weight}kg');
    } catch (e) {
      print('❌ Error adding body weight log: $e');
      rethrow;
    }
  }

  @override
  Future<List<BodyWeightLog>> getBodyWeightLogsForDateRange(
      String startDate,
      String endDate,
      ) async {
    try {
      final result = await _db.query(
        'body_weight_logs',
        where: 'userId = ? AND dateKey BETWEEN ? AND ?',
        whereArgs: [_userId, startDate, endDate],
        orderBy: 'dateKey DESC',
      );

      return result.map((map) => BodyWeightLog.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting body weight logs: $e');
      return [];
    }
  }

  @override
  Future<double> getWeightTrendForDateRange(
      String startDate,
      String endDate,
      ) async {
    try {
      final logs = await getBodyWeightLogsForDateRange(startDate, endDate);

      if (logs.isEmpty) return 0.0;

      final total = logs.fold<double>(0, (sum, log) => sum + log.weight);
      return total / logs.length;
    } catch (e) {
      print('❌ Error getting weight trend: $e');
      return 0.0;
    }
  }

  // ============ HELPER METHODS ============

  /// Get latest body weight
  Future<double?> getLatestBodyWeight() async {
    try {
      final result = await _db.query(
        'body_weight_logs',
        where: 'userId = ?',
        whereArgs: [_userId],
        orderBy: 'dateKey DESC',
        limit: 1,
      );

      if (result.isEmpty) return null;

      return (result.first['weight'] as num).toDouble();
    } catch (e) {
      print('❌ Error getting latest body weight: $e');
      return null;
    }
  }

  /// Calculate weight change for date range
  Future<double> getWeightChangeForDateRange(
      String startDate,
      String endDate,
      ) async {
    try {
      final logs = await getBodyWeightLogsForDateRange(startDate, endDate);

      if (logs.isEmpty) return 0.0;

      // Sort by date
      logs.sort((a, b) => a.dateKey.compareTo(b.dateKey));

      final startWeight = logs.first.weight;
      final endWeight = logs.last.weight;

      return endWeight - startWeight;
    } catch (e) {
      print('❌ Error getting weight change: $e');
      return 0.0;
    }
  }

  /// Get average daily weight for date range
  Future<double> getAverageDailyWeightForDateRange(
      String startDate,
      String endDate,
      ) async {
    try {
      final logs = await getBodyWeightLogsForDateRange(startDate, endDate);

      if (logs.isEmpty) return 0.0;

      final total = logs.fold<double>(0, (sum, log) => sum + log.weight);
      return total / logs.length;
    } catch (e) {
      print('❌ Error getting average weight: $e');
      return 0.0;
    }
  }
}