import 'package:active_tracker/data/models/hive/water_log_model.dart';
import 'package:active_tracker/data/local/hive_manager.dart';
import 'package:active_tracker/data/sync/sync_manager.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';
import 'package:active_tracker/utils/date_utils.dart';
import 'package:get/get.dart';
import 'package:active_tracker/presentation/controllers/auth_controller.dart';
import 'package:hive/hive.dart';

/// Implementation of HydrationRepository
/// Manages water intake tracking using Hive
class HydrationRepositoryImpl implements HydrationRepository {
  String get _userId => Get.find<AuthController>().userId.value;
  late Box<WaterLogModel> _waterBox;

  HydrationRepositoryImpl() {
    _waterBox = HiveManager.getWaterLogBox();
  }

  @override
  Future<double> getTotalWaterForDate(String dateKey) async {
    try {
      double total = 0.0;

      for (var log in _waterBox.values) {
        if (log.userId == _userId && log.dateKey == dateKey) {
          total += log.mlConsumed;
        }
      }

      return total;
    } catch (e) {
      print('❌ Error getting total water for date: $e');
      return 0.0;
    }
  }

  @override
  Future<void> logWaterIntake(String dateKey, double mlConsumed) async {
    try {
      final now = DateTime.now();
      final waterLog = WaterLogModel(
        userId: _userId,
        dateKey: dateKey,
        mlConsumed: mlConsumed,
        timestamp: now,
        createdAt: now,
        updatedAt: now,
      );

      await _waterBox.add(waterLog);

      // Queue for sync
      await SyncManager().queueOperation(
        userId: _userId,
        operationType: 'create',
        tableName: 'hydration_logs',
        entityId: waterLog.timestamp.millisecondsSinceEpoch.toString(),
        data: waterLog.toMap(),
      );

      print('✅ Water intake logged: ${mlConsumed}ml');
    } catch (e) {
      print('❌ Error logging water intake: $e');
      rethrow;
    }
  }

  @override
  Future<double> getWaterGoal() async {
    try {
      // Default water goal: weight (kg) * 35 ml + 500 ml bonus
      // Get from user profile if available
      // For now, return default
      return 2500.0; // Default: 2.5 liters
    } catch (e) {
      print('❌ Error getting water goal: $e');
      return 2500.0;
    }
  }

  @override
  Future<bool> isWaterGoalMet(String dateKey) async {
    try {
      final totalWater = await getTotalWaterForDate(dateKey);
      final goal = await getWaterGoal();
      return totalWater >= goal;
    } catch (e) {
      print('❌ Error checking water goal: $e');
      return false;
    }
  }

  @override
  Future<Map<String, double>> getWaterHistoryForDateRange(
      String startDate,
      String endDate,
      ) async {
    try {
      final history = <String, double>{};
      final dates = DateUtils.getDatesBetween(startDate, endDate);

      for (var dateKey in dates) {
        final total = await getTotalWaterForDate(dateKey);
        history[dateKey] = total;
      }

      return history;
    } catch (e) {
      print('❌ Error getting water history: $e');
      return {};
    }
  }

  @override
  Future<List<WaterLogModel>> getWaterLogsForDate(String dateKey) async {
    try {
      return _waterBox.values
          .where((log) => log.userId == _userId && log.dateKey == dateKey)
          .toList();
    } catch (e) {
      print('❌ Error getting water logs: $e');
      return [];
    }
  }

  /// Get all water logs for date
  List<WaterLogModel> getWaterLogsForDateSync(String dateKey) {
    try {
      return _waterBox.values
          .where((log) => log.userId == _userId && log.dateKey == dateKey)
          .toList();
    } catch (e) {
      print('❌ Error getting water logs sync: $e');
      return [];
    }
  }

  @override
  Future<void> updateWaterLog(WaterLogModel waterLog) async {
    try {
      final now = DateTime.now();
      final log = waterLog.copyWith(
        userId: _userId,
        updatedAt: now,
      );

      // Find by key or index
      final index = _waterBox.values.toList().indexOf(waterLog);
      if (index != -1) {
        await _waterBox.putAt(index, log);
      } else {
        // Fallback: search by timestamp if available or just update if we have the reference
        await waterLog.save();
      }

      // Queue for sync
      await SyncManager().queueOperation(
        userId: _userId,
        operationType: 'update',
        tableName: 'hydration_logs',
        entityId: log.timestamp.millisecondsSinceEpoch.toString(),
        data: log.toMap(),
      );

      print('✅ Water intake updated: ${log.mlConsumed}ml');
    } catch (e) {
      print('❌ Error updating water intake: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteWaterLog(WaterLogModel waterLog) async {
    try {
      // Queue for sync
      await SyncManager().queueOperation(
        userId: _userId,
        operationType: 'delete',
        tableName: 'hydration_logs',
        entityId: waterLog.timestamp.millisecondsSinceEpoch.toString(),
        data: {'timestamp': waterLog.timestamp.toIso8601String()},
      );

      await waterLog.delete();
      print('✅ Water log deleted');
    } catch (e) {
      print('❌ Error deleting water log: $e');
      rethrow;
    }
  }
}