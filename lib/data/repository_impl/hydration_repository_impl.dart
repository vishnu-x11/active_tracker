import 'package:active_tracker/data/models/hive/water_log_model.dart';
import 'package:active_tracker/data/local/hive_manager.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';
import 'package:active_tracker/utils/date_utils.dart';
import 'package:hive/hive.dart';

/// Implementation of HydrationRepository
/// Manages water intake tracking using Hive
class HydrationRepositoryImpl implements HydrationRepository {
  final String userId;
  late Box<WaterLogModel> _waterBox;

  HydrationRepositoryImpl({required this.userId}) {
    _waterBox = HiveManager.getWaterLogBox();
  }

  @override
  Future<double> getTotalWaterForDate(String dateKey) async {
    try {
      double total = 0.0;

      for (var log in _waterBox.values) {
        if (log.userId == userId && log.dateKey == dateKey) {
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
        userId: userId,
        dateKey: dateKey,
        mlConsumed: mlConsumed,
        timestamp: now,
        createdAt: now,
        updatedAt: now,
      );

      await _waterBox.add(waterLog);
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

  /// Get all water logs for date
  List<WaterLogModel> getWaterLogsForDateSync(String dateKey) {
    try {
      return _waterBox.values
          .where((log) => log.userId == userId && log.dateKey == dateKey)
          .toList();
    } catch (e) {
      print('❌ Error getting water logs: $e');
      return [];
    }
  }

  /// Delete water log
  Future<void> deleteWaterLog(int index) async {
    try {
      await _waterBox.deleteAt(index);
      print('✅ Water log deleted');
    } catch (e) {
      print('❌ Error deleting water log: $e');
      rethrow;
    }
  }
}