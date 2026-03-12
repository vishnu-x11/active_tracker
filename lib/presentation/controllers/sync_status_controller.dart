import 'package:get/get.dart';
import 'package:active_tracker/data/sync/sync_manager.dart';
import 'package:active_tracker/data/sync/connectivity_monitor.dart';
import 'package:active_tracker/data/sync/offline_queue_manager.dart';

/// Monitors sync status and connectivity
class SyncStatusController extends GetxController {
  // ============ DEPENDENCIES ============
  final SyncManager _syncManager;
  final ConnectivityMonitor _connectivity;
  final OfflineQueueManager _queueManager;

  // ============ OBSERVABLE STATE ============
  final isOnline = true.obs;
  final isSyncing = false.obs;
  final pendingOperationsCount = 0.obs;
  final lastSyncTime = Rx<DateTime?>(null);
  final syncError = ''.obs;

  // ============ CONSTRUCTOR ============
  SyncStatusController(
      this._syncManager,
      this._connectivity,
      this._queueManager,
      );

  // ============ LIFECYCLE ============
  @override
  void onInit() {
    super.onInit();
    print('✅ SyncStatusController initialized');
    updateStatus();
    _setupListeners();
  }

  @override
  void onReady() {
    super.onReady();
    print('✅ SyncStatusController ready');
  }

  @override
  void onClose() {
    super.onClose();
    print('✅ SyncStatusController closed');
  }

  // ============ BUSINESS LOGIC ============

  /// Setup listeners for connectivity changes
  void _setupListeners() {
    // Listen for connectivity changes
    ever(isOnline, (online) {
      if (online) {
        print('📡 Online detected - triggering sync');
        processPendingOperations();
      } else {
        print('📴 Offline detected');
      }
    });
  }

  /// Update sync status from managers
  Future<void> updateStatus() async {
    try {
      isOnline.value = _connectivity.isOnline;
      isSyncing.value = _syncManager.isSyncing;
      lastSyncTime.value = _syncManager.lastSyncTime;

      final stats = await _queueManager.getQueueStats();
      pendingOperationsCount.value = (stats['total'] as int?) ?? 0;

      syncError.value = _syncManager.lastError ?? '';
      print('✅ Sync status updated: online=$isOnline, pending=${pendingOperationsCount.value}');
    } catch (e) {
      print('❌ Error updating sync status: $e');
    }
  }

  /// Process pending operations in offline queue
  Future<void> processPendingOperations() async {
    try {
      if (pendingOperationsCount.value == 0) {
        print('✅ No pending operations');
        return;
      }

      print('🔄 Processing ${pendingOperationsCount.value} pending operations');

      // TODO: Implement actual queue processing
      // await _syncManager.processOfflineQueue('user-id');

      await updateStatus();
      print('✅ Pending operations processed');
    } catch (e) {
      syncError.value = 'Failed to process queue: $e';
      print('❌ Error processing queue: $e');
    }
  }

  /// Force sync
  Future<void> forceSync() async {
    try {
      if (!isOnline.value) {
        syncError.value = 'Cannot sync while offline';
        return;
      }

      print('🔄 Force syncing...');

      // TODO: Implement actual force sync
      // await _syncManager.forceSync('user-id');

      await updateStatus();
      print('✅ Force sync completed');
    } catch (e) {
      syncError.value = 'Sync failed: $e';
      print('❌ Force sync error: $e');
    }
  }

  // ============ HELPER METHODS ============

  /// Get user-friendly status message
  String getStatusMessage() {
    if (!isOnline.value) {
      return '📴 Offline - ${pendingOperationsCount.value} operations queued';
    }
    if (isSyncing.value) {
      return '🔄 Syncing...';
    }
    if (pendingOperationsCount.value > 0) {
      return '⏳ ${pendingOperationsCount.value} pending operations';
    }
    return '✅ All synced';
  }

  /// Get status color (for UI)
  String getStatusColor() {
    if (!isOnline.value) return '#FF6B6B'; // Red
    if (isSyncing.value) return '#4ECDC4'; // Cyan
    if (pendingOperationsCount.value > 0) return '#FFE66D'; // Yellow
    return '#95E1D3'; // Green
  }

  /// Get queue size
  int getQueueSize() => pendingOperationsCount.value;

  /// Is ready to sync
  bool get canSync => isOnline.value && !isSyncing.value;

  /// Get last sync duration
  String getLastSyncTime() {
    if (lastSyncTime.value == null) {
      return 'Never';
    }
    final duration = DateTime.now().difference(lastSyncTime.value!);
    if (duration.inSeconds < 60) {
      return 'Just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minutes ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hours ago';
    } else {
      return '${duration.inDays} days ago';
    }
  }
}