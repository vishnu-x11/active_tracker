import 'dart:convert';
import 'package:active_tracker/data/sync/offline_queue_manager.dart';
import 'package:active_tracker/data/sync/firebase_sync.dart';
import 'package:active_tracker/data/models/sqlite/daily_log_summary.dart';
import 'package:active_tracker/data/models/sqlite/food_log.dart';
import 'package:active_tracker/data/models/sqlite/workout_log.dart';
import 'package:active_tracker/data/models/sqlite/exercise.dart';
import 'package:active_tracker/data/models/sqlite/body_weight_log.dart';
import 'package:active_tracker/data/models/hive/bmi_result_model.dart';
import 'package:active_tracker/data/models/hive/water_log_model.dart';
import 'package:active_tracker/data/models/hive/user_profile_model.dart';

enum SyncState {
  idle,
  syncing,
  error,
  offline,
}

/// Orchestrates all sync operations
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();

  factory SyncManager() {
    return _instance;
  }

  SyncManager._internal();

  SyncState _state = SyncState.idle;
  String? _lastError;
  DateTime? _lastSyncTime;

  final OfflineQueueManager _queueManager = OfflineQueueManager();
  final FirebaseSync _firebaseSync = FirebaseSync();

  /// Initialize sync manager
  Future<void> init() async {
    try {
      await _queueManager.init();
      await _firebaseSync.init();
      print('✅ Sync Manager initialized');
    } catch (e) {
      print('❌ Error initializing sync manager: $e');
      _state = SyncState.error;
      _lastError = e.toString();
    }
  }

  /// Get current sync state
  SyncState get state => _state;

  /// Get last error message
  String? get lastError => _lastError;

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if syncing
  bool get isSyncing => _state == SyncState.syncing;

  /// Check if offline
  bool get isOffline => _state == SyncState.offline;

  /// Set online state
  void setOnline() {
    if (_state != SyncState.syncing) {
      _state = SyncState.idle;
      _lastError = null;
      print('📡 Online - ready to sync');
    }
  }

  /// Set offline state
  void setOffline() {
    if (_state != SyncState.syncing) {
      _state = SyncState.offline;
      print('📴 Offline - operations queued');
    }
  }

  /// Start sync
  Future<void> startSync(String userId) async {
    if (_state == SyncState.syncing) {
      print('⚠️ Sync already in progress');
      return;
    }

    try {
      _state = SyncState.syncing;
      print('🔄 Starting sync for user: $userId');

      // Repair any stale operations before processing
      await _queueManager.repairOperations(userId);

      await processOfflineQueue(userId);

      _lastSyncTime = DateTime.now();
      _state = SyncState.idle;
      print('✅ Sync completed');
    } catch (e) {
      _state = SyncState.error;
      _lastError = e.toString();
      print('❌ Sync error: $e');
    }
  }

  /// Queue operation for offline
  Future<void> queueOperation({
    required String userId,
    required String operationType,
    required String tableName,
    required String entityId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final jsonString = jsonEncode(data);
      await _queueManager.addOperation(
        userId: userId,
        operationType: operationType,
        tableName: tableName,
        entityId: entityId,
        data: jsonString,
      );
      
      print('⏳ Operation queued: $operationType $tableName ($entityId)');
      
      // If online, try to sync immediately
      if (!isOffline) {
        startSync(userId);
      }
    } catch (e) {
      print('❌ Error queuing operation: $e');
      rethrow;
    }
  }

  /// Process offline queue
  Future<void> processOfflineQueue(String userId) async {
    try {
      print('🔄 Processing offline queue for user: $userId');

      final operations = await _queueManager.getPendingOperations(userId: userId);
      
      for (final op in operations) {
        try {
          bool success = false;
          final dataMap = _parseData(op.data);
          
          if (dataMap.isEmpty && op.operationType != 'delete') {
            print('⚠️ Empty data for operation ${op.id}, skipping');
            await _queueManager.removeOperation(op.id!);
            continue;
          }

          // Map operations to Firebase actions
          switch (op.tableName) {
            case 'daily_log_summary':
              if (op.operationType == 'update' || op.operationType == 'create') {
                await _firebaseSync.pushDailyLogSummary(DailyLogSummary.fromMap(dataMap));
                success = true;
              }
              break;
              
            case 'food_logs':
              if (op.operationType == 'update' || op.operationType == 'create') {
                await _firebaseSync.pushFoodLog(FoodLog.fromMap(dataMap));
                success = true;
              }
              break;

            case 'workout_logs':
              if (op.operationType == 'update' || op.operationType == 'create') {
                await _firebaseSync.pushWorkoutLog(WorkoutLog.fromMap(dataMap));
                success = true;
              }
              break;

            case 'exercises':
              if (op.operationType == 'update' || op.operationType == 'create') {
                await _firebaseSync.pushExercise(Exercise.fromMap(dataMap));
                success = true;
              }
              break;

            case 'body_weight_logs':
              if (op.operationType == 'update' || op.operationType == 'create') {
                await _firebaseSync.pushBodyWeightLog(BodyWeightLog.fromMap(dataMap));
                success = true;
              }
              break;

            case 'bmi_results':
              if (op.operationType == 'update' || op.operationType == 'create') {
                await _firebaseSync.pushBmiResult(BmiResultModel.fromMap(dataMap));
                success = true;
              }
              break;

            case 'hydration_logs':
              if (op.operationType == 'update' || op.operationType == 'create') {
                await _firebaseSync.pushWaterLog(WaterLogModel.fromMap(dataMap));
                success = true;
              }
              break;

            case 'user_profiles':
              if (op.operationType == 'update' || op.operationType == 'create') {
                await _firebaseSync.pushUserProfile(UserProfileModel.fromMap(dataMap));
                success = true;
              }
              break;

            // Handle deletions
            default:
              if (op.operationType == 'delete') {
                // For deletion, we usually only need the ID and table to locate the doc in Firestore
                // This could be a generic delete method in FirebaseSync if we standardized the paths
                print('ℹ️ Processing delete for ${op.tableName}');
                success = true; 
              } else {
                print('⚠️ No Firebase mapping for table: ${op.tableName}');
                success = true;
              }
          }

          if (success) {
            await _queueManager.removeOperation(op.id!);
          } else {
            await _queueManager.incrementRetryCount(op.id!);
          }
        } catch (e) {
          print('⚠️ Error processing operation ${op.id}: $e');
          await _queueManager.incrementRetryCount(op.id!);
        }
      }

      print('✅ Offline queue processed');
    } catch (e) {
      print('❌ Error processing queue: $e');
      _state = SyncState.error;
      _lastError = e.toString();
    }
  }

  Map<String, dynamic> _parseData(String data) {
    try {
      return jsonDecode(data);
    } catch (e) {
      print('❌ Error parsing operation data: $e');
      return {};
    }
  }

  /// Get sync status
  Map<String, dynamic> getStatus() {
    return {
      'state': _state.toString(),
      'is_syncing': isSyncing,
      'is_offline': isOffline,
      'last_sync': _lastSyncTime?.toIso8601String(),
      'last_error': _lastError,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Reset sync state
  void reset() {
    _state = SyncState.idle;
    _lastError = null;
    print('🔄 Sync state reset');
  }

  /// Force sync
  Future<void> forceSync(String userId) async {
    reset();
    await startSync(userId);
  }
}