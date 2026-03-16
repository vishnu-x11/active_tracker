import 'package:active_tracker/data/models/sqlite/food_log.dart';
import 'package:active_tracker/data/models/sqlite/food_item.dart';
import 'package:active_tracker/data/repository_impl/nutrition_repository_impl.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';

// Import Phase 4 components
// import '../sync/sync_manager.dart';
// import '../sync/offline_queue_manager.dart';
// import '../sync/firebase_sync.dart';

/// Synced version of NutritionRepository
/// Handles push to Firebase and pull from Firebase
class SyncNutritionRepository implements NutritionRepository {
  final NutritionRepositoryImpl _local;
  final String userId;

  // TODO: Phase 4 - Uncomment when implementations available
  // final SyncManager _syncManager;
  // final OfflineQueueManager _queueManager;
  // final FirebaseSync _firebaseSync;

  SyncNutritionRepository({
    required this.userId,
    required NutritionRepositoryImpl localRepository,
    // required SyncManager syncManager,
    // required OfflineQueueManager queueManager,
    // required FirebaseSync firebaseSync,
  }) : _local = localRepository {
    // _syncManager = syncManager;
    // _queueManager = queueManager;
    // _firebaseSync = firebaseSync;
  }

  @override
  Future<void> addFoodLog(FoodLog foodLog) async {
    try {
      // 1. Save locally first
      await _local.addFoodLog(foodLog);
      print('✅ Food log saved locally');

      // TODO: Phase 4 - Implement sync push
      // 2. Try to push to Firebase if online
      // if (_syncManager.state == SyncState.idle) {
      //   try {
      //     await _firebaseSync.pushFoodLog(foodLog);
      //     print('✅ Food log synced to Firebase');
      //   } catch (e) {
      //     // Queue for later if push fails
      //     await _queueManager.addOperation(
      //       userId: userId,
      //       operationType: 'create',
      //       tableName: 'food_logs',
      //       entityId: foodLog.id?.toString() ?? '',
      //       data: jsonEncode(foodLog.toMap()),
      //     );
      //     print('⏳ Food log queued for sync');
      //   }
      // } else {
      //   // Queue if offline
      //   await _queueManager.addOperation(
      //     userId: userId,
      //     operationType: 'create',
      //     tableName: 'food_logs',
      //     entityId: foodLog.id?.toString() ?? '',
      //     data: jsonEncode(foodLog.toMap()),
      //   );
      // }
    } catch (e) {
      print('❌ Error adding food log: $e');
      rethrow;
    }
  }

  @override
  Future<List<FoodLog>> getFoodLogsForDate(String dateKey) async {
    try {
      // TODO: Phase 4 - Pull from Firebase first
      // if (_syncManager.state == SyncState.idle) {
      //   try {
      //     await _syncManager.startSync(userId);
      //   } catch (e) {
      //     print('⚠️ Sync failed, using local cache: $e');
      //   }
      // }

      // Return from local cache
      return await _local.getFoodLogsForDate(dateKey);
    } catch (e) {
      print('❌ Error getting food logs: $e');
      return [];
    }
  }

  @override
  Future<double> getTotalCaloriesForDate(String dateKey) async {
    try {
      return await _local.getTotalCaloriesForDate(dateKey);
    } catch (e) {
      print('❌ Error getting total calories: $e');
      return 0.0;
    }
  }

  @override
  Future<Map<String, double>> getMacrosForDate(String dateKey) async {
    try {
      return await _local.getMacrosForDate(dateKey);
    } catch (e) {
      print('❌ Error getting macros: $e');
      return {};
    }
  }

  @override
  Future<void> updateFoodLog(FoodLog foodLog) async {
    try {
      // 1. Update locally
      await _local.updateFoodLog(foodLog);
      print('✅ Food log updated locally');

      // TODO: Phase 4 - Sync update to Firebase
      // 2. Try to update in Firebase if online
      // if (_syncManager.state == SyncState.idle) {
      //   try {
      //     // await _firebaseSync.updateFoodLog(foodLog);
      //     print('✅ Food log synced to Firebase');
      //   } catch (e) {
      //     // Queue for later
      //   }
      // } else {
      //   // Queue if offline
      // }
    } catch (e) {
      print('❌ Error updating food log: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteFoodLog(int id) async {
    try {
      await _local.deleteFoodLog(id);
      print('✅ Food log deleted locally');

      // TODO: Phase 4 - Sync deletion to Firebase
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
      return await _local.getFoodLogsForDateRange(startDate, endDate);
    } catch (e) {
      print('❌ Error getting food logs for date range: $e');
      return [];
    }
  }

  @override
  Future<List<FoodItem>> searchFoodItems(String query) async {
    return await _local.searchFoodItems(query);
  }

  @override
  Future<FoodItem?> getFoodItemByName(String name) async {
    return await _local.getFoodItemByName(name);
  }
}